class App::Services::Orders < App::Services::Base
  ADMIN_EMAIL = 'luckysirisha1@gmail.com'.freeze

  def model; App::Models::Order; end

  def list
    ds = model.order(Sequel.desc(:created_at))
    ds = ds.where(status: qs[:status]) if qs[:status].present?
    count = ds.count
    return_success(
      ds.offset(offset).limit(limit).all.map(&:to_pos),
      total_pages: (count / page_size.to_f).ceil,
      total_count: count
    )
  end

  def get
    return_success(item.to_pos)
  end

  # Public — called from checkout (no auth required)
  def place
    p = qs

    order = model.new(
      customer_name:  p[:customer_name],
      customer_phone: p[:customer_phone],
      customer_email: p[:customer_email],
      address_flat:   p[:address_flat],
      address_area:   p[:address_area],
      address_city:   p[:address_city],
      address_state:  p[:address_state],
      address_pin:    p[:address_pin],
      payment_method: p[:payment_method] || 'upi',
      items:          p[:items] || [],
      item_total:     p[:item_total].to_i,
      delivery_fee:   p[:delivery_fee].to_i,
      platform_fee:   (p[:platform_fee] || 5).to_i,
      grand_total:    p[:grand_total].to_i,
      status:         'pending',
    )

    if order.save
      send_admin_notification(order)
      return_success(order.to_pos)
    else
      return_errors!(order.errors)
    end
  rescue => e
    App.logger.error(e.message)
    return_errors!(e.message)
  end

  # Admin — update order status
  def update_status
    new_status = qs[:status]
    unless App::Models::Order::STATUSES.include?(new_status)
      return_errors!("Invalid status. Allowed: #{App::Models::Order::STATUSES.join(', ')}")
    end
    item.update(status: new_status)
    return_success(item.to_pos)
  rescue => e
    return_errors!(e.message)
  end

  def self.fields
    { save: [] }
  end

  private

  def send_admin_notification(order)
    items_text = Array(order.items).map do |i|
      "  • #{i['name']} x#{i['qty']} — ₹#{i['price'].to_i * i['qty'].to_i}"
    end.join("\n")

    body = <<~BODY
      New order received on Crave Better Foods!

      Order ID : ##{order.id}
      Customer : #{order.customer_name}
      Phone    : #{order.customer_phone}
      Email    : #{order.customer_email}

      Delivery Address:
        #{order.address_flat}, #{order.address_area}
        #{order.address_city}#{order.address_state ? ", #{order.address_state}" : ''} - #{order.address_pin}

      Items:
      #{items_text}

      Item Total   : ₹#{order.item_total}
      Delivery Fee : ₹#{order.delivery_fee}
      Platform Fee : ₹#{order.platform_fee}
      Grand Total  : ₹#{order.grand_total}

      Payment Method: #{order.payment_method&.upcase}
      Placed at: #{order.created_at}
    BODY

    Mail.new do
      from    ENV['EMAIL_USER']
      to      ADMIN_EMAIL
      subject "New Order ##{order.id} — ₹#{order.grand_total} | Crave Better"
      body    body
    end.deliver!
  rescue => e
    App.logger.error("Admin email failed: #{e.message}")
    # Don't fail the order if email fails
  end
end
