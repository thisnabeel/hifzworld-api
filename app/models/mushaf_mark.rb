class MushafMark < ApplicationRecord
  # Keep in sync with iOS MistakeMarkType (+ legacy values for older marks).
  MARK_TYPES = %w[mistake tajweed pronunciation skipped added hesitation other].freeze

  belongs_to :subject, class_name: "User"
  belongs_to :marker, class_name: "User"

  before_validation :normalize_mark_type
  before_create :ensure_marked_at

  validates :word_id, :verse_key, :page_number, :mushaf_id, :mark_type, presence: true
  validates :mark_type, inclusion: { in: MARK_TYPES }
  validates :word_id, uniqueness: { scope: %i[subject_id mushaf_id] }

  scope :active, -> { where(unmarked_at: nil) }

  def unmarked?
    unmarked_at.present?
  end

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
      updated_at: updated_at,
      marked_at: marked_at,
      unmarked_at: unmarked_at
    }
  end

  private

  def ensure_marked_at
    self.marked_at ||= Time.current
  end

  def normalize_mark_type
    self.mark_type = mark_type.to_s.strip.downcase.presence
    # Older clients used broader labels; map unknowns to mistake so marking never hard-fails.
    return if mark_type.blank? || MARK_TYPES.include?(mark_type)

    self.mark_type = "mistake"
  end
end
