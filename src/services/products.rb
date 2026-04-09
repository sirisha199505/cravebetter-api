class App::Services::Products < App::Services::Base
  def model; App::Models::Product; end

  def list
    ds = model.where(active: true).order(:id)
    ds = ds.where(category: qs[:category]) if qs[:category].present?
    return_success(ds.all.map(&:to_pos))
  end

  def get
    return_success(item.to_pos)
  end

  def create
    obj = model.new(data_for(:save))
    save(obj)
  end

  def update
    item.set_fields(data_for(:save), data_for(:save).keys)
    save(item)
  end

  def delete
    item.update(active: false)
    return_success('Product deactivated')
  rescue => e
    return_errors!(e.message)
  end

  def self.fields
    {
      save: [:name, :category, :description, :price, :image_url, :badge, :badge_color,
             :rating, :orders_count, :active,
             :protein, :calories, :carbs, :fat, :weight, :ingredients, :benefits]
    }
  end
end
