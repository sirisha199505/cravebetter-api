
options = {
  address:              ENV['EMAIL_SMTP_SERVER'],
  port:                 465,
  domain:               ENV['EMAIL_DOMAIN'],
  user_name:            ENV['EMAIL_USER'],
  password:             ENV['EMAIL_PASSWORD'],
  authentication:       'login',
  enable_starttls_auto: false,
  ssl:                  true,
}

Mail.defaults do
  delivery_method :smtp, options
end



# mail = Mail.new do
#   from    'noreply@vhrr.net'
#   to      'sathish@pasupunuri.com'  # Replace with the recipient email
#   subject 'Test email'
#   body    'This is a test email sent from a Ruby Roda app!'
# end

# mail.deliver!