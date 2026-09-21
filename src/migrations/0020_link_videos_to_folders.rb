Sequel.migration do
  up do
    # A video belongs to the event it was shot at, not to a section of its
    # own — the same folder that holds that event's photos. Deleting the
    # folder takes its videos with it, as it already does its photos.
    alter_table(:gallery_links) do
      add_foreign_key :folder_id, :gallery_folders, on_delete: :cascade
      add_index [:folder_id, :position]
    end
  end

  down do
    alter_table(:gallery_links) do
      drop_index [:folder_id, :position]
      drop_column :folder_id
    end
  end
end
