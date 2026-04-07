Sequel.migration do
  change do
    create_table(:bulk_orders) do
      primary_key :id

      String  :business_name,  null: false
      String  :contact_name
      String  :contact_phone,  null: false
      String  :contact_email

      Integer :quantity,       null: false, default: 0

      String  :message,        text: true

      # Lifecycle: new | contacted | converted | declined
      String  :status, default: 'new'

      DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, default: Sequel::CURRENT_TIMESTAMP

      index :status
      index :created_at
    end
  end
end
