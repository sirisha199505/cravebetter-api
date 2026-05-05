Sequel.migration do
  change do
    alter_table(:orders) do
      add_column :order_number, String, default: ''
    end
  end
end
