class App::Services::Orders < App::Services::Base
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
    p = qs  # params come directly, not nested under :data for public endpoint

    order = model.new(
      customer_name:  p[:customer_name],
      customer_phone: p[:customer_phone],
      address_flat:   p[:address_flat],
      address_area:   p[:address_area],
      address_city:   p[:address_city],
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
end
