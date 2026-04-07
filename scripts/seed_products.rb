env_file = File.expand_path('../.env', __dir__)
if File.exist?(env_file)
  File.foreach(env_file) do |line|
    line.strip!
    next if line.empty? || line.start_with?('#')
    key, val = line.split('=', 2)
    val = val.to_s.strip.gsub(/\A["']|["']\z/, '')
    ENV[key.strip] ||= val
  end
end

require 'bundler'
Bundler.require(:default, :development)
require_relative '../src/app'

App.load!

puts "Seeding Crave Better products..."

PRODUCTS = [
  {
    name:         'Chocolate Peanut Butter',
    category:     'Protein Bar',
    description:  'Rich dark chocolate meets creamy peanut butter in every indulgent bite. Packed with 20g of premium whey protein, the ultimate post-workout treat.',
    price:        150,
    image_url:    '/bar1.png',
    badge:        'Best Seller',
    badge_color:  '#54221b',
    rating:       4.8,
    orders_count: 1200,
  },
  {
    name:         'Salted Caramel',
    category:     'Protein Bar',
    description:  'Indulge in the perfect balance of sweet caramel and a hint of sea salt. With 18g of protein per bar, guilt-free indulgence at its finest.',
    price:        150,
    image_url:    '/bar2.png',
    badge:        'New',
    badge_color:  '#1e5054',
    rating:       4.6,
    orders_count: 450,
  },
  {
    name:         'Dark Chocolate',
    category:     'Protein Bar',
    description:  'Pure, intense dark chocolate packed with antioxidants and 20g of muscle-building protein. No fillers, just results.',
    price:        150,
    image_url:    '/bar3.png',
    badge:        nil,
    badge_color:  nil,
    rating:       4.7,
    orders_count: 890,
  },
  {
    name:         'Vanilla Almond',
    category:     'Protein Bar',
    description:  'Classic, smooth vanilla with satisfying crunchy almonds. 19g of protein with heart-healthy fats from real roasted almonds.',
    price:        160,
    image_url:    '/bar4.png',
    badge:        nil,
    badge_color:  nil,
    rating:       4.5,
    orders_count: 620,
  },
  {
    name:         'Mixed Berry',
    category:     'Protein Bar',
    description:  'A vibrant burst of strawberries, blueberries, and raspberries combined with 18g of clean protein. Light, fruity, refreshing.',
    price:        160,
    image_url:    '/bar5.png',
    badge:        'Fan Fav',
    badge_color:  '#7b2d8b',
    rating:       4.9,
    orders_count: 980,
  },
]

PRODUCTS.each do |p|
  existing = App::Models::Product.find(name: p[:name])
  if existing
    existing.update(p.merge(active: true))
    puts "  Updated: #{p[:name]}"
  else
    App::Models::Product.create(p.merge(active: true))
    puts "  Created: #{p[:name]}"
  end
end

puts "Done. #{App::Models::Product.count} products total."
