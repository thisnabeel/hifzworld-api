class Heat < ApplicationRecord
  belongs_to :mushaf_mark, counter_cache: true
  belongs_to :recorded_by, class_name: "User"

  def as_json(_options = {})
    {
      id: id,
      mushaf_mark_id: mushaf_mark_id,
      recorded_by_id: recorded_by_id,
      created_at: created_at,
      heats_count: mushaf_mark&.heats_count
    }
  end
end
