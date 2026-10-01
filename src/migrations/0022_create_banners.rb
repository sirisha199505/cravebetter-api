Sequel.migration do
  up do
    # Homepage hero slider. Before this the slides were hardcoded in
    # HomeBanner.jsx; now the admin manages them.
    create_table(:banners) do
      primary_key :id
      String   :title                       # alt text, also the admin label
      String   :image_url, null: false, text: true
      String   :link_url,  text: true       # optional click-through
      Integer  :position,  default: 0
      Boolean  :active,    default: true
      DateTime :created_at
      DateTime :updated_at

      index [:active, :position]
    end

    # Carry over the two Diwali slides that were live in the code, so the
    # homepage looks the same the moment this runs. They are static files in
    # the SPA's public/, hence the relative URLs.
    now = Time.now
    self[:banners].multi_insert([
      { title: 'This Diwali, Gift Better — Crave Better gift hampers, launching soon',
        image_url: '/diwali-banner-1.webp', position: 0, active: true,
        created_at: now, updated_at: now },
      { title: 'A Sweeter Diwali Ahead — Crave Better Dark Choco, Milk Choco and Classic Squares, launching soon',
        image_url: '/diwali-banner-2.webp', position: 1, active: true,
        created_at: now, updated_at: now },
    ])
  end

  down do
    drop_table(:banners)
  end
end
