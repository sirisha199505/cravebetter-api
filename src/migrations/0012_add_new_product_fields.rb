Sequel.migration do
  change do
    alter_table(:products) do
      add_column :fiber,          String
      add_column :transfat,       String
      add_column :original_price, Integer, default: 0
      add_column :tagline,        String
      add_column :pack,           String
    end
  end
end
