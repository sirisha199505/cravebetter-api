class App::Services::Banners < App::Services::Base
  def model; App::Models::Banner; end

  # Public: the homepage slider.
  def list
    return_success(model.where(active: true).order(:position, :id).all.map(&:to_pos))
  end

  def admin_list
    items = model.order(:position, :id).all.map { |b| b.to_pos.merge(active: b.active) }
    return_success(items)
  end

  def create
    obj = model.new(data_for(:save))
    obj.position = model.count if obj.position.nil?
    obj.created_at = obj.updated_at = Time.now
    save(obj)
  end

  def update
    data = data_for(:save)
    item.set_fields(data, data.keys)
    item.updated_at = Time.now
    save(item)
  end

  # Hard delete, like gallery images — a banner is just a picture, and
  # "Active" already covers taking one down temporarily. Only objects this
  # app uploaded are removed from the bucket (own_url? guards pasted URLs).
  def delete
    url = item.image_url
    item.destroy
    App::Services::Uploads.delete_by_urls(url) if App::Services::Uploads.own_url?(url)
    return_success('Banner deleted')
  rescue => e
    App.logger.error(e.message)
    return_errors!(e.message, 400)
  end

  def self.fields
    { save: [:title, :image_url, :link_url, :position, :active] }
  end
end
