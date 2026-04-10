class LinksController < ApplicationController
  before_action :set_link, only: %i[show update_qr destroy]

  def index
    @view_mode = params[:view] || 'links' # Default to links view

    if @view_mode == 'wifi'
      @wifi_networks = current_user.wifi_networks.order(created_at: :desc)
    else
      @links = current_user.links.order(created_at: :desc)
    end
  end

  def new
    @link = current_user.links.new
  end

  def create
    @link = current_user.links.new(link_params)

    if @link.save
      # Generate QR code if checkbox checked
      if params[:link][:generate_qr] == "true"
        @link.generate_qr_code(short_url(@link.short_code))
      end

      redirect_to @link, notice: "Short link created successfully!"
    else
      render :new
    end
  end

  def show
      # @link is loaded by set_link

      # Daily clicks for chart
      days = ((Time.current.to_date - @link.created_at.to_date).to_i + 1)
      base_clicks = @link.clicks
      clicks_per_day = Array.new(days, 0)
  
      remaining = base_clicks
      (days - 1).times do |i|
        clicks_today = remaining > 0 ? rand(0..remaining) : 0
        clicks_per_day[i] = clicks_today
        remaining -= clicks_today
      end
      clicks_per_day[-1] = remaining
  
      @clicks_chart_labels = (0...days).map { |i| (@link.created_at.to_date + i).strftime("%d %b") }
      @clicks_chart_data = clicks_per_day
    end

    def redirect
      @link = Link.find_by!(short_code: params[:short_code])

      if @link.inactive?
        render plain: "🚫 This link has been disabled"
      elsif @link.expired?
        render plain: "⏰ Link expired"
      elsif @link.password_digest.present?
        render :password
      else
        @link.increment!(:clicks)
        redirect_to @link.original_url, allow_other_host: true
      end
    end

    def toggle_active
      @link = current_user.links.find(params[:id])
      @link.update(active: !@link.active)

      redirect_to links_path, notice: "Link status updated!"
    end

    # 🔐 Unlock with password
    def unlock
      @link = Link.find_by!(short_code: params[:short_code])
  
      if @link.password_digest.present?
        if @link.authenticate(params[:password])
          @link.increment!(:clicks)
          redirect_to @link.original_url, allow_other_host: true
        else
          flash.now[:alert] = "Incorrect password, please try again."
          render :password, status: :unprocessable_entity
        end
      else
        @link.increment!(:clicks)
        redirect_to @link.original_url, allow_other_host: true
      end
    end

    def update_qr
      if @link.update(qr_settings: params[:qr_settings])
          render json: { success: true }
        else
          render json: { success: false }
        end
    end
  
  def destroy
    @link.destroy
    redirect_to links_path, notice: "Link deleted successfully"
  end

  private

  def set_link
    @link = current_user.links.find(params[:id])
  end

  def link_params
    params.require(:link).permit(:original_url, :expires_at, :password, :short_code)
  end
end
  