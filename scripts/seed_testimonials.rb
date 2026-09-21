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

# The three testimonials that were hardcoded in Home.jsx before the admin
# panel existed. Safe to re-run: it only inserts names that aren't there yet,
# so it won't clobber anything the client has since added or edited.
TESTIMONIALS = [
  { name:    'Arjun Sharma',
    role:    'Working Professional, Mumbai',
    message: 'Genuinely surprised — I expected a "health bar" taste and got a proper chocolate. The Classic Square is on my desk every day now.',
    rating:  5 },
  { name:    'Priya Menon',
    role:    'Teacher, Bangalore',
    message: "My students always sneak my Dark Choco Squares. Guess that settles the 'does it taste good?' question. We're all hooked.",
    rating:  5 },
  { name:    'Rohan Desai',
    role:    'Business Owner, Pune',
    message: "We bulk order for the whole office now. The milk choco square is gone within a day. Everyone assumes it's a regular chocolate — until they read the label.",
    rating:  5 },
]

puts 'Seeding testimonials...'

now = Time.now
TESTIMONIALS.each_with_index do |t, i|
  if App::Models::Testimonial.where(name: t[:name]).count > 0
    puts "  Skipped (already present): #{t[:name]}"
    next
  end

  App::Models::Testimonial.create(
    name:       t[:name],
    role:       t[:role],
    message:    t[:message],
    rating:     t[:rating],
    featured:   true,
    position:   i,
    active:     true,
    created_at: now,
    updated_at: now,
  )
  puts "  Created ##{i}: #{t[:name]}"
end

puts "Done. #{App::Models::Testimonial.count} testimonial(s) in the database."
