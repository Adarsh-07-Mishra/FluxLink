class Link < ApplicationRecord
  belongs_to :user, optional: true
  has_secure_password validations: false

  # Virtual attribute for QR generation checkbox
  attr_accessor :generate_qr
  
    before_validation :set_and_normalize_short_code, on: :create
    before_validation :normalize_original_url
    before_create :set_default_active

  
    validates :original_url, presence: true
    validate  :validate_original_url_format
  
    validates :short_code,
              presence: true,
              uniqueness: { case_sensitive: false },
              format: { with: /\A[a-z0-9]+\z/, message: "only lowercase letters and numbers allowed" }
  
    # Check if link is expired
    def expired?
      expires_at.present? && Time.current > expires_at
    end
  
    # Generate QR code (SVG)
    def qr_code(url)
      RQRCode::QRCode.new(url)
    end
  
    # Optional: store generated QR code as SVG string
    def generate_qr_code(url)
      self.qr_code_data = RQRCode::QRCode.new(url).as_svg(module_size: 5)
      save
    end

     def active?
      active == true
    end

    def inactive?
      !active?
    end
  
    private
  
    # Normalize short code
    def set_and_normalize_short_code
      if short_code.present?
        self.short_code = short_code.gsub(/[^a-zA-Z0-9]/, "").downcase
      else
        generate_random_code
      end
    end
  
    def generate_random_code
      loop do
        self.short_code = SecureRandom.alphanumeric(6).downcase
        break unless Link.exists?(short_code: short_code)
      end
    end
  
    # Remove extra spaces from original URL
    def normalize_original_url
      self.original_url = original_url.strip if original_url.present?
    end
  
    # Validate original URL format
    def validate_original_url_format
      return if original_url.blank?
  
      uri = URI.parse(original_url) rescue nil
      unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
        errors.add(:original_url, "must be a valid URL starting with http:// or https://")
      end
    end

    def set_default_active
      self.active = true if active.nil?
    end

   
  end
  