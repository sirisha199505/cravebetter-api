require 'net/http'
require 'openssl'

class App::Services::Payments < App::Services::Base
  RAZORPAY_ORDERS_URL = 'https://api.razorpay.com/v1/orders'.freeze

  def create_order
    p = qs
    amount_paise = p[:amount].to_i
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

    rzp = JSON.parse(res.body)
    rzp_order_id = rzp['id']

    order = App::Models::Order.new(
      order_number:      format('%06d', Time.now.to_i % 1_000_000),
      customer_name:     p[:customer_name],
      customer_phone:    p[:customer_phone],
      customer_email:    p[:customer_email],
      address_flat:      p[:address_flat],
      address_area:      p[:address_area],
      address_city:      p[:address_city],
      address_state:     p[:address_state],
      address_pin:       p[:address_pin],
      payment_method:    'online',
      items:             p[:items] || [],
      item_total:        p[:item_total].to_i,
      delivery_fee:      p[:delivery_fee].to_i,
      platform_fee:      0,
      grand_total:       p[:grand_total].to_i,
      status:            'pending',
      razorpay_order_id: rzp_order_id,
    )

    unless order.save
      App.logger.error("Failed to save pending order: #{order.errors}")
      return_errors!('Could not save order. Please try again.')
    end

    return_success({ id: rzp_order_id, amount: rzp['amount'], currency: rzp['currency'], order_id: order.id, key_id: ENV['RAZORPAY_KEY_ID'] })
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

    unless Rack::Utils.secure_compare(expected, rzp_signature)
      return_errors!('Payment verification failed. Please contact support.')
    end

    order = App::Models::Order.where(razorpay_order_id: rzp_order_id).first
    return_errors!('Order not found.', 404) unless order

    # Idempotent: only send notifications if webhook hasn't already processed this
    unless order.razorpay_payment_id
      order.update(razorpay_payment_id: rzp_payment_id)
      notify_order(order.reload)
    end

    return_success(order.to_pos)
  rescue => e
    App.logger.error("Razorpay verify: #{e.message}")
    return_errors!(e.message)
  end

  def webhook
    raw_body  = request.env['RAW_BODY'].to_s
    signature = request.env['HTTP_X_RAZORPAY_SIGNATURE'].to_s

    expected = OpenSSL::HMAC.hexdigest(
      OpenSSL::Digest.new('sha256'),
      ENV['RAZORPAY_WEBHOOK_SECRET'].to_s,
      raw_body
    )

    unless Rack::Utils.secure_compare(expected, signature)
      App.logger.warn('Razorpay webhook: invalid signature')
      return_errors!('Invalid signature', 400)
    end

    payload = JSON.parse(raw_body)
    event   = payload['event'].to_s
    App.logger.info("Razorpay webhook event: #{event}")

    case event
    when 'payment.captured', 'order.paid'
      payment_entity = payload.dig('payload', 'payment', 'entity') || {}
      rzp_order_id   = payment_entity['order_id'].to_s
      rzp_payment_id = payment_entity['id'].to_s

      order = App::Models::Order.where(razorpay_order_id: rzp_order_id).first
      if order && order.razorpay_payment_id.nil?
        order.update(razorpay_payment_id: rzp_payment_id)
        notify_order(order.reload)
        App.logger.info("Webhook: order #{order.order_number} marked paid (#{rzp_payment_id})")
      end
    end

    return_success('ok')
  rescue => e
    App.logger.error("Razorpay webhook: #{e.message}")
    # Always return 200 so Razorpay does not keep retrying on application errors
    { status: 'ok' }
  end

  def self.fields
    { save: [] }
  end

  private

  def notify_order(order)
    send_admin_notification(order)
    send_customer_confirmation(order)
  end

  def send_admin_notification(order)
    items_text = Array(order.items).map do |i|
      "  • #{i['name']} x#{i['qty']} — ₹#{i['price'].to_i * i['qty'].to_i}"
    end.join("\n")

    body = <<~BODY
      New order received on Crave Better Foods!

      Order ID : ##{order.order_number}
      Customer : #{order.customer_name}
      Phone    : #{order.customer_phone}
      Email    : #{order.customer_email}

      Delivery Address:
        #{order.address_flat}, #{order.address_area}
        #{order.address_city}#{order.address_state ? ", #{order.address_state}" : ''} - #{order.address_pin}

      Items:
      #{items_text}

      Item Total   : ₹#{order.item_total}
      Delivery Fee : #{order.delivery_fee == 0 ? 'FREE' : "₹#{order.delivery_fee}"}
      Grand Total  : ₹#{order.grand_total}

      Payment Method : ONLINE (Razorpay)
      Payment ID     : #{order.razorpay_payment_id}
      Placed at      : #{order.created_at}
    BODY

    Mail.new do
      from    ENV['EMAIL_USER']
      to      App::Services::Orders::ADMIN_EMAIL
      subject "New Order ##{order.order_number} — ₹#{order.grand_total} | Crave Better"
      body    body
    end.deliver!
  rescue => e
    App.logger.error("Admin email failed: #{e.message}")
  end

  def send_customer_confirmation(order)
    return unless order.customer_email.to_s.strip.length > 0

    items_text = Array(order.items).map do |i|
      "  • #{i['name']} x#{i['qty']} — ₹#{i['price'].to_i * i['qty'].to_i}"
    end.join("\n")

    body = <<~BODY
      Hi #{order.customer_name},

      Thank you for your order! We've received it and will begin preparing it shortly.

      Order ID : ##{order.order_number}

      Items:
      #{items_text}

      Item Total   : ₹#{order.item_total}
      Delivery Fee : #{order.delivery_fee == 0 ? 'FREE' : "₹#{order.delivery_fee}"}
      Grand Total  : ₹#{order.grand_total}

      Payment : Online (Razorpay) ✓

      Delivery Address:
        #{order.address_flat}, #{order.address_area}
        #{order.address_city}#{order.address_state ? ", #{order.address_state}" : ''} - #{order.address_pin}

      If you have any questions, reach us at #{App::Services::Orders::ADMIN_EMAIL}.

      Thank you for choosing Crave Better Foods!
    BODY

    Mail.new do
      from    ENV['EMAIL_USER']
      to      order.customer_email
      subject "Order Confirmed ##{order.order_number} — Crave Better Foods"
      body    body
    end.deliver!
  rescue => e
    App.logger.error("Customer email failed: #{e.message}")
  end
end
