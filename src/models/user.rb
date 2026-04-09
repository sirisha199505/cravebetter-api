class App::Models::User < Sequel::Model
  include BCrypt

  def admin?
    role == 1
  end

  def rgm?
    role == 2
  end

  def validate
    super
    validates_presence [:full_name, :email]
    validates_unique(:email) { |ds| ds.where(active: true) }
  end

  def password
    @password ||= Password.new(encoded_password)
  end

  def password=(new_password)
    @password = Password.create(new_password)
    self.encoded_password = @password
  end

  def as_pos
    {
      id:           id,
      email:        email,
      full_name:    full_name,
      phone_number: phone_number,
      role:         role,
      active:       active,
    }
  end
end
