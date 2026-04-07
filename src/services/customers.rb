class App::Services::Customers < App::Services::Base

  def list
    ds = App::Models::User.where(active: true, role: 0).order(Sequel.desc(:created_at))

    if qs[:search].present?
      q = "%#{qs[:search].strip}%"
      ds = ds.where(
        Sequel.|(
          Sequel.ilike(:full_name, q),
          Sequel.ilike(:email, q),
          Sequel.like(:phone_number, q)
        )
      )
    end

    count = ds.count
    customers = ds.offset(offset).limit(page_size).all.map do |u|
      {
        id:           u.id,
        full_name:    u.full_name,
        email:        u.email,
        phone_number: u.phone_number,
        active:       u.active,
        created_at:   u.created_at,
        last_login:   u.last_logged_in_at,
      }
    end

    return_success(customers, total: count, page: (qs[:page] || 1).to_i, page_size: page_size)
  rescue => e
    App.logger.error("Customers list error: #{e.message}")
    return_errors!(e.message)
  end

end
