require 'net/http'
require 'openssl'

class App::Services::Payments < App::Services::Base
  RAZORPAY_ORDERS_URL = 'https://api.razorpay.com/v1/orders'.freeze

  def create_order
    amount_paise = qs[:amount].to_i
    return_errors!('Invalid amount') if amount_paise <= 0

    uri = URI(RAZORPAY_ORDERS_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    req = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
    req.basic_auth(ENV['RAZORPAY_KEY_ID'], ENV['RAZORPAY_KEY_SECRET'])
    req.body = {
      amount:   amount_paise,
      currency: 'INR',
      receipt:  "rcpt_#{Time.now.to_i}",
    }.to_json

    res = http.request(req)
    unless res.code == '200'
      App.logger.error("Razorpay create_order failed: #{res.body}")
      return_errors!('Could not initiate payment. Please try again.')
    end

    data = JSON.parse(res.body)
    return_success({ id: data['id'], amount: data['amount'], currency: data['currency'] })
  rescue => e
    App.logger.error("Razorpay create_order: #{e.message}")
    return_errors!(e.message)
  end

  def verify
    p = qs
    rzp_order_id   = p[:razorpay_order_id].to_s
    rzp_payment_id = p[:razorpay_payment_id].to_s
    rzp_signature  = p[:razorpay_signature].to_s

    expected = OpenSSL::HMAC.hexdigest(
      OpenSSL::Digest.new('sha256'),
      ENV['RAZORPAY_KEY_SECRET'].to_s,
      "#{rzp_order_id}|#{rzp_payment_id}"
    )

    unless ActiveSupport::SecurityUtils.secure_compare(expected, rzp_signature)
      return_errors!('Payment verification failed. Please contact support.')
    end

    Orders[request].place
  rescue => e
    App.logger.error("Razorpay verify: #{e.message}")
    return_errors!(e.message)
  end

  def self.fields
    { save: [] }
  end
end
