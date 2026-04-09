Sequel.migration do
  change do
    alter_table(:orders) do
      add_column :customer_email, String
      add_column :address_state,  String
    end
  end
end
