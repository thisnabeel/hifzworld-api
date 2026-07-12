class MushafBundle < ApplicationRecord
  belongs_to :owner, class_name: "User"
  has_many :bundle_shares, dependent: :destroy
  has_many :review_sessions, dependent: :destroy
  has_many :session_marks, dependent: :destroy

  validates :title, presence: true
  validates :mushaf_id, presence: true

  def as_json(options = {})
    role = options[:role]
    payload = {
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

    if role == "owner"
      accepted = bundle_shares.find { |share| share.status == "accepted" } ||
                 bundle_shares.accepted.order(updated_at: :desc).first
      if accepted
        payload[:collaborator_user_id] = accepted.shared_with_id
        payload[:collaborator_name] = accepted.shared_with&.display_name
        payload[:share_status] = accepted.status
      else
        pending = bundle_shares.pending.order(updated_at: :desc).first
        if pending
          payload[:collaborator_user_id] = pending.shared_with_id
          payload[:collaborator_name] = pending.shared_with&.display_name
          payload[:share_status] = pending.status
        end
      end
    end

    payload
  end
end
