class App::Models::GalleryFolder < Sequel::Model(:gallery_folders)
  one_to_many :items, class: 'App::Models::GalleryItem', key: :folder_id

  def validate
    super
    validates_presence [:name, :slug]
    validates_unique :slug
  end

  def before_validation
    self.slug = self.class.unique_slug(name, ignore_id: id) if slug.to_s.empty?
    super
  end

  # "Diwali Mela 2025" → "diwali-mela-2025". The slug is what the public URL
  # carries (/gallery/diwali-mela-2025), so it has to stay unique.
  def self.unique_slug(name, ignore_id: nil)
    base = name.to_s.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/\A-|-\z/, '')
    base = 'folder' if base.empty?

    slug = base
    n = 2
    loop do
      ds = where(slug: slug)
      ds = ds.exclude(id: ignore_id) if ignore_id
      break slug if ds.empty?
      slug = "#{base}-#{n}"
      n += 1
    end
  end

  def to_pos(extras = {})
    {
      id:          id,
      name:        name,
      slug:        slug,
      description: description,
      event_date:  event_date&.iso8601,
      year:        event_date&.year,
      position:    position,
    }.merge(extras)
  end
end
