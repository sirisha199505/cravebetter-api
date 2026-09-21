class App::Services::GalleryLinks < App::Services::Base
  include App::EventDateFilter

  # Ten to a page, matching the albums.
  PAGE_SIZE = 10
  MAX_PAGE_SIZE = 50

  def model; App::Models::GalleryLink; end

  # Public: GET /api/gallery/links?folder=<slug>&q=&page= — the videos that
  # belong to one event folder, shown alongside that event's photos.
  def list
    ds = model.where(active: true)

    folder = nil
    if qs[:folder].present?
      folder = App::Services::GalleryFolders.by_slug(qs[:folder])
      return_errors!('Folder not found', 404) if folder.nil? || folder.active == false
      ds = ds.where(folder_id: folder.id)
    end

    rows, page_meta = paginate(filtered(ds))
    return_success(rows.map(&:to_pos), meta: page_meta.merge(
      folder: folder&.to_pos,
      # The full year list, not the filtered one — the year control has to
      # keep offering the other years after one is picked.
      years:  years(active_only: true),
    ))
  end

  # Admin: ?folder_id=<id> for one folder's videos, ?unfiled=true for the
  # ones that belong to no folder yet.
  def admin_list
    ds = model.dataset

    if qs[:folder_id].present?
      folder = App::Models::GalleryFolder[qs[:folder_id].to_i]
      return_errors!('Folder not found', 404) if folder.nil?
      ds = ds.where(folder_id: folder.id)
    elsif qs[:unfiled].to_s == 'true'
      ds = ds.where(folder_id: nil)
    end

    rows, page_meta = paginate(filtered(ds))
    items = rows.map { |l| l.to_pos.merge(active: l.active) }
    return_success(items, meta: page_meta.merge(years: years(active_only: false)))
  end

  def create
    data = data_for(:save)
    data[:folder_id] = data[:folder_id].presence&.to_i if data.key?(:folder_id)

    obj = model.new(data)
    obj.title = obj.title.to_s.strip
    obj.url   = obj.url.to_s.strip
    obj.position = next_position if obj.position.nil? || obj.position.zero?
    # Most links are added around the time they are about, so today is the
    # useful default; the admin can correct it for an older video.
    obj.event_date = Date.today if obj.event_date.nil?
    obj.created_at = Time.now
    save(obj)
  end

  def update
    data = data_for(:save)
    data[:title] = data[:title].to_s.strip if data.key?(:title)
    data[:url]   = data[:url].to_s.strip   if data.key?(:url)
    data[:folder_id] = data[:folder_id].presence&.to_i if data.key?(:folder_id)
    item.set_fields(data, data.keys)
    item.updated_at = Time.now
    save(item)
  end

  # Hard delete, and take an uploaded thumbnail out of the bucket with it.
  # A link carries no irreplaceable content — the URL is the content.
  def delete
    thumb = item.thumb_url
    item.destroy
    App::Services::Uploads.delete_by_urls([thumb]) if App::Services::Uploads.own_url?(thumb)
    return_success('Link deleted')
  rescue => e
    App.logger.error(e.message)
    return_errors!(e.message, 400)
  end

  def self.fields
    { save: [:title, :url, :description, :folder_id, :event_date, :position, :active] }
  end

  private

  # Returns [rows, meta] for one page — same contract as the folder list, so
  # the page can drive both pagers the same way.
  def paginate(ds)
    size  = [(qs[:page_size] || PAGE_SIZE).to_i, MAX_PAGE_SIZE].min.clamp(1, MAX_PAGE_SIZE)
    total = ds.count
    pages = [(total.to_f / size).ceil, 1].max
    page  = [(qs[:page] || 1).to_i, 1].max.clamp(1, pages)

    rows = ds.order(:position, :id).limit(size).offset((page - 1) * size).all

    [rows, { total: total, page: page, page_size: size, total_pages: pages }]
  end

  # ?q= searches the title, description and the URL itself (so pasting part
  # of a link finds it); the date parameters are handled by EventDateFilter,
  # exactly as for the photo albums.
  def filtered(ds)
    if (q = qs[:q].to_s.strip).present?
      pattern = "%#{q.gsub(/[%_]/) { |c| "\\#{c}" }}%"
      ds = ds.where(Sequel.|(
        Sequel.ilike(:title, pattern),
        Sequel.ilike(Sequel.function(:coalesce, :description, ''), pattern),
        Sequel.ilike(:url, pattern),
      ))
    end
    filter_by_event_date(ds)
  end

  # Newest first, matching the folder year list.
  def years(active_only:)
    event_years(active_only ? model.where(active: true) : model.dataset)
  end

  def next_position
    (model.max(:position) || -1) + 1
  end
end
