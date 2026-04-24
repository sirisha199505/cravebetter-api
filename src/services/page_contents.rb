class App::Services::PageContents < App::Services::Base
  def model; App::Models::PageContent; end

  def get_by_slug
    obj = model.first(slug: qs[:slug])
    return return_success({ slug: qs[:slug], title: '', content: '' }) unless obj
    return_success(obj.to_pos)
  end

  def upsert
    obj = model.first(slug: qs[:slug]) || model.new(slug: qs[:slug])
    fields = data_for(:save)
    obj.set_fields(fields, fields.keys)
    obj.updated_at = Time.now
    save(obj)
  end

  def self.fields
    {
      save: [:title, :content]
    }
  end
end
