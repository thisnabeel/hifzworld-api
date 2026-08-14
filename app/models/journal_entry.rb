class JournalEntry < ApplicationRecord
  belongs_to :user

  validates :entry_date, presence: true
  validates :time_zone, presence: true
  validates :body, length: { maximum: 20_000 }
  validates :entry_date, uniqueness: { scope: :user_id }

  def as_json(_options = {})
    {
      id: id,
      user_id: user_id,
      entry_date: entry_date&.iso8601,
      body: body,
      time_zone: time_zone,
      created_at: created_at,
      updated_at: updated_at
    }
  end
end
