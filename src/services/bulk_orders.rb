class App::Services::BulkOrders < App::Services::Base
  def model; App::Models::BulkOrder; end

  # Public — anyone can submit a bulk order request
  def create
    p = qs[:data] || qs

    req = model.new(
      business_name:  p[:business_name].to_s.strip,
      contact_name:   p[:contact_name].to_s.strip,
      contact_phone:  p[:contact_phone].to_s.strip,
      contact_email:  p[:contact_email].to_s.strip,
      quantity:       p[:quantity].to_i,
      message:        p[:message].to_s.strip,
      status:         'new',
    )

    if req.save
      return_success(req.to_pos)
    else
      return_errors!(req.errors)
    end
  rescue => e
    App.logger.error(e.message)
    return_errors!(e.message)
  end

  # Admin — list all bulk order requests
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

  # Admin — update status
  def update_status
    new_status = (qs[:data] || qs)[:status].to_s
    unless App::Models::BulkOrder::STATUSES.include?(new_status)
      return_errors!("Invalid status. Allowed: #{App::Models::BulkOrder::STATUSES.join(', ')}")
    end
    item.update(status: new_status)
    return_success(item.to_pos)
  rescue => e
    return_errors!(e.message)
  end

  def self.fields
    { save: [:business_name, :contact_name, :contact_phone, :contact_email, :quantity, :message, :status] }
  end
end
