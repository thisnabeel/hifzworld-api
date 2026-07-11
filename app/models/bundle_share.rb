class BundleShare < ApplicationRecord
  STATUSES = %w[pending accepted].freeze

  belongs_to :mushaf_bundle
  belongs_to :shared_by, class_name: "User"
  belongs_to :shared_with, class_name: "User"

  validates :status, inclusion: { in: STATUSES }

  scope :pending, -> { where(status: "pending") }
  scope :accepted, -> { where(status: "accepted") }

  def as_json(_options = {})
    {
      id: id,
      mushaf_bundle_id: mushaf_bundle_id,
      shared_by_id: shared_by_id,
      shared_with_id: shared_with_id,
      status: status,
      bundle: mushaf_bundle&.as_json(role: "shared"),
      shared_by: shared_by&.as_json,
      created_at: created_at,
      updated_at: updated_at
    }
  end
end
