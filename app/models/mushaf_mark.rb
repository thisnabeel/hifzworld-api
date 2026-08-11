class MushafMark < ApplicationRecord
  MARK_TYPES = %w[mistake tajweed pronunciation skipped added hesitation other].freeze

  belongs_to :subject, class_name: "User"
  belongs_to :marker, class_name: "User"

  validates :word_id, :verse_key, :page_number, :mushaf_id, :mark_type, presence: true
  validates :mark_type, inclusion: { in: MARK_TYPES }
  validates :word_id, uniqueness: { scope: %i[subject_id mushaf_id] }

  def as_json(_options = {})
    {
      id: id,
      subject_id: subject_id,
      marker_id: marker_id,
      subject: subject&.as_json,
      marker: marker&.as_json,
      word_id: word_id,
      verse_key: verse_key,
      page_number: page_number,
      line_number: line_number,
      word_position: word_position,
      mushaf_id: mushaf_id,
      mark_type: mark_type,
      note: note,
      created_at: created_at,
      updated_at: updated_at
    }
  end
end
