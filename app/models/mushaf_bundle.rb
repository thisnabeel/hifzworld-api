class MushafBundle < ApplicationRecord
  belongs_to :owner, class_name: "User"
  has_many :bundle_shares, dependent: :destroy
  has_many :review_sessions, dependent: :destroy
  has_many :session_marks, dependent: :destroy

  validates :title, presence: true
  validates :mushaf_id, presence: true

  def as_json(options = {})
    role = options[:role]
    {
      id: id,
      owner_id: owner_id,
      title: title,
      description: description,
      page_numbers: page_numbers,
      mushaf_id: mushaf_id,
      role: role,
      created_at: created_at,
      updated_at: updated_at
    }
  end
end
