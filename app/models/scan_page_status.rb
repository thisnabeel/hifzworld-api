# Review status of a scanned mushaf page: marked ready once its word tiles have been checked.
class ScanPageStatus < ApplicationRecord
  validates :mushaf_key, inclusion: { in: ScanPageLayout::MUSHAF_KEYS }
  validates :page, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 1000 }
  validates :page, uniqueness: { scope: :mushaf_key }
  validates :ready, inclusion: { in: [true, false] }

  def as_json(_options = {})
    { page: page, ready: ready, updated_at: updated_at }
  end
end
