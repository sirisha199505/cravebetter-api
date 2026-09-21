Sequel.migration do
  up do
    alter_table(:gallery_links) do
      # Same idea as gallery_folders.year: the year the video is about, which
      # is not always the year the link was added. Drives the year filter on
      # the Videos tab.
      add_column :year, Integer
      add_index [:active, :year]
    end

    # Existing rows predate the column — fall back to when they were added.
    from(:gallery_links).exclude(created_at: nil).update(
      year: Sequel.function(:extract, Sequel.lit('YEAR FROM created_at')).cast(:integer),
    )
  end

  down do
    alter_table(:gallery_links) do
      drop_index [:active, :year]
      drop_column :year
    end
  end
end
