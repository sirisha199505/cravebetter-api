class App::Models::Product < Sequel::Model
  def validate
    super
    validates_presence [:name, :category, :price]
  end

  def to_pos
    {
      id:            id,
      name:          name,
      pack:          pack,
      tagline:       tagline,
      category:      category,
      description:   description,
      price:         price,
      originalPrice: original_price,
      image:         image_url,
      badge:         badge,
      badgeColor:    badge_color,
      rating:        rating,
      orders:        orders_count,
      protein:       protein,
      fiber:         fiber,
      calories:      calories,
      transfat:      transfat,
      carbs:         carbs,
      fat:           fat,
      weight:        weight,
      ingredients:   ingredients,
      benefits:      (benefits.is_a?(Array) ? benefits : []),
    }
  end
end
