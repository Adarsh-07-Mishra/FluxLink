class SessionsController < ApplicationController
  skip_before_action :require_login, only: %i[new create]

  def new
    redirect_to links_path if logged_in?
  end

  def create
    result = ApiAuthenticationGem::Auth.login(
      email: params[:email].to_s.strip.downcase,
      password: params[:password]
    )

    if result.present?
      cookies.signed[:jwt_token] = {
        value: result[:token],
        httponly: true,
        secure: Rails.env.production?,
        same_site: :strict
      }

      if params[:original_url].present?
        redirect_to new_link_path(original_url: params[:original_url]), notice: "Signed in successfully."
      else
        redirect_to links_path, notice: "Signed in successfully."
      end
    else
      flash.now[:alert] = "Invalid email or password."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    cookies.delete(:jwt_token)
    redirect_to login_path, notice: "Logged out successfully."
  end
end
