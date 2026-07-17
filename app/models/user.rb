class User < ApplicationRecord
  has_many :owned_bundles, class_name: "MushafBundle", foreign_key: :owner_id, dependent: :destroy
  has_many :outgoing_shares, class_name: "BundleShare", foreign_key: :shared_by_id, dependent: :destroy
  has_many :incoming_shares, class_name: "BundleShare", foreign_key: :shared_with_id, dependent: :destroy
  has_many :reciter_sessions, class_name: "ReviewSession", foreign_key: :reciter_id, dependent: :destroy
  has_many :listener_sessions, class_name: "ReviewSession", foreign_key: :listener_id, dependent: :destroy
  has_many :session_marks, foreign_key: :listener_id, dependent: :destroy
  has_many :app_feedbacks, dependent: :destroy

  validates :apple_sub, presence: true, uniqueness: true
  validates :display_name, presence: true
  validates :handle, uniqueness: true, allow_nil: true

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
end
