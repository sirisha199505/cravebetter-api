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

# FAQs provided by the client (Crave_Better_Website_FAQs.pdf).
# This list REPLACES any existing FAQs.
FAQS = [
  { question: 'What is Crave Better?',
    answer:   'Crave Better Foods creates wholesome snack squares made with simple, recognizable ingredients like ragi, oats, peanuts, jaggery, and prebiotic fiber. Our goal is to make everyday snacking more satisfying and mindful.' },
  { question: 'What ingredients are used?',
    answer:   'Our snack squares are made with whole rolled oats, ragi (finger millet), roasted peanuts, jaggery, and prebiotic fiber (FOS).' },
  { question: 'Does Crave Better contain refined sugar?',
    answer:   'No. We use jaggery instead of refined sugar.' },
  { question: 'Which flavours are available?',
    answer:   'Classic Square, Milk Choco Square, and Dark Choco Square.' },
  { question: 'Why are oats included?',
    answer:   'Whole rolled oats naturally provide dietary fiber, including beta-glucan, which can help support fullness and steadier post-meal energy as part of a balanced diet.' },
  { question: 'Why is ragi used?',
    answer:   'Ragi is a wholesome millet that naturally provides fiber and important nutrients, making it a great ingredient for everyday snacking.' },
  { question: 'Is Crave Better suitable for everyday snacking?',
    answer:   'Yes. Crave Better is designed to be a wholesome snack you can enjoy as part of a balanced lifestyle.' },
  { question: 'Does it contain artificial preservatives?',
    answer:   'No. Our products do not contain artificial preservatives.' },
  { question: 'What makes Crave Better different?',
    answer:   'We focus on simple, recognizable ingredients instead of heavily refined ingredients, helping you make better snack choices.' },
  { question: 'Is it suitable for office or college snacks?',
    answer:   "Yes. It's convenient to carry and ideal for work, college, travel, or an afternoon snack." },
  { question: 'Can I enjoy it before or after a workout?',
    answer:   'Yes. Many people enjoy Crave Better before or after physical activity as part of a balanced diet.' },
  { question: 'Is it suitable for children?',
    answer:   'Yes. It is made with familiar ingredients, but parents should always check ingredient and allergen information.' },
  { question: 'Does it contain peanuts?',
    answer:   'Yes. Our products contain peanuts.' },
  { question: 'Is it vegetarian?',
    answer:   'Yes. Crave Better Foods products are vegetarian.' },
  { question: 'How should I store the product?',
    answer:   'Store in a cool, dry place away from direct sunlight.' },
  { question: 'Where can I buy Crave Better?',
    answer:   'You can purchase directly from the official Crave Better website and authorised sales channels.' },
  { question: 'What is FOS (Prebiotic Fiber)?',
    answer:   'FOS (Fructo-oligosaccharides) is a prebiotic fiber that helps nourish beneficial gut bacteria as part of a balanced diet.' },
  { question: "What does 'No Refined Sugar' mean?",
    answer:   'It means we do not use refined white sugar. We use jaggery as our sweetener.' },
  { question: 'Who is Crave Better for?',
    answer:   'Crave Better is for anyone looking for a convenient snack made with wholesome ingredients—students, professionals, parents, travellers, and fitness enthusiasts alike.' },
  { question: 'Why choose Crave Better?',
    answer:   'Because better ingredients lead to better snacking. Every bite is crafted with wholesome ingredients and great taste.' },
]

puts "Seeding FAQs (replacing existing)..."

removed = App::Models::Faq.dataset.delete
puts "  Removed #{removed} existing FAQ(s)."

now = Time.now
FAQS.each_with_index do |faq, i|
  App::Models::Faq.create(
    question:   faq[:question],
    answer:     faq[:answer],
    position:   i,
    active:     true,
    created_at: now,
    updated_at: now,
  )
  puts "  Created ##{i}: #{faq[:question]}"
end

puts "Done. #{App::Models::Faq.count} FAQ(s) seeded."
