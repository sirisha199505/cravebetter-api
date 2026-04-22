Sequel.migration do
  change do
    alter_table(:bulk_orders) do
      add_column :product_preference, String
    end
  end
end
