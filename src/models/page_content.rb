class App::Models::PageContent < Sequel::Model(:page_contents)
  def to_pos
    {
      id:         id,
      slug:       slug,
      title:      title,
      content:    content,
      updated_at: updated_at
    }
  end
end
