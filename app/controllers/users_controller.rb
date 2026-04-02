class UsersController < ApplicationController
  skip_before_action :require_login, only: %i[new create]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if user_params[:password] != user_params[:password_confirmation]
      flash.now[:alert] = "Password confirmation does not match."
      return render :new, status: :unprocessable_entity
    end

    begin
      result = ApiAuthenticationGem::Auth.signup(
        email: user_params[:email].to_s.strip.downcase,
        password: user_params[:password]
      )

      cookies.signed[:jwt_token] = {
        value: result[:token],
        httponly: true,
        secure: Rails.env.production?,
        same_site: :strict
      }

      if params[:original_url].present?
        redirect_to new_link_path(original_url: params[:original_url]), notice: "Account created and signed in."
      else
        redirect_to links_path, notice: "Account created and signed in."
      end
    rescue ActiveRecord::RecordInvalid => e
      flash.now[:alert] = e.record.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end
