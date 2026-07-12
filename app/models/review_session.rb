class ReviewSession < ApplicationRecord
  STATUSES = %w[waiting active ended].freeze

  belongs_to :mushaf_bundle
  belongs_to :reciter, class_name: "User"
  belongs_to :listener, class_name: "User"
  has_many :session_marks, dependent: :destroy

  validates :status, inclusion: { in: STATUSES }

  def active?
    status == "active"
  end

  def ended?
    status == "ended"
  end

  def as_json(options = {})
    payload = {
      id: id,
      mushaf_bundle_id: mushaf_bundle_id,
      bundle_title: mushaf_bundle.title,
      reciter_id: reciter_id,
      listener_id: listener_id,
      reciter: reciter.as_json,
      listener: listener.as_json,
      status: status,
      current_page: current_page,
      page_hidden: page_hidden,
      video_room_id: video_room_id,
      started_at: started_at,
      ended_at: ended_at,
      created_at: created_at,
      updated_at: updated_at
    }
    payload[:mark_count] = options[:mark_count] if options.key?(:mark_count)
    payload
  end
end
