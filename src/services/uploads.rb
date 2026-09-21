# Hands the admin browser presigned PUT URLs so image bytes go
# browser → object store directly and never through this app. That keeps a
# 500-file gallery import off the Fly machine entirely (no request size
# limits, no memory spikes, and uploads can run in parallel).
#
# The store is MinIO, which speaks the S3 API, so the aws-sdk-s3 gem drives it
# unchanged — it only needs to be pointed at the MinIO endpoint and told to
# address buckets by path (minio.example.com/bucket/key) rather than by
# virtual host (bucket.s3.amazonaws.com/key), which MinIO does not do.
#
# Configure with S3_ENDPOINT, S3_BUCKET, S3_ACCESS_KEY_ID, S3_SECRET_ACCESS_KEY
# (AWS_* names still work as a fallback). Leave S3_ENDPOINT unset and this
# talks to real AWS S3 exactly as before.
class App::Services::Uploads < App::Services::Base
  ALLOWED_TYPES = %w[
    image/jpeg image/jpg image/png image/webp image/gif image/heic image/heif
  ].freeze

  # Presign expiry — generous enough for a slow connection to finish a large
  # batch, short enough that a leaked URL is not useful for long.
  EXPIRES_IN = 15 * 60

  MAX_BATCH = 200

  def presign
    bucket = self.class.bucket
    return_errors!('S3_BUCKET is not configured on the server', 500) if bucket.to_s.empty?

    files = params&.[](:files)
    files = [params] if !files.is_a?(Array) && params.present? # allow a single-file body too
    return_errors!({ files: "Can't be blank" }, 400) if files.blank?
    return_errors!({ files: "Too many files in one request (max #{MAX_BATCH})" }, 400) if files.size > MAX_BATCH

    signer = Aws::S3::Presigner.new

    results = files.map do |f|
      ctype = f[:content_type].to_s.downcase
      ctype = 'image/jpeg' unless ALLOWED_TYPES.include?(ctype)

      key = self.class.build_key(f[:folder], f[:filename])

      {
        key:        key,
        upload_url: signer.presigned_url(
          :put_object,
          bucket:       bucket,
          key:          key,
          content_type: ctype,
          expires_in:   EXPIRES_IN,
        ),
        public_url:   self.class.public_url(key),
        content_type: ctype,
      }
    end

    return_success(results)
  rescue => e
    App.logger.error("Presign failed: #{e.message}")
    return_errors!(e.message, 500)
  end

  # ── Helpers shared with other services ────────────────────────────

  # Accepts the several names these projects have used for the same setting.
  def self.bucket
    ENV['MINIO_BUCKET'].presence ||
      ENV['S3_BUCKET'].presence ||
      ENV['AWS_S3_BUCKET'].presence ||
      ENV['AWS_BUCKET_NAME'].presence
  end

  def self.region
    ENV['MINIO_REGION'].presence || ENV['AWS_REGION'].presence || 'ap-south-1'
  end

  # The MinIO base URL, e.g. https://media-storage.snst.cloud.
  # Unset means real AWS S3.
  def self.endpoint
    (ENV['MINIO_ENDPOINT'].presence ||
      ENV['S3_ENDPOINT'].presence ||
      ENV['AWS_S3_ENDPOINT'].presence)&.strip&.sub(%r{/\z}, '')
  end

  # MinIO has no per-bucket subdomains, so buckets are addressed by path.
  # Defaults on whenever an endpoint is set; set the var to false only if
  # something in front of MinIO does virtual-host addressing.
  def self.force_path_style?
    flag = ENV['MINIO_FORCE_PATH_STYLE'].presence || ENV['S3_FORCE_PATH_STYLE'].presence
    return !endpoint.nil? if flag.nil?

    flag.strip.downcase != 'false'
  end

  # Set S3_PUBLIC_BASE to a CDN domain (e.g. https://cdn.cravebetter4u.com)
  # to serve images through the CDN instead of straight off the bucket.
  def self.public_url(key)
    base = ENV['S3_PUBLIC_BASE'].to_s.sub(%r{/\z}, '')
    return "#{base}/#{key}" unless base.empty?

    # MinIO addresses buckets by path, AWS by virtual host.
    if endpoint
      return force_path_style? ? "#{endpoint}/#{bucket}/#{key}" : "#{endpoint}/#{key}"
    end

    "https://#{bucket}.s3.#{region}.amazonaws.com/#{key}"
  end

  # The bucket URL, the MinIO URL and a CDN URL all put the object key in the
  # path, so the key is recoverable from whatever we stored.
  def self.key_from_url(url)
    return nil if url.to_s.empty?

    uri  = URI.parse(url)
    path = uri.path.to_s.sub(%r{\A/}, '')

    # A path-style MinIO URL is endpoint/bucket/key, so the leading bucket
    # segment is part of the path and has to come off before the key is
    # usable. A CDN or virtual-host URL carries the key on its own.
    if force_path_style? && bucket.to_s.present? && host_of(endpoint) == uri.host.to_s.downcase
      path = path.sub(%r{\A#{Regexp.escape(bucket.to_s)}/}, '')
    end

    path.presence
  rescue URI::InvalidURIError
    nil
  end

  def self.host_of(url)
    return nil if url.to_s.empty?

    URI.parse(url).host.to_s.downcase.presence
  rescue URI::InvalidURIError
    nil
  end

  # True only for URLs this app wrote. An admin can paste any thumbnail URL
  # into a gallery link, and a stranger's URL must never reach delete_objects.
  def self.own_url?(url)
    return false if url.to_s.empty?

    host = host_of(url)
    return false if host.nil?

    base_host = host_of(ENV['S3_PUBLIC_BASE'])
    return true if base_host && host == base_host

    return true if host_of(endpoint) == host

    bucket.to_s.present? && host.start_with?("#{bucket.to_s.downcase}.s3")
  end

  # Best-effort cleanup. Deleting the DB row is what the admin asked for, so a
  # failure to remove the object must not fail their request.
  def self.delete_by_urls(*urls)
    keys = urls.flatten.compact.map { |u| key_from_url(u) }.compact.uniq
    return if keys.empty? || bucket.to_s.empty?

    Aws::S3::Client.new.delete_objects(
      bucket: bucket,
      delete: { objects: keys.map { |k| { key: k } }, quiet: true },
    )
  rescue => e
    App.logger.warn("S3 cleanup skipped for #{keys.inspect}: #{e.message}")
  end

  # The bucket may be shared with other apps, so everything this project
  # writes lives under one prefix. Override with S3_KEY_PREFIX (set it to an
  # empty string for a bucket dedicated to Crave Better).
  def self.key_prefix
    return ENV['S3_KEY_PREFIX'].to_s.gsub(%r{\A/|/\z}, '') if ENV.key?('S3_KEY_PREFIX')

    'cravebetter'
  end

  def self.build_key(folder, filename)
    dir  = folder.to_s.gsub(/[^a-z0-9\-_]/i, '').downcase
    dir  = 'uploads' if dir.empty?
    safe = sanitize_filename(filename)

    # Deliberately NOT App.generate_id — its "%k" is a blank-padded hour, so
    # the space truncates to_i and it returns the same token for a whole UTC
    # day. Two same-named files uploaded on one day would collide and silently
    # overwrite each other, which at 2000 images is a real risk.
    token = "#{Time.now.utc.strftime('%d%H%M%S')}-#{SecureRandom.hex(4)}"

    [
      key_prefix.presence,
      dir,
      Time.now.utc.strftime('%Y/%m'),
      "#{token}-#{safe}",
    ].compact.join('/')
  end

  def self.sanitize_filename(filename)
    base = File.basename(filename.to_s)
    ext  = File.extname(base).downcase.gsub(/[^a-z0-9.]/, '')
    ext  = '.jpg' if ext.empty?

    stem = File.basename(base, File.extname(base))
                .downcase
                .gsub(/[^a-z0-9]+/, '-')
                .gsub(/\A-|-\z/, '')[0, 60]
    stem = 'image' if stem.to_s.empty?

    "#{stem}#{ext}"
  end

  def self.fields
    { save: [:files, :filename, :content_type, :folder] }
  end
end
