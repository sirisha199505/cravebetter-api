Sequel.migration do
  change do
    alter_table(:orders) do
      add_column :razorpay_order_id,   String
      add_column :razorpay_payment_id, String
      add_index  :razorpay_order_id
    end
  end
end
