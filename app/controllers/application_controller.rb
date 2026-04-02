class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :require_login
  helper_method :current_user, :logged_in?

  private

  def current_user
    return @current_user if defined?(@current_user)

    token = cookies.signed[:jwt_token] || bearer_token
    if token.present?
      payload = ApiAuthenticationGem::Auth.decode(token)
      @current_user = User.find_by(id: payload&.dig("user_id"))
    else
      @current_user = nil
    end
  end

  def logged_in?
    current_user.present?
  end

  def require_login
    return if logged_in?

    redirect_to login_path, alert: "Please log in first."
  end

  def bearer_token
    auth_header = request.headers["Authorization"]
    return unless auth_header.present?

    parts = auth_header.split(" ")
    parts.size == 2 && parts[0] == "Bearer" ? parts[1] : nil
  end
end
