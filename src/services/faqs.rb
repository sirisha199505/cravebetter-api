class App::Services::Faqs < App::Services::Base
  def model; App::Models::Faq; end

  def list
    ds = model.where(active: true).order(:position, :id)
    return_success(ds.all.map(&:to_pos))
  end

  def admin_list
    ds = model.order(:position, :id)
    return_success(ds.all.map { |f| f.to_pos.merge(active: f.active) })
  end

  def create
    obj = model.new(data_for(:save))
    obj.position = model.count if obj.position.nil? || obj.position.zero?
    obj.created_at = Time.now
    obj.updated_at = Time.now
    save(obj)
  end

  def update
    item.set_fields(data_for(:save), data_for(:save).keys)
    item.updated_at = Time.now
    save(item)
  end

  def delete
    item.update(active: false)
    return_success('FAQ deleted')
  rescue => e
    return_errors!(e.message)
  end

  def self.fields
    { save: [:question, :answer, :position, :active] }
  end
end
