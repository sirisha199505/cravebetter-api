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

puts "Seeding Crave Better admin user..."

email    = 'admin@cravebetterfoods.com'
existing = App::Models::User.find(email: email)

if existing
  puts "Admin already exists (id: #{existing.id})"
else
  admin = App::Models::User.new(
    full_name: 'Crave Better Admin',
    email:     email,
    role:      1,
    active:    true,
  )
  admin.password = 'crave@admin123'
  if admin.save
    puts "Admin created!"
    puts "  Email:    #{email}"
    puts "  Password: crave@admin123"
  else
    puts "Error: #{admin.errors}"
  end
end
