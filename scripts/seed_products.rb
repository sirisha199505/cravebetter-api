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

puts "Deactivating old products..."
App::Models::Product.where(active: true).update(active: false)

puts "Seeding Crave Better products..."

PRODUCTS = [
  {
    name:         'Classic Square',
    category:     'Protein Bar',
    description:  'The original Crave Better bar — made with Ragi, Peanuts & Oats and sweetened naturally with Jaggery. A wholesome, crunchy snack loaded with fiber and sustained energy.',
    price:        35,
    image_url:    '/classic%20square.png',
    badge:        'Best Seller',
    badge_color:  '#54221b',
    rating:       4.8,
    orders_count: 1200,
    protein:      '5g',
    calories:     '120 kcal',
    carbs:        '13g',
    fat:          '3.2g',
    weight:       '28g',
    ingredients:  'Roasted Peanut (36%), Multigrain Muesli Mix (29%) [Ragi Crisps, Oats, Pumpkin Seeds], Jaggery (22%), FOS (10%), Skimmed Milk Powder (2%), Vanilla Flavour, Rosemary Extract. Allergens: Contains Peanuts, Milk.',
    benefits:     [
      '100% Natural ingredients',
      'Sweetened with Jaggery — no refined sugar',
      'No artificial preservatives',
      'High in dietary fiber (6g per bar)',
      'Made with Ragi, Peanuts & Oats',
    ],
  },
  {
    name:         'Dark Choco Square',
    category:     'Protein Bar',
    description:  'All the goodness of the Classic Square wrapped in a rich dark chocolate coating. Made with Ragi, Peanuts & Oats — indulgent yet clean, sweetened only with Jaggery.',
    price:        60,
    image_url:    '/dark%20chocolate%201.png',
    badge:        'Fan Fav',
    badge_color:  '#1e5054',
    rating:       4.7,
    orders_count: 980,
    protein:      '5g',
    calories:     '180 kcal',
    carbs:        '22g',
    fat:          '6.5g',
    weight:       '38g',
    ingredients:  'Roasted Peanut (33%), Multigrain Muesli Mix (29%) [Ragi Crisps, Oats, Pumpkin Seeds], Jaggery (22%), FOS (10%), Skimmed Milk Powder (2%), Dark Chocolate Coating, Vanilla Flavour, Rosemary Extract. Allergens: Contains Peanuts, Milk.',
    benefits:     [
      '100% Natural ingredients',
      'Sweetened with Jaggery — no refined sugar',
      'No artificial preservatives',
      'Rich dark chocolate coating',
      'Made with Ragi, Peanuts & Oats',
    ],
  },
  {
    name:         'Milk Choco Square',
    category:     'Protein Bar',
    description:  "Creamy milk chocolate meets the wholesome crunch of Ragi, Peanuts & Oats. Sweetened with Jaggery for a smooth, guilt-lighter treat you'll keep coming back to.",
    price:        50,
    image_url:    '/milk%20choco%20square.png',
    badge:        'New',
    badge_color:  '#7b3f00',
    rating:       4.6,
    orders_count: 450,
    protein:      '5g',
    calories:     '170 kcal',
    carbs:        '20g',
    fat:          '8.5g',
    weight:       '38g',
    ingredients:  'Roasted Peanuts (36%), Multigrain Muesli Mix (29%) [Ragi Crisps, Oats, Pumpkin Seeds], Jaggery (22%), FOS (10%), Skimmed Milk Powder (20%), Sugar, Edible Vegetable Fat, Salt, Milk Solids. Allergens: Contains Peanuts, Milk, Tree Nuts.',
    benefits:     [
      '100% Natural ingredients',
      'Sweetened with Jaggery — no refined sugar',
      'No artificial preservatives',
      'Smooth milk chocolate coating',
      'Made with Ragi, Peanuts & Oats',
    ],
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

puts "Done. #{App::Models::Product.where(active: true).count} active products."
