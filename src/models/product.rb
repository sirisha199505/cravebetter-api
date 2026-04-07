class App::Models::Product < Sequel::Model
  def validate
    super
    validates_presence [:name, :category, :price]
  end

  def to_pos
    {
      id:          id,
      name:        name,
      category:    category,
      desc:        description,
      price:       price,
      image:       image_url,
      badge:       badge,
      badgeColor:  badge_color,
      rating:      rating,
      orders:      orders_count,
    }
  end
end
