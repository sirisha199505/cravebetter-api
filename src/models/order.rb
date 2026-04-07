class App::Models::Order < Sequel::Model
  STATUSES = %w[pending preparing out_for_delivery delivered cancelled].freeze

  def validate
    super
    validates_presence [:customer_name, :customer_phone, :address_flat, :address_area, :address_city, :address_pin]
    validates_includes STATUSES, :status
  end

  def to_pos
    {
      id:             id,
      customer_name:  customer_name,
      customer_phone: customer_phone,
      address: {
        flat: address_flat,
        area: address_area,
        city: address_city,
        pin:  address_pin,
      },
      payment_method: payment_method,
      items:          items,
      item_total:     item_total,
      delivery_fee:   delivery_fee,
      platform_fee:   platform_fee,
      grand_total:    grand_total,
      status:         status,
      created_at:     created_at,
    }
  end
end
