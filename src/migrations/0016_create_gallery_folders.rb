Sequel.migration do
  up do
    # An event ("Diwali Mela 2025") is a folder: the admin creates it once and
    # drops that event's photos into it. Folders are rows rather than the old
    # free-text gallery_items.category so they can be renamed, reordered and
    # hidden without rewriting every image, and so a freshly created folder
    # exists before its first upload.
    create_table(:gallery_folders) do
      primary_key :id
      String   :name,        null: false
      String   :slug,        null: false, unique: true
      String   :description, text: true
      # The year the event happened — drives the "filter by year" control on
      # the public gallery, and is not always the year it was uploaded.
      Integer  :year
      Integer  :position,    default: 0
      Boolean  :active,      default: true
      DateTime :created_at
      DateTime :updated_at

      index [:active, :position]
      index [:active, :year]
    end

    alter_table(:gallery_items) do
      add_foreign_key :folder_id, :gallery_folders, on_delete: :set_null
      add_index [:folder_id, :position]
    end

    # Carry the existing categories over so nothing loses its grouping.
    now   = Time.now
    slugs = {}
    from(:gallery_items)
      .exclude(category: nil)
      .exclude(category: '')
      .distinct
      .order(:category)
      .select_map(:category)
      .each_with_index do |name, i|
        base = name.to_s.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/\A-|-\z/, '')
        base = "folder-#{i + 1}" if base.empty?
        slug = base
        n = 2
        while slugs.key?(slug)
          slug = "#{base}-#{n}"
          n += 1
        end
        slugs[slug] = true

        # A trailing year in the old category name ("Diwali Mela 2024") is the
        # only year signal these rows carry; anything else is left blank for
        # the admin to fill in.
        year = name.to_s[/\b(19|20)\d{2}\b/]&.to_i

        folder_id = from(:gallery_folders).insert(
          name:       name,
          slug:       slug,
          year:       year,
          position:   i,
          active:     true,
          created_at: now,
        )
        from(:gallery_items).where(category: name).update(folder_id: folder_id)
      end
  end

  down do
    alter_table(:gallery_items) do
      drop_index [:folder_id, :position]
      drop_column :folder_id
    end
    drop_table(:gallery_folders)
  end
end
