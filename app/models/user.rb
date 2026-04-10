class User < ApplicationRecord
  attr_accessor :agree_terms

  has_secure_password

  has_many :links, dependent: :destroy
  has_many :wifi_networks, dependent: :destroy

  before_validation :normalize_email

  validates :email,
            presence: true,
            uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP }

  validates :agree_terms, acceptance: { message: "must be accepted" }, on: :create

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end
end
