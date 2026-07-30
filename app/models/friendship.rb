class Friendship < ApplicationRecord
  STATUSES = %w[pending accepted].freeze

  belongs_to :requester, class_name: "User"
  belongs_to :recipient, class_name: "User"

  validates :status, inclusion: { in: STATUSES }
  validate :cannot_friend_self
  validate :no_duplicate_pair

  scope :pending, -> { where(status: "pending") }
  scope :accepted, -> { where(status: "accepted") }

  def self.between(user_a, user_b)
    where(
      "(requester_id = :a AND recipient_id = :b) OR (requester_id = :b AND recipient_id = :a)",
      a: user_a.id,
      b: user_b.id
    ).first
  end

  def self.accepted_between?(user_a, user_b)
    accepted.merge(
      where(
        "(requester_id = :a AND recipient_id = :b) OR (requester_id = :b AND recipient_id = :a)",
        a: user_a.id,
        b: user_b.id
      )
    ).exists?
  end

  def self.friends_of(user)
    accepted.where(requester_id: user.id).or(accepted.where(recipient_id: user.id))
  end

  def other_user(for_user)
    requester_id == for_user.id ? recipient : requester
  end

  def as_json_for(viewer)
    {
      id: id,
      status: status,
      requester_id: requester_id,
      recipient_id: recipient_id,
      user: other_user(viewer)&.as_json,
      created_at: created_at,
      updated_at: updated_at
    }
  end

  private

  def cannot_friend_self
    errors.add(:recipient, "cannot be yourself") if requester_id.present? && requester_id == recipient_id
  end

  def no_duplicate_pair
    return if requester_id.blank? || recipient_id.blank?

    existing = Friendship.where(
      "(requester_id = :a AND recipient_id = :b) OR (requester_id = :b AND recipient_id = :a)",
      a: requester_id,
      b: recipient_id
    )
    existing = existing.where.not(id: id) if id.present?
    return unless existing.exists?

    errors.add(:base, "Friendship already exists")
  end
end
