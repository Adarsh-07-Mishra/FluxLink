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
