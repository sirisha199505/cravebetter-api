Sequel.migration do
  up do
    # A review can come with its own media, separate from the customer's
    # avatar in :image_url — a photo they sent with the review, and/or a
    # video review on YouTube.
    alter_table(:testimonials) do
      add_column :photo_url, String, text: true
      add_column :video_url, String, text: true
    end
  end

  down do
    alter_table(:testimonials) do
      drop_column :photo_url
      drop_column :video_url
    end
  end
end
