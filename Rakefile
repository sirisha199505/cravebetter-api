env_file = File.expand_path('.env', __dir__)
if File.exist?(env_file)
  File.foreach(env_file) do |line|
    line.strip!
    next if line.empty? || line.start_with?('#')
    key, val = line.split('=', 2)
    val = val.to_s.strip.gsub(/\A["']|["']\z/, '')
    ENV[key.strip] ||= val
  end
end
require './src/app'
namespace :db do
  desc "Run migrations"
  task :migrate, [:version] do |t, args|
    puts args, App.db_url
    require "sequel/core"
    Sequel.extension :migration
    version = args[:version].to_i if args[:version]
    puts version
    Sequel.connect(App.db_url) do |db|
      db.extension :pg_enum
      Sequel::Migrator.run(db, "src/migrations", target: version)
    end
  end
end


namespace :email do
  desc "Diagnose SMTP config and connectivity from inside this machine"
  task :diagnose, [:to] do |t, args|
    require 'net/smtp'
    require 'socket'

    host = ENV['EMAIL_SMTP_SERVER']
    user = ENV['EMAIL_USER']
    pass = ENV['EMAIL_PASSWORD']

    puts "RACK_ENV              : #{ENV['RACK_ENV'].inspect}"
    puts "EMAIL_SMTP_SERVER     : #{host.inspect}"
    puts "EMAIL_DOMAIN          : #{ENV['EMAIL_DOMAIN'].inspect}"
    puts "EMAIL_USER            : #{user.inspect}"
    puts "EMAIL_PASSWORD        : #{pass.to_s.empty? ? 'MISSING' : "set (#{pass.length} chars)"}"

    if host.to_s.empty? || user.to_s.empty? || pass.to_s.empty?
      puts "\n=> FAIL: mail credentials are not present in this environment."
      puts "   Set them with: fly secrets set EMAIL_SMTP_SERVER=... EMAIL_DOMAIN=... EMAIL_USER=... EMAIL_PASSWORD=..."
      next
    end

    [465, 587, 25].each do |port|
      print "\nTCP #{host}:#{port} ... "
      begin
        Socket.tcp(host, port, connect_timeout: 15) { |s| s.close }
        puts "reachable"
      rescue => e
        puts "BLOCKED/UNREACHABLE (#{e.class}: #{e.message})"
        next
      end

      print "  SMTP AUTH on #{port} ... "
      begin
        smtp = Net::SMTP.new(host, port)
        if port == 465
          smtp.enable_tls
        else
          smtp.enable_starttls_auto
        end
        smtp.open_timeout = 15
        smtp.read_timeout = 30
        smtp.start(ENV['EMAIL_DOMAIN'] || 'localhost', user, pass, :login) do |s|
          puts "OK"
          if args[:to].to_s.strip.length > 0
            s.send_message(
              "From: #{user}\r\nTo: #{args[:to]}\r\nSubject: Crave Better SMTP diagnose (port #{port})\r\n\r\nSent from the production machine at #{Time.now}.\r\n",
              user, args[:to]
            )
            puts "  Test message sent to #{args[:to]} via port #{port}"
          end
        end
      rescue => e
        puts "FAILED (#{e.class}: #{e.message})"
      end
    end
  end
end


require 'optparse'


namespace :create do
  desc "Creates Model"
  task :models do #|t, args|
    models = []
    OptionParser.new do |opts|
      puts opts
      opts.banner = "Usage: rake create:models [options]"
      opts.on("-n", "--names ARG", String) { |str| models += str.split(',') }

    end.parse!
    puts models
    exit
  end
end


# DATABASE_URL="postgres://doqhgpwk:faHZB60XTVMZTczxkznkvXC0rcHxyap6@rogue.db.elephantsql.com:5432/doqhgpwk" rake db:migrate\[0\]


# DATABASE_URL="postgres://exbkkjhk:teWF4qtJwyLZMXLm0CDM1eiYfNC-xr_T@satao.db.elephantsql.com:5432/exbkkjhk" rake db:migrate\[7\]
# DATABASE_URL="postgres://lnhtywgf:qfdIK2eJVhJlES3jAsyU4wZAxx1ESzfi@balarama.db.elephantsql.com:5432/lnhtywgf" rake db:migrate