class SessionMark < ApplicationRecord
  # Keep in sync with iOS MistakeMarkType (+ legacy values for older marks).
  MARK_TYPES = %w[mistake tajweed pronunciation skipped added hesitation other].freeze

  belongs_to :review_session
  belongs_to :mushaf_bundle
  belongs_to :listener, class_name: "User"

  before_validation :normalize_mark_type

  validates :word_id, :verse_key, :page_number, :mushaf_id, :mark_type, presence: true
  validates :mark_type, inclusion: { in: MARK_TYPES }

  def as_json(_options = {})
    {
      id: id,
      review_session_id: review_session_id,
      mushaf_bundle_id: mushaf_bundle_id,
      listener_id: listener_id,
      listener_display_name: listener.display_name,
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

  private

  def normalize_mark_type
    self.mark_type = mark_type.to_s.strip.downcase.presence
    return if mark_type.blank? || MARK_TYPES.include?(mark_type)

    self.mark_type = "mistake"
  end
end
