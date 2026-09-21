class App::Models::Testimonial < Sequel::Model(:testimonials)
  def validate
    super
    validates_presence [:name, :message]
    validates_integer :rating, allow_nil: true
    if video_url.to_s != '' && !video_url.to_s.match?(%r{\Ahttps?://}i)
      errors.add(:video_url, 'must start with http:// or https://')
    end
  end

  # Fallback avatar for testimonials with no photo — the homepage has always
  # shown initials, so keep producing them server-side.
  def initials
    name.to_s.split(/\s+/).reject(&:empty?).first(2).map { |w| w[0] }.join.upcase
  end

  # Same four link shapes the gallery accepts, so an admin can paste a watch,
  # share, embed or shorts URL here too.
  def youtube_id
    video_url.to_s[App::Models::GalleryLink::YOUTUBE_ID, 1]
  end

  def to_pos
    {
      id:         id,
      name:       name,
      role:       role,
      message:    message,
      rating:     (rating || 5).clamp(1, 5),
      image_url:  image_url,
      photo_url:  photo_url,
      video_url:  video_url,
      youtube_id: youtube_id,
      initials:   initials,
      featured:   featured,
      position:   position,
    }
  end
end
