class HomeController < ApplicationController
  skip_before_action :require_login

  def index
    @original_url = params[:url] || params[:original_url]
  end

  def features
  end

  def pricing
  end

  def about
  end

  def contact
  end

  def documents
  end

  def terms
  end

  def privacy
  end

  def agreement
    @pending_signup = session[:pending_signup]

    if @pending_signup.blank?
      redirect_to signup_path, alert: "Please complete your signup details before accepting the agreement."
    end
  end

  def accept_agreement
    pending = session.delete(:pending_signup)

    unless pending.present?
      redirect_to signup_path, alert: "Please complete your signup details before accepting the agreement."
      return
    end

    user_attrs = pending.slice("email", "password", "password_confirmation")
    @user = User.new(user_attrs.merge(agree_terms: "1"))

    if User.where("lower(email) = ?", @user.email.to_s.strip.downcase).exists?
      @pending_signup = pending
      flash.now[:alert] = "An account with that email already exists. Please log in instead."
      return render :agreement, status: :unprocessable_entity
    end

    if @user.invalid?
      @pending_signup = pending
      flash.now[:alert] = @user.errors.full_messages.to_sentence
      render :agreement, status: :unprocessable_entity
      return
    end

    begin
      result = ApiAuthenticationGem::Auth.signup(
        email: @user.email.to_s.strip.downcase,
        password: @user.password
      )

      cookies.signed[:jwt_token] = {
        value: result[:token],
        httponly: true,
        secure: Rails.env.production?,
        same_site: :strict
      }

      if pending["original_url"].present?
        redirect_to new_link_path(original_url: pending["original_url"]), notice: "Account created and signed in."
      else
        redirect_to links_path, notice: "Account created and signed in."
      end
    rescue ActiveRecord::RecordInvalid => e
      @pending_signup = pending
      flash.now[:alert] = e.record.errors.full_messages.to_sentence
      render :agreement, status: :unprocessable_entity
    end
  end

  def wifi_qr
    # Require login for WiFi QR functionality
    unless logged_in?
      redirect_to signup_path, notice: "Please sign up to create and save WiFi QR codes."
      return
    end

    # Check if we have WiFi data from session (for newly generated codes)
    if session[:wifi_qr].present?
      wifi_data = session[:wifi_qr]

      # Save to database if user is logged in
      if logged_in?
        @wifi_network = current_user.wifi_networks.create(
          ssid: wifi_data['ssid'],
          password: wifi_data['password'],
          security: wifi_data['security']
        )
      end

      # Generate WiFi QR code string
      # For open networks (nopass), don't include password parameter
      if wifi_data['security'] == 'nopass'
        wifi_string = "WIFI:T:nopass;S:#{wifi_data['ssid']};;"
      else
        wifi_string = "WIFI:T:#{wifi_data['security']};S:#{wifi_data['ssid']};P:#{wifi_data['password']};;"
      end

      # Generate QR code
      qr = RQRCode::QRCode.new(wifi_string)

      # Store in instance variables for the view
      @ssid = wifi_data['ssid']
      @password = wifi_data['password'].present? ? "•" * wifi_data['password'].length : ""
      @security = wifi_data['security']
      @wifi_string = wifi_string
      @qr_code = qr.as_svg(
        offset: 0,
        color: '000',
        shape_rendering: 'crispEdges',
        module_size: 6,
        standalone: true
      )

      # Clear session data after use
      session.delete(:wifi_qr)

    # Check if we're viewing a saved network
    elsif params[:id].present? && logged_in?
      @wifi_network = current_user.wifi_networks.find_by(id: params[:id])
      if @wifi_network
        # Generate WiFi QR code string for saved network
        if @wifi_network.security == 'nopass'
          wifi_string = "WIFI:T:nopass;S:#{@wifi_network.ssid};;"
        else
          wifi_string = "WIFI:T:#{@wifi_network.security};S:#{@wifi_network.ssid};P:#{@wifi_network.password};;"
        end

        # Generate QR code
        qr = RQRCode::QRCode.new(wifi_string)

        # Store in instance variables for the view
        @ssid = @wifi_network.ssid
        @password = @wifi_network.password.present? ? "•" * @wifi_network.password.length : ""
        @security = @wifi_network.security
        @wifi_string = wifi_string
        @qr_code = qr.as_svg(
          offset: 0,
          color: '000',
          shape_rendering: 'crispEdges',
          module_size: 6,
          standalone: true
        )
      end
    end

    # Load saved networks for logged-in users
    @saved_networks = logged_in? ? current_user.wifi_networks.order(created_at: :desc) : []
  end

  def generate_wifi_qr
    # Require login for WiFi QR generation
    unless logged_in?
      redirect_to signup_path, notice: "Please sign up to create WiFi QR codes."
      return
    end

    ssid = params[:ssid].to_s.strip
    password = params[:password].to_s
    security = params[:security]

    if ssid.blank?
      redirect_to wifi_qr_path, alert: "Please enter a network name (SSID)."
      return
    end

    # Store parameters in session for the view
    session[:wifi_qr] = {
      ssid: ssid,
      password: password,
      security: security
    }

    redirect_to wifi_qr_path
  end

  def shorten
    original_url = params[:original_url].to_s.strip

    if original_url.blank?
      redirect_to root_path, alert: "Please enter a valid URL to shorten."
      return
    end

    if logged_in?
      redirect_to new_link_path(original_url: original_url)
    else
      redirect_to signup_path(original_url: original_url)
    end
  end
end
