Sequel.migration do
  change do
    create_table(:orders) do
      primary_key :id

      # Customer info
      String  :customer_name,  null: false
      String  :customer_phone, null: false

      # Delivery address
      String  :address_flat,   null: false
      String  :address_area,   null: false
      String  :address_city,   null: false
      String  :address_pin,    null: false

      # Payment
      String  :payment_method, default: 'upi'   # upi | card | cod

      # Order items stored as JSONB array: [{id, name, price, qty, image}]
      column  :items, :jsonb, default: '[]'

      # Totals (in rupees)
      Integer :item_total,    default: 0
      Integer :delivery_fee,  default: 0
      Integer :platform_fee,  default: 5
      Integer :grand_total,   default: 0

      # Lifecycle
      String  :status, default: 'pending'   # pending | preparing | out_for_delivery | delivered | cancelled

      DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, default: Sequel::CURRENT_TIMESTAMP

      index :status
      index :created_at
    end
  end
end
