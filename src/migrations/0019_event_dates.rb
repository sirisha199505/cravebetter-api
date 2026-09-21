Sequel.migration do
  up do
    # The gallery filters by year, by month and by a custom date range, so a
    # bare year is no longer enough — both albums and videos carry the date
    # the event actually happened. `year` becomes a derived value.
    alter_table(:gallery_folders) do
      add_column :event_date, Date
      add_index [:active, :event_date]
    end

    alter_table(:gallery_links) do
      add_column :event_date, Date
      add_index [:active, :event_date]
    end

    # Backfill: a year we already know becomes the 1st of January (the only
    # honest reading of "2024"), otherwise fall back to when it was added.
    run <<~SQL
      UPDATE gallery_folders
         SET event_date = COALESCE(make_date(year, 1, 1), created_at::date, CURRENT_DATE)
       WHERE event_date IS NULL;

      UPDATE gallery_links
         SET event_date = COALESCE(make_date(year, 1, 1), created_at::date, CURRENT_DATE)
       WHERE event_date IS NULL;
    SQL

    alter_table(:gallery_folders) do
      drop_index [:active, :year]
      drop_column :year
    end

    alter_table(:gallery_links) do
      drop_index [:active, :year]
      drop_column :year
    end
  end

  down do
    alter_table(:gallery_folders) do
      add_column :year, Integer
      add_index [:active, :year]
    end
    alter_table(:gallery_links) do
      add_column :year, Integer
      add_index [:active, :year]
    end

    run <<~SQL
      UPDATE gallery_folders SET year = EXTRACT(YEAR FROM event_date)::int WHERE event_date IS NOT NULL;
      UPDATE gallery_links   SET year = EXTRACT(YEAR FROM event_date)::int WHERE event_date IS NOT NULL;
    SQL

    alter_table(:gallery_folders) do
      drop_index [:active, :event_date]
      drop_column :event_date
    end
    alter_table(:gallery_links) do
      drop_index [:active, :event_date]
      drop_column :event_date
    end
  end
end
