require 'net/http'
require 'openssl'

# PIN code -> city/state lookup backed by the public api.postalpincode.in service.
#
# That API is free and intermittently slow (single connection attempts have been
# seen to time out), so lookups are retried and every successful answer is cached
# in-process — a PIN's district and state never change, so a cached entry stays
# correct for the life of the server.
module App::PincodeLookup
  ENDPOINT     = 'https://api.postalpincode.in/pincode/'.freeze
  OPEN_TIMEOUT = 4
  READ_TIMEOUT = 6
  ATTEMPTS     = 3
  RETRY_DELAY  = 0.4

  # Distinguishes "this PIN does not exist" from "we could not ask" so the
  # checkout form can tell the customer which one happened.
  NOT_FOUND   = :not_found
  UNAVAILABLE = :unavailable

  @cache = {}
  @mutex = Mutex.new

  class<<self
    # Returns { city:, state: }, NOT_FOUND, or UNAVAILABLE.
    def lookup(pin)
      pin = pin.to_s.gsub(/\D/, '')
      return NOT_FOUND unless pin.length == 6

      cached = @mutex.synchronize { @cache[pin] }
      return cached if cached

      result = fetch(pin)
      @mutex.synchronize { @cache[pin] = result } if result.is_a?(Hash) || result == NOT_FOUND
      result
    end

    private

    def fetch(pin)
      last_error = nil

      ATTEMPTS.times do |attempt|
        begin
          return parse(get(pin))
        rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, OpenSSL::SSL::SSLError,
               Errno::ECONNRESET, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, JSON::ParserError => e
          last_error = e
          sleep(RETRY_DELAY * (attempt + 1)) unless attempt == ATTEMPTS - 1
        end
      end

      App.logger.error("Pincode lookup failed for #{pin} after #{ATTEMPTS} attempts: #{last_error.class}: #{last_error.message}")
      UNAVAILABLE
    end

    def get(pin)
      uri  = URI("#{ENDPOINT}#{pin}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl       = true
      http.verify_mode   = OpenSSL::SSL::VERIFY_PEER
      http.open_timeout  = OPEN_TIMEOUT
      http.read_timeout  = READ_TIMEOUT
      http.start { |h| h.get(uri.request_uri) }
    end

    def parse(response)
      return UNAVAILABLE unless response.is_a?(Net::HTTPSuccess)

      entry = JSON.parse(response.body)[0] || {}
      po    = Array(entry['PostOffice']).first
      return NOT_FOUND unless entry['Status'] == 'Success' && po

      { city: po['District'] || po['Name'], state: po['State'] }
    end
  end
end
