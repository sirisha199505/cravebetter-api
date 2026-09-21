class App::Models::GalleryItem < Sequel::Model(:gallery_items)
  many_to_one :folder, class: 'App::Models::GalleryFolder', key: :folder_id

  def validate
    super
    validates_presence [:image_url]
  end

  # Grids and lightboxes want the small file first and the big one only on
  # demand, so always hand back both (falling back to the full image when a
  # thumbnail could not be generated).
  def to_pos
    {
      id:        id,
      title:     title,
      folder_id: folder_id,
      image_url: image_url,
      thumb_url: thumb_url.to_s.empty? ? image_url : thumb_url,
      position:  position,
    }
  end
end
