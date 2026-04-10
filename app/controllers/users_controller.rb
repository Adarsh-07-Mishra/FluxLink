class UsersController < ApplicationController
  skip_before_action :require_login, only: %i[new create]

  def new
    @user = User.new
  end

  def create
    normalized_email = user_params[:email].to_s.strip.downcase
    @user = User.new(user_params)

    if user_params[:password] != user_params[:password_confirmation]
      flash.now[:alert] = "Password confirmation does not match."
      return render :new, status: :unprocessable_entity
    end

    if user_params[:agree_terms] == "1" && User.where("lower(email) = ?", normalized_email).exists?
      @user.errors.add(:email, "has already been taken")
      flash.now[:alert] = "An account with that email already exists. Please log in instead."
      return render :new, status: :unprocessable_entity
    end

    terms_checked = user_params[:agree_terms] == "1"
    @user.valid?

    if !terms_checked && @user.errors.attribute_names == [:agree_terms]
      session[:pending_signup] = {
        email: user_params[:email],
        password: user_params[:password],
        password_confirmation: user_params[:password_confirmation],
        original_url: params[:original_url]
      }

      redirect_to agreement_path
      return
    end

    if @user.invalid?
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
    params.require(:user).permit(:email, :password, :password_confirmation, :agree_terms)
  end
end
