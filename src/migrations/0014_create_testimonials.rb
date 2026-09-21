Sequel.migration do
  change do
    create_table(:testimonials) do
      primary_key :id
      String   :name,      null: false
      String   :role
      String   :message,   null: false, text: true
      Integer  :rating,    default: 5
      String   :image_url, text: true
      Boolean  :featured,  default: true
      Integer  :position,  default: 0
      Boolean  :active,    default: true
      DateTime :created_at
      DateTime :updated_at

      index [:active, :featured]
    end
  end
end
