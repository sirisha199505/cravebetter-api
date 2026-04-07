class App::Services::Session < App::Services::Base

  def login
    begin
      user = User.find(email: params[:email]&.strip, active: true)
      if (user && user.password == params[:password])
        if App.cu.current_did.present? && user.id != 7665
          user.device_uuid ||= App.cu.current_did
          if user.device_uuid != App.cu.current_did
            return_errors!("Not allowed to login from multiple devices. Please contact support.")
          end
        end
        user.last_logged_in_at = Time.now
        user.current_session_id = CurrentUser.encoded_token(user)
        puts "USER IP: #{App.cu.ip}"
        user.save
        return_success(token: user.current_session_id, info: user.as_pos)
      else
        return_errors!("Invalid Email / Password")
      end
    rescue => e
      puts e.message
      puts e.backtrace
      return_errors!("Some error!!!")
    end
  end

  def register
    data      = params || {}
    email     = data[:email].to_s.strip.downcase
    full_name = data[:full_name].to_s.strip
    password  = data[:password].to_s
    phone     = data[:phone_number].to_s.strip

    return err('Name, email and password are required.')      if full_name.empty? || email.empty? || password.empty?
    return err('Password must be at least 6 characters.')    if password.length < 6
    return err('An account with this email already exists.') if User.find(email: email, active: true)

    user = User.new(
      full_name:    full_name,
      email:        email,
      phone_number: phone.empty? ? nil : phone,
      role:         0,
      active:       true
    )
    user.password = password

    # Check validity before saving (avoids Sequel::ValidationFailed)
    unless user.valid?
      msg = user.errors.full_messages.first || 'Validation failed.'
      return err(msg)
    end

    user.save
    user.current_session_id = CurrentUser.encoded_token(user)
    user.last_logged_in_at  = Time.now
    user.save

    return_success(token: user.current_session_id, info: user.as_pos)
  rescue => e
    App.logger.error("Register error: #{e.message}\n#{e.backtrace.first(3).join("\n")}")
    err("Registration failed: #{e.message}")
  end

  private

  def err(msg)
    { status: 'error', data: msg }
  end

end
