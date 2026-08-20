class User < ApplicationRecord
  has_many :owned_bundles, class_name: "MushafBundle", foreign_key: :owner_id, dependent: :destroy
  has_many :outgoing_shares, class_name: "BundleShare", foreign_key: :shared_by_id, dependent: :destroy
  has_many :incoming_shares, class_name: "BundleShare", foreign_key: :shared_with_id, dependent: :destroy
  has_many :reciter_sessions, class_name: "ReviewSession", foreign_key: :reciter_id, dependent: :destroy
  has_many :listener_sessions, class_name: "ReviewSession", foreign_key: :listener_id, dependent: :destroy
  has_many :session_marks, foreign_key: :listener_id, dependent: :destroy
  has_many :app_feedbacks, dependent: :destroy
  has_many :sent_friend_requests, class_name: "Friendship", foreign_key: :requester_id, dependent: :destroy
  has_many :received_friend_requests, class_name: "Friendship", foreign_key: :recipient_id, dependent: :destroy
  has_many :subject_mushaf_marks, class_name: "MushafMark", foreign_key: :subject_id, dependent: :destroy
  has_many :marker_mushaf_marks, class_name: "MushafMark", foreign_key: :marker_id, dependent: :destroy
  has_many :journal_entries, dependent: :destroy
  has_many :sent_messages, class_name: "Message", foreign_key: :sender_id, dependent: :destroy
  has_many :received_messages, class_name: "Message", foreign_key: :recipient_id, dependent: :destroy

  validates :apple_sub, presence: true, uniqueness: true
  validates :display_name, presence: true
  validates :handle,
            uniqueness: true,
            allow_nil: true,
            format: { with: /\A[a-z0-9_]{3,30}\z/, message: "must be 3–30 characters: lowercase letters, numbers, underscore" }

  before_validation :normalize_handle
  before_validation :assign_default_handle, on: :create

  def ensure_handle!
    return if handle.present?

    base = HandleService.from_email(email) || "user"
    update!(handle: HandleService.unique_for(base, excluding_user_id: id))
  end

  def as_json(_options = {})
    {
      id: id,
      email: email,
      handle: handle,
      display_name: display_name,
      avatar_url: avatar_url,
      created_at: created_at,
      updated_at: updated_at
    }
  end

  private

  def normalize_handle
    return if handle.nil?

    self.handle = handle.to_s.delete_prefix("@").downcase.strip
    self.handle = nil if handle.blank?
  end

  def assign_default_handle
    return if handle.present?
    return if email.blank?

    base = HandleService.from_email(email) || "user"
    self.handle = HandleService.unique_for(base)
  end
end
