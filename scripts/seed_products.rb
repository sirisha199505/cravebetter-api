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
    category:     'Chocolate Square',
    description:  'The OG Crave Better — crunchy Ragi and roasted Peanuts, sweetened naturally with Jaggery. No sugar crash, no guilt, just a deeply satisfying snack that loves you back.',
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
      'Zero sugar spike — high fiber slows it all down',
      'Sweetened with Jaggery & FOS, not refined sugar',
      'Crunchy Ragi base packed with calcium & iron',
      '6g dietary fiber keeps you full for longer',
      'No artificial colours, flavours, or preservatives',
    ],
  },
  {
    name:         'Dark Choco Square',
    category:     'Chocolate Square',
    description:  'All the crunch and goodness of the Classic, wrapped in a rich dark chocolate coating. Indulgent taste, clean ingredients — this is what guilt-free actually feels like.',
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
      'Zero sugar spike — high fiber does the heavy lifting',
      'Rich dark chocolate coating, sweetened with Jaggery',
      'Crunchy Ragi + Peanut base for real satisfaction',
      '6g dietary fiber — stays with you for hours',
      'No artificial preservatives or refined sugar',
    ],
  },
  {
    name:         'milk choco square1',
    category:     'Chocolate Square',
    description:  "Silky milk chocolate meets crunchy Ragi and Peanuts — smooth on the outside, satisfying crunch inside. The one you'll keep reaching for, without the morning-after regret.",
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
      'Zero sugar spike — fiber keeps blood sugar stable',
      'Smooth milk chocolate with Jaggery sweetness',
      'Crunchy Ragi & Peanut center — deeply satisfying',
      'High fiber, real ingredients, clean label',
      'No artificial additives or refined sugar overload',
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
