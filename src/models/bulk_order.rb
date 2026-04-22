class App::Models::BulkOrder < Sequel::Model(:bulk_orders)
  STATUSES = %w[new contacted converted declined].freeze

  def validate
    super
    validates_presence [:business_name, :contact_phone, :quantity]
    validates_includes STATUSES, :status
  end

  def to_pos
    {
      id:                 id,
      business_name:      business_name,
      contact_name:       contact_name,
      contact_phone:      contact_phone,
      contact_email:      contact_email,
      product_preference: product_preference,
      quantity:           quantity,
      message:            message,
      status:             status,
      created_at:         created_at,
    }
  end
end
