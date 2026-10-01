class App::Models::Banner < Sequel::Model(:banners)
  def validate
    super
    validates_presence [:image_url]
    if link_url.to_s != '' && !link_url.to_s.match?(%r{\A(https?://|/)}i)
      errors.add(:link_url, 'must start with / (a page on this site) or http(s)://')
    end
  end

  def to_pos
    {
      id:        id,
      title:     title,
      image_url: image_url,
      link_url:  link_url,
      position:  position,
    }
  end
end
