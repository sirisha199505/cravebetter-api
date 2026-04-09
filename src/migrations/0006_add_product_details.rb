Sequel.migration do
  change do
    alter_table(:products) do
      add_column :protein,     String
      add_column :calories,    String
      add_column :carbs,       String
      add_column :fat,         String
      add_column :weight,      String
      add_column :ingredients, String, text: true
      add_column :benefits,    :jsonb, default: '[]'
    end
  end
end
