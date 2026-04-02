ApiAuthenticationGem.configure do |config|
  config.secret_key = ENV["API_AUTH_SECRET_KEY"] || Rails.application.secret_key_base
  config.user_class = "User"
end
