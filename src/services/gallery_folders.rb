class App::Services::GalleryFolders < App::Services::Base
  include App::EventDateFilter

  # The public gallery lands on the folder list and shows a taste of each
  # event; the whole folder is one click away at /gallery/<slug>.
  PREVIEW_SIZE = 5

  # Eight events to a page on the website, ten in the admin grid.
  PUBLIC_PAGE_SIZE = 8
  PAGE_SIZE = 10
  MAX_PAGE_SIZE = 50

  def model; App::Models::GalleryFolder; end
  def item_model; App::Models::GalleryItem; end
  def link_model; App::Models::GalleryLink; end

  # Public: GET /api/gallery/folders?q=&year=|month=|from=&to=&page=
  # One page of events, each with its image count and first few images, so a
  # page renders in a single request no matter how many events exist.
  def list
    # An empty folder would render as an empty strip, so it is excluded in
    # SQL rather than after paging — otherwise a page of ten could arrive
    # with three rows. A folder with only videos still counts as content.
    with_photos = item_model.where(active: true).exclude(folder_id: nil).select(:folder_id)
    with_videos = link_model.where(active: true).exclude(folder_id: nil).select(:folder_id)
    ds = filtered(model.where(active: true))
         .where(Sequel.|({ id: with_photos }, { id: with_videos }))

    folders, page_meta = paginate(ds, PUBLIC_PAGE_SIZE)
    ids     = folders.map(&:id)
    counts  = image_counts(ids, active_only: true)
    videos  = video_counts(ids, active_only: true)
    preview = previews(ids, PREVIEW_SIZE)

    rows = folders.map do |f|
      f.to_pos(
        image_count: counts.fetch(f.id, 0),
        video_count: videos.fetch(f.id, 0),
        preview:     preview.fetch(f.id, []),
      )
    end

    return_success(rows, meta: page_meta.merge(
      preview_size: PREVIEW_SIZE,
      # Always the full year list, not the filtered one — the year control
      # has to keep offering the other years after one is picked.
      years:        years(active_only: true),
    ))
  end

  # Admin: every folder, live or hidden, plus a cover thumbnail and the count
  # including hidden images (the admin grid has to reach those too).
  def admin_list
    folders, page_meta = paginate(filtered(model.dataset))
    ids     = folders.map(&:id)
    counts  = image_counts(ids, active_only: false)
    videos  = video_counts(ids, active_only: false)
    covers  = previews(ids, 1, active_only: false)

    rows = folders.map do |f|
      f.to_pos(
        active:      f.active,
        image_count: counts.fetch(f.id, 0),
        video_count: videos.fetch(f.id, 0),
        cover:       covers.fetch(f.id, []).first,
      )
    end

    return_success(rows, meta: page_meta.merge(
      unfiled:       unfiled_count,
      unfiled_links: unfiled_link_count,
      years:         years(active_only: false),
    ))
  end

  def create
    data = data_for(:save)
    return_errors!({ name: "Can't be blank" }, 400) if data[:name].to_s.strip.empty?

    obj = model.new(data)
    obj.name = obj.name.to_s.strip
    obj.slug = model.unique_slug(obj.name) if obj.slug.to_s.empty?
    # Most events are added around the time they happen, so today is the
    # useful default; the admin can correct it for an older event.
    obj.event_date = Date.today if obj.event_date.nil?
    obj.position = next_position if obj.position.nil? || obj.position.zero?
    obj.created_at = Time.now
    save(obj)
  end

  def update
    data = data_for(:save)
    data[:name] = data[:name].to_s.strip if data.key?(:name)
    return_errors!({ name: "Can't be blank" }, 400) if data.key?(:name) && data[:name].empty?

    # A rename re-slugs the folder, so its public URL follows the new name.
    if data[:name].present? && data[:name] != item.name
      data[:slug] = model.unique_slug(data[:name], ignore_id: item.id)
    end

    item.set_fields(data, data.keys)
    item.updated_at = Time.now
    save(item)
  end

  # Deleting an event folder deletes that event's photos with it, in the
  # bucket as well as the table — a folder is the unit the client thinks in,
  # and leaving 200 orphans behind is not what "delete the folder" means.
  def delete
    images = item_model.where(folder_id: item.id).all
    urls   = images.flat_map { |i| [i.image_url, i.thumb_url] }
    videos = link_model.where(folder_id: item.id).count
    name   = item.name

    model.db.transaction do
      item_model.where(folder_id: item.id).delete
      item.destroy
    end

    App::Services::Uploads.delete_by_urls(urls) if urls.any?
    return_success("Folder \"#{name}\" deleted with #{images.size} #{images.size == 1 ? 'image' : 'images'} and #{videos} #{videos == 1 ? 'video' : 'videos'}")
  rescue => e
    App.logger.error(e.message)
    return_errors!(e.message, 400)
  end

  def self.fields
    { save: [:name, :slug, :description, :event_date, :position, :active] }
  end

  # Looks a folder up by its public slug (used by the items endpoint).
  def self.by_slug(slug)
    App::Models::GalleryFolder.where(slug: slug.to_s).first
  end

  private

  # Returns [rows, meta] for one page. Base#page_size caps at 1000 and has no
  # per-endpoint default, so paging is worked out here.
  def paginate(ds, default_size = PAGE_SIZE)
    size  = [(qs[:page_size] || default_size).to_i, MAX_PAGE_SIZE].min.clamp(1, MAX_PAGE_SIZE)
    total = ds.count
    pages = [(total.to_f / size).ceil, 1].max
    # A filter change can leave the visitor on a page that no longer exists.
    page  = [(qs[:page] || 1).to_i, 1].max.clamp(1, pages)

    rows = ds.order(:position, :id).limit(size).offset((page - 1) * size).all

    [rows, { total: total, page: page, page_size: size, total_pages: pages }]
  end

  # ?q= searches the folder name and description; the date parameters
  # (?year=, ?month=, ?from=/?to=) are handled by EventDateFilter.
  def filtered(ds)
    if (q = qs[:q].to_s.strip).present?
      pattern = "%#{q.gsub(/[%_]/) { |c| "\\#{c}" }}%"
      ds = ds.where(Sequel.|(
        Sequel.ilike(:name, pattern),
        Sequel.ilike(Sequel.function(:coalesce, :description, ''), pattern),
      ))
    end
    filter_by_event_date(ds)
  end

  # Newest first — an event gallery is browsed backwards from this year.
  def years(active_only:)
    event_years(active_only ? model.where(active: true) : model.dataset)
  end

  def image_counts(ids, active_only:)
    return {} if ids.empty?
    ds = item_model.where(folder_id: ids)
    ds = ds.where(active: true) if active_only
    ds.group_and_count(:folder_id).to_hash(:folder_id, :count)
  end

  def video_counts(ids, active_only:)
    return {} if ids.empty?
    ds = link_model.where(folder_id: ids)
    ds = ds.where(active: true) if active_only
    ds.group_and_count(:folder_id).to_hash(:folder_id, :count)
  end

  # Top-N images per folder in one query — a per-folder query would be N+1
  # round trips to Neon just to draw the landing page.
  def previews(ids, per_folder, active_only: true)
    return {} if ids.empty?

    ds = item_model.where(folder_id: ids)
    ds = ds.where(active: true) if active_only

    ranked = ds.select_all(:gallery_items).select_append(
      Sequel.function(:row_number)
            .over(partition: :folder_id, order: [:position, Sequel.desc(:id)])
            .as(:rn),
    )

    item_model.db.from(ranked.as(:ranked))
              .where { rn <= per_folder }
              .order(:folder_id, :rn)
              .all
              .group_by { |row| row[:folder_id] }
              .transform_values { |rows| rows.map { |row| item_model.load(row).to_pos } }
  end

  # Images uploaded before folders existed, or left behind by a deleted
  # folder — surfaced in the admin so they never become unreachable.
  def unfiled_count
    item_model.where(folder_id: nil).count
  end

  def unfiled_link_count
    link_model.where(folder_id: nil).count
  end

  def next_position
    (model.max(:position) || -1) + 1
  end
end
