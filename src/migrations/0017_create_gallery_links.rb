Sequel.migration do
  change do
    # A section of its own on the gallery page: videos and outside links
    # (YouTube, a press article, an Instagram reel) rather than photos, so it
    # is deliberately not tied to a photo folder.
    create_table(:gallery_links) do
      primary_key :id
      String   :title,       null: false
      String   :url,         null: false, text: true
      String   :description, text: true
      # Optional override — YouTube thumbnails are derived from the URL, so
      # this is for links that have no thumbnail of their own.
      String   :thumb_url,   text: true
      Integer  :position,    default: 0
      Boolean  :active,      default: true
      DateTime :created_at
      DateTime :updated_at

      index [:active, :position]
    end
  end
end
