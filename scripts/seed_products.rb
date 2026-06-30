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
    name:           'Classic Square',
    pack:           'Pack of 6',
    tagline:        'Crunchy. Clean. Completely Satisfying.',
    category:       'Chocolate Square',
    description:    'The OG Crave Better — crunchy Ragi and roasted Peanuts, sweetened naturally with Jaggery. No sugar crash, no guilt, just a deeply satisfying snack that loves you back.',
    price:          190,
    original_price: 210,
    image_url:      '/classic-1.webp',
    badge:          'Best Seller',
    badge_color:    '#54221b',
    rating:         4.8,
    orders_count:   1200,
    protein:        '5g',
    fiber:          '5.2g',
    calories:       '120 kcal',
    transfat:       '0g',
    carbs:          '13g',
    fat:            '3.2g',
    weight:         '28g × 6',
    ingredients:    'Roasted Peanut (36%), Multigrain Muesli Mix (29%) [Ragi Crisps, Oats, Pumpkin Seeds], Jaggery (22%), FOS (10%), Skimmed Milk Powder (2%), Vanilla Flavour, Rosemary Extract. Allergens: Contains Peanuts, Milk.',
    benefits:       [
      'Minimal sugar spike — high fiber slows it all down',
      'Sweetened with Jaggery & FOS, not refined sugar',
      'Crunchy Ragi base packed with calcium & iron',
      '5.2g dietary fiber keeps you full for longer',
      'No artificial colours, flavours, or preservatives',
    ],
  },
  {
    name:           'Dark Choco Square',
    pack:           'Pack of 6',
    tagline:        'Rich. Dark. Ridiculously Good.',
    category:       'Chocolate Square',
    description:    'All the crunch and goodness of the millets, wrapped in a rich dark chocolate coating. Indulgent taste, clean ingredients — this is what guilt-free actually feels like.',
    price:          320,
    original_price: 360,
    image_url:      '/dark-1.webp',
    badge:          'Fan Fav',
    badge_color:    '#1e5054',
    rating:         4.7,
    orders_count:   980,
    protein:        '5g',
    fiber:          '5g',
    calories:       '180 kcal',
    transfat:       '0g',
    carbs:          '22g',
    fat:            '6.5g',
    weight:         '38g × 6',
    ingredients:    'Roasted Peanut (33%), Multigrain Muesli Mix (29%) [Ragi Crisps, Oats, Pumpkin Seeds], Jaggery (22%), FOS (10%), Skimmed Milk Powder (2%), Dark Chocolate Coating, Vanilla Flavour, Rosemary Extract. Allergens: Contains Peanuts, Milk.',
    benefits:       [
      'Minimal sugar spike — high fiber does the heavy lifting',
      'Rich dark chocolate coating, sweetened with Jaggery',
      'Crunchy Ragi + Peanut base for real satisfaction',
      '5g dietary fiber — stays with you for hours',
      'No artificial preservatives or refined sugar',
    ],
  },
  {
    name:           'Milk Choco Square',
    pack:           'Pack of 6',
    tagline:        'Creamy. Smooth. Made for Cravings.',
    category:       'Chocolate Square',
    description:    "Silky milk chocolate meets crunchy Ragi and Peanuts — smooth on the outside, satisfying crunch inside. The one you'll keep reaching for, without the morning-after regret.",
    price:          270,
    original_price: 300,
    image_url:      '/milk-1.webp',
    badge:          'Loved by Kids',
    badge_color:    '#7b3f00',
    rating:         4.6,
    orders_count:   450,
    protein:        '5g',
    fiber:          '5g',
    calories:       '170 kcal',
    transfat:       '0g',
    carbs:          '20g',
    fat:            '8.5g',
    weight:         '38g × 6',
    ingredients:    'Roasted Peanuts (36%), Multigrain Muesli Mix (29%) [Ragi Crisps, Oats, Pumpkin Seeds], Jaggery (22%), FOS (10%), Skimmed Milk Powder (20%), Sugar, Edible Vegetable Fat, Salt, Milk Solids. Allergens: Contains Peanuts, Milk, Tree Nuts.',
    benefits:       [
      'Minimal sugar spike — fiber keeps blood sugar stable',
      'Smooth milk chocolate with Jaggery sweetness',
      'Crunchy Ragi & Peanut center — deeply satisfying',
      'High fiber, real ingredients, clean label',
      'No artificial additives or refined sugar overload',
    ],
  },
  {
    name:           'Combo Box',
    pack:           'Pack of 6',
    tagline:        'Try All 3. Love Every Bite.',
    category:       'Combo',
    description:    "Can't pick just one? Don't. The Combo Box brings together all three Crave Better flavours — 2 Classic Squares, 2 Dark Choco Squares, and 2 Milk Choco Squares — in one irresistible pack. All the crunch, all the chocolate, all the goodness. Best value for money, guaranteed.",
    price:          250,
    original_price: 290,
    image_url:      '/combo-1.webp',
    badge:          'Best Value',
    badge_color:    '#2D6A4F',
    rating:         4.9,
    orders_count:   0,
    protein:        '5g',
    fiber:          '5g',
    calories:       '—',
    transfat:       '0g',
    carbs:          '—',
    fat:            '—',
    weight:         '6 bars',
    ingredients:    'Contains Classic Square, Dark Choco Square, and Milk Choco Square. See individual products for full ingredient lists. Allergens: Contains Peanuts, Milk, Tree Nuts.',
    benefits:       [
      'All 3 flavours in one pack — perfect for trying',
      '2 squares of each: Classic, Dark Choco & Milk Choco',
      'Best value — save more when you mix and match',
      'Great for gifting, sharing, or stocking up',
      'Same clean ingredients across all variants',
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
