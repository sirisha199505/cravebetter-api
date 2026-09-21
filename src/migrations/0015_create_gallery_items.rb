Sequel.migration do
  change do
    create_table(:gallery_items) do
      primary_key :id
      String   :title,     text: true
      String   :category
      String   :image_url, null: false, text: true
      String   :thumb_url, text: true
      Integer  :position,  default: 0
      Boolean  :active,    default: true
      DateTime :created_at
      DateTime :updated_at

      # The public gallery always filters on active and usually on category,
      # and orders by position — this covers both at 2000+ rows.
      index [:active, :category, :position]
    end
  end
end
