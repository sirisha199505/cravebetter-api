class App::Services::Testimonials < App::Services::Base
  def model; App::Models::Testimonial; end

  # Public. ?featured=true is what the homepage strip asks for; the
  # /testimonials page asks for everything.
  def list
    ds = model.where(active: true)
    ds = ds.where(featured: true) if qs[:featured].to_s == 'true'
    return_success(ds.order(:position, :id).all.map(&:to_pos))
  end

  def admin_list
    items = model.order(:position, :id).all.map { |t| t.to_pos.merge(active: t.active) }
    return_success(items)
  end

  def create
    obj = model.new(data_for(:save))
    obj.position = model.count if obj.position.nil? || obj.position.zero?
    obj.created_at = Time.now
    save(obj)
  end

  def update
    data = data_for(:save)
    item.set_fields(data, data.keys)
    save(item)
  end

  # Soft delete, matching FAQs — a testimonial is a customer's words and the
  # client may want it back.
  def delete
    item.update(active: false)
    return_success('Testimonial deleted')
  rescue => e
    return_errors!(e.message)
  end

  def self.fields
    { save: [:name, :role, :message, :rating, :image_url, :photo_url, :video_url, :featured, :position, :active] }
  end
end
