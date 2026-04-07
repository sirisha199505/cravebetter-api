Sequel.migration do
  change do
    create_table(:products) do
      primary_key :id
      String  :name,        null: false
      String  :category,    null: false
      String  :description, text: true
      Integer :price,       null: false, default: 0
      String  :image_url,   text: true
      String  :badge
      String  :badge_color
      Float   :rating,      default: 0.0
      Integer :orders_count, default: 0
      Boolean :active,      default: true
      DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, default: Sequel::CURRENT_TIMESTAMP

      index :category
      index :active
    end
  end
end
