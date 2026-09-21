class App::Models::GalleryLink < Sequel::Model(:gallery_links)
  many_to_one :folder, class: 'App::Models::GalleryFolder', key: :folder_id

  # youtu.be/ID, /watch?v=ID, /embed/ID, /shorts/ID — the four shapes people
  # actually paste.
  YOUTUBE_ID = %r{
    (?:youtube\.com/(?:watch\?(?:.*&)?v=|embed/|shorts/|live/)|youtu\.be/)
    ([A-Za-z0-9_-]{11})
  }x

  def validate
    super
    validates_presence [:title, :url]
    errors.add(:url, 'must start with http:// or https://') unless url.to_s.match?(%r{\Ahttps?://}i)
  end

  def youtube_id
    url.to_s[YOUTUBE_ID, 1]
  end

  def youtube?
    !youtube_id.nil?
  end

  def to_pos
    {
      id:          id,
      title:       title,
      url:         url,
      description: description,
      folder_id:   folder_id,
      event_date:  event_date&.iso8601,
      year:        event_date&.year,
      kind:        youtube? ? 'youtube' : 'link',
      youtube_id:  youtube_id,
      position:    position,
    }
  end
end
