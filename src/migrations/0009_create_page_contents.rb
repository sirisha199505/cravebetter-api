Sequel.migration do
  change do
    create_table(:page_contents) do
      primary_key :id
      String   :slug,       null: false, unique: true
      String   :title,      null: false, default: ''
      String   :content,    text: true,  default: ''
      DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, default: Sequel::CURRENT_TIMESTAMP
      index :slug, unique: true
    end
  end
end
