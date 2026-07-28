class DeckInvite < ApplicationRecord
  belongs_to :mushaf_bundle
  belongs_to :created_by, class_name: "User"

  validates :token, presence: true, uniqueness: true

  before_validation :ensure_token, on: :create

  scope :active, -> { where(revoked_at: nil) }

  def self.find_or_create_active!(bundle:, created_by:)
    active.find_by(mushaf_bundle: bundle) || create!(mushaf_bundle: bundle, created_by: created_by)
  end

  def revoked?
    revoked_at.present?
  end

  def as_json(options = {})
    {
      token: token,
      url: options[:url],
      deep_link: "hifzworld://invite/#{token}",
      bundle_title: mushaf_bundle&.title,
      created_at: created_at
    }.compact
  end

  private

  def ensure_token
    self.token ||= SecureRandom.urlsafe_base64(18)
  end
end
