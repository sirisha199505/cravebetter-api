class App::Services::GalleryItems < App::Services::Base
  # The client has ~2000 images, so nothing here ever returns the whole table.
  # Both the public page and the admin grid page through it.
  DEFAULT_PAGE_SIZE = 24
  ADMIN_PAGE_SIZE   = 48

  def model; App::Models::GalleryItem; end

  # Public: GET /api/gallery?folder=<slug>&q=&page=1&page_size=24
  # A folder slug is required in practice — the public gallery reaches images
  # through a folder — but an unfiled listing still works without one.
  def list
    ds = searched(model.where(active: true))

    folder = nil
    if qs[:folder].present?
      folder = App::Services::GalleryFolders.by_slug(qs[:folder])
      return_errors!('Folder not found', 404) if folder.nil? || folder.active == false
      ds = ds.where(folder_id: folder.id)
    end

    paged(ds, DEFAULT_PAGE_SIZE, folder: folder&.to_pos) { |i| i.to_pos }
  end

  # Admin: same paging, plus the active flag so inactive rows are visible.
  # ?folder_id=<id> scopes to one folder, ?unfiled=true to the leftovers.
  def admin_list
    ds = searched(model.dataset)

    folder = nil
    if qs[:folder_id].present?
      folder = App::Models::GalleryFolder[qs[:folder_id].to_i]
      return_errors!('Folder not found', 404) if folder.nil?
      ds = ds.where(folder_id: folder.id)
    elsif qs[:unfiled].to_s == 'true'
      ds = ds.where(folder_id: nil)
    end

    paged(ds, ADMIN_PAGE_SIZE, folder: folder&.to_pos) { |i| i.to_pos.merge(active: i.active) }
  end

  def create
    obj = model.new(data_for(:save))
    obj.position = next_position if obj.position.nil? || obj.position.zero?
    obj.created_at = Time.now
    save(obj)
  end

  # Bulk import: one request creates every row for a folder of uploads, so a
  # 500-image drop is a single round trip instead of 500. `folder_id` on the
  # payload applies to the whole batch — that is how an event upload arrives.
  def bulk_create
    rows = params&.[](:items)
    return_errors!({ items: "Can't be blank" }, 400) if rows.blank?
    return_errors!({ items: 'Too many items in one request (max 500)' }, 400) if rows.size > 500

    batch_folder_id = params&.[](:folder_id).presence&.to_i
    if batch_folder_id && App::Models::GalleryFolder[batch_folder_id].nil?
      return_errors!({ folder_id: 'Folder not found' }, 404)
    end

    now  = Time.now
    base = next_position
    created = []

    model.db.transaction do
      rows.each_with_index do |row, i|
        next if row[:image_url].to_s.strip.empty?

        obj = model.new(
          title:     row[:title].to_s.strip,
          folder_id: row[:folder_id].presence&.to_i || batch_folder_id,
          image_url: row[:image_url].to_s.strip,
          thumb_url: row[:thumb_url].to_s.strip,
          position:  row[:position].presence&.to_i || (base + i),
          active:    true,
        )
        obj.created_at = now
        return_errors!(obj.errors, 400) unless obj.save
        created << obj.to_pos
      end
    end

    return_success(created, meta: { created: created.size })
  end

  def update
    data = data_for(:save)
    data[:folder_id] = data[:folder_id].presence&.to_i if data.key?(:folder_id)
    item.set_fields(data, data.keys)
    save(item)
  end

  # Hard delete — an unwanted photo should leave both the list and the bucket,
  # otherwise 2000 images turn into 2000 rows plus storage nobody wants.
  def delete
    urls = [item.image_url, item.thumb_url]
    item.destroy
    App::Services::Uploads.delete_by_urls(urls)
    return_success('Image deleted')
  rescue => e
    App.logger.error(e.message)
    return_errors!(e.message, 400)
  end

  def self.fields
    { save: [:title, :folder_id, :image_url, :thumb_url, :position, :active] }
  end

  private

  # ?q= searches image captions within whatever folder scope is in play.
  def searched(ds)
    q = qs[:q].to_s.strip
    return ds if q.empty?

    pattern = "%#{q.gsub(/[%_]/) { |c| "\\#{c}" }}%"
    ds.where(Sequel.ilike(Sequel.function(:coalesce, :title, ''), pattern))
  end

  def paged(ds, default_size = DEFAULT_PAGE_SIZE, folder: nil)
    size  = page_size(default_size)
    page  = [(qs[:page] || 1).to_i, 1].max
    total = ds.count

    items = ds.order(:position, Sequel.desc(:id))
              .limit(size)
              .offset((page - 1) * size)
              .all
              .map { |i| yield(i) }

    return_success(items, meta: {
      total:       total,
      page:        page,
      page_size:   size,
      total_pages: (total.to_f / size).ceil,
      folder:      folder,
    })
  end

  def next_position
    (model.max(:position) || -1) + 1
  end

  # Base#page_size defaults to 20 and has no per-endpoint override.
  def page_size(default_size)
    [(qs[:page_size] || default_size).to_i, 100].min.clamp(1, 100)
  end
end
