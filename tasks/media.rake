# Moves media that still lives in the old AWS bucket into the object store the
# app is configured for now (MinIO), then repoints the database rows at it.
#
# The gallery, testimonial and product tables store ABSOLUTE urls, so changing
# MINIO_* in the environment only changes where NEW uploads go — rows written
# earlier keep pointing at whatever bucket was configured the day they were
# saved. Nothing in the app rewrites them, which is why the API still hands the
# frontend adhyapak-uploads.s3.amazonaws.com links. This task closes that gap.
#
#   rake media:scan                     # read-only report, changes nothing
#   rake media:migrate                  # dry run: says exactly what it would do
#   rake media:migrate[apply]           # copy objects, verify, then update rows
#   rake media:rollback[tmp/media-....json]
#
# Objects are copied key-for-key — only the host and bucket part of each url
# changes — so the copy is idempotent and safe to re-run. Nothing is ever
# deleted from the old bucket: it stays as the backup until you drop it.
namespace :media do
  # The bucket these urls are being moved OFF. Override for a different source.
  LEGACY_HOST = ENV['LEGACY_MEDIA_HOST'].to_s.strip.empty? ?
    'adhyapak-uploads.s3.us-east-1.amazonaws.com' :
    ENV['LEGACY_MEDIA_HOST'].strip

  # Every column in the schema that holds a media url.
  MEDIA_COLUMNS = {
    gallery_items: %i[image_url thumb_url],
    testimonials:  %i[image_url photo_url video_url],
    products:      %i[image_url],
  }.freeze

  EXT_TYPES = {
    '.webp' => 'image/webp', '.jpg' => 'image/jpeg', '.jpeg' => 'image/jpeg',
    '.png'  => 'image/png',  '.gif' => 'image/gif',  '.heic' => 'image/heic',
    '.heif' => 'image/heif', '.mp4' => 'video/mp4',  '.webm' => 'video/webm',
  }.freeze

  # The Rakefile loads src/app.rb but not the bundle, so gems have to come in
  # before anything touches Sequel or Aws.
  def boot!
    require 'bundler'
    Bundler.require(:default, App.env)
    App.load!
    require 'net/http'
    require 'json'
  end

  def uploads
    App::Services::Uploads
  end

  # Rows whose url still points at the old bucket, one entry per column.
  def legacy_rows
    rows = []
    MEDIA_COLUMNS.each do |table, columns|
      next unless App.db.table_exists?(table)

      present = App.db[table].columns
      columns.each do |column|
        next unless present.include?(column)

        App.db[table].where(Sequel.like(column, "%#{LEGACY_HOST}%"))
                     .select(:id, column).order(:id).each do |r|
          rows << { table: table, id: r[:id], column: column, old_url: r[column] }
        end
      end
    end
    rows
  end

  def content_type_for(key, from_response)
    return from_response if from_response.to_s.start_with?('image/', 'video/')

    EXT_TYPES[File.extname(key).downcase] || 'application/octet-stream'
  end

  # Plain GET rather than the AWS sdk: the old objects are publicly readable
  # and the credentials in this environment belong to MinIO, not to AWS.
  def fetch(url, redirects = 5)
    raise "Too many redirects fetching #{url}" if redirects.zero?

    uri = URI.parse(url)
    res = Net::HTTP.start(uri.host, uri.port,
                          use_ssl: uri.scheme == 'https',
                          open_timeout: 20, read_timeout: 120) do |http|
      http.get(uri.request_uri)
    end

    return fetch(res['location'], redirects - 1) if res.is_a?(Net::HTTPRedirection)
    raise "GET returned #{res.code}" unless res.is_a?(Net::HTTPSuccess)

    [res.body, res['content-type']]
  end

  def head_size(client, bucket, key)
    client.head_object(bucket: bucket, key: key).content_length
  rescue Aws::S3::Errors::NotFound, Aws::S3::Errors::NoSuchKey
    nil
  end

  desc 'Report which media rows still point at the old bucket (read-only)'
  task :scan do
    boot!

    rows = legacy_rows
    puts "Legacy host : #{LEGACY_HOST}"
    puts "Target      : #{uploads.endpoint || 'AWS S3'} bucket #{uploads.bucket}"
    puts

    if rows.empty?
      puts 'Nothing to migrate — no rows reference the legacy host.'
      next
    end

    rows.group_by { |r| [r[:table], r[:column]] }.sort_by { |k, _| k.map(&:to_s) }
        .each { |(table, column), rs| puts format('%-16s %-12s %4d rows', table, column, rs.size) }

    puts
    puts "#{rows.size} row/column values across #{rows.map { |r| r[:old_url] }.uniq.size} distinct objects."
  end

  desc 'Copy legacy objects into the current bucket and repoint the rows. Pass [apply] to write; default is a dry run'
  task :migrate, [:mode] do |_t, args|
    boot!

    apply  = args[:mode].to_s.strip.downcase == 'apply'
    bucket = uploads.bucket
    raise 'No bucket configured (MINIO_BUCKET / S3_BUCKET)' if bucket.to_s.empty?

    rows = legacy_rows
    if rows.empty?
      puts 'Nothing to migrate — no rows reference the legacy host.'
      next
    end

    puts apply ? '== APPLY ==' : '== DRY RUN (pass [apply] to write) =='
    puts "From  : #{LEGACY_HOST}"
    puts "To    : #{uploads.endpoint || 'AWS S3'} / #{bucket}"
    puts "Rows  : #{rows.size}"
    puts

    # The same object can be referenced by more than one row, so copy per
    # distinct url and let every row that uses it share the result.
    objects = rows.map { |r| r[:old_url] }.uniq.map do |url|
      key = uploads.key_from_url(url)
      { old_url: url, key: key, new_url: key && uploads.public_url(key) }
    end

    unmapped = objects.select { |o| o[:key].to_s.empty? }
    unmapped.each { |o| puts "  SKIP  no key could be derived from #{o[:old_url]}" }
    objects -= unmapped

    client = Aws::S3::Client.new
    copied = {}

    objects.each_with_index do |o, i|
      label = format('[%3d/%3d] %s', i + 1, objects.size, o[:key])

      begin
        existing = head_size(client, bucket, o[:key])

        unless apply
          puts "#{label} — #{existing ? "already in #{bucket} (#{existing} bytes)" : 'would copy'}"
          copied[o[:old_url]] = o[:new_url]
          next
        end

        if existing
          puts "#{label} — already present (#{existing} bytes), skipping copy"
          copied[o[:old_url]] = o[:new_url]
          next
        end

        body, res_type = fetch(o[:old_url])
        ctype = content_type_for(o[:key], res_type)
        client.put_object(bucket: bucket, key: o[:key], body: body, content_type: ctype)

        # Verify before the row is allowed to point here, so a half-written
        # object can never become the only url we have.
        stored = head_size(client, bucket, o[:key])
        if stored != body.bytesize
          puts "#{label} — VERIFY FAILED (sent #{body.bytesize}, stored #{stored.inspect}), row left alone"
          next
        end

        puts "#{label} — copied #{body.bytesize} bytes (#{ctype})"
        copied[o[:old_url]] = o[:new_url]
      rescue => e
        puts "#{label} — ERROR #{e.class}: #{e.message}, row left alone"
      end
    end

    updatable = rows.select { |r| copied[r[:old_url]] }
    puts
    puts "#{copied.size}/#{objects.size} objects ready, #{updatable.size}/#{rows.size} rows updatable."

    if updatable.empty?
      puts 'No rows to update.'
      next
    end

    unless apply
      updatable.first(5).each do |r|
        puts "  would set #{r[:table]}##{r[:id]}.#{r[:column]}"
        puts "    #{r[:old_url]}"
        puts " -> #{copied[r[:old_url]]}"
      end
      puts "  ... and #{updatable.size - 5} more" if updatable.size > 5
      next
    end

    backup = File.join(App.root, 'tmp', "media-migration-#{Time.now.utc.strftime('%Y%m%d-%H%M%S')}.json")
    FileUtils.mkdir_p(File.dirname(backup))
    File.write(backup, JSON.pretty_generate(
      updatable.map { |r| r.merge(new_url: copied[r[:old_url]]) }
    ))
    puts "Backup of previous urls: #{backup}"

    # One transaction: either every row moves to the new host or none does,
    # so the gallery is never half on one bucket and half on the other.
    updated = 0
    App.db.transaction do
      updatable.each do |r|
        updated += App.db[r[:table]].where(id: r[:id], r[:column] => r[:old_url])
                                    .update(r[:column] => copied[r[:old_url]])
      end
    end

    puts "Updated #{updated} row/column values."
    remaining = legacy_rows.size
    puts remaining.zero? ?
      'Done — no rows reference the legacy host any more.' :
      "#{remaining} rows still reference the legacy host (see errors above)."
  end

  desc 'Restore the urls recorded in a media:migrate backup file'
  task :rollback, [:file] do |_t, args|
    boot!

    file = args[:file].to_s
    raise 'Usage: rake media:rollback[tmp/media-migration-....json]' if file.empty?
    raise "No such backup: #{file}" unless File.exist?(file)

    entries = JSON.parse(File.read(file), symbolize_names: true)
    restored = 0

    App.db.transaction do
      entries.each do |e|
        restored += App.db[e[:table].to_sym]
                       .where(id: e[:id], e[:column].to_sym => e[:new_url])
                       .update(e[:column].to_sym => e[:old_url])
      end
    end

    puts "Restored #{restored}/#{entries.size} values from #{file}."
  end
end
