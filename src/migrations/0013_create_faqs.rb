Sequel.migration do
  change do
    create_table(:faqs) do
      primary_key :id
      String   :question, null: false, text: true
      String   :answer,   null: false, text: true
      Integer  :position, default: 0
      Boolean  :active,   default: true
      DateTime :created_at
      DateTime :updated_at
    end
  end
end
