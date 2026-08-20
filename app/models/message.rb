class Message < ApplicationRecord
  belongs_to :sender, class_name: "User"
  belongs_to :recipient, class_name: "User"

  validates :body, presence: true, length: { minimum: 1, maximum: 5000 }
  validates :mushaf_id, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validate :sender_not_recipient
  validate :must_be_friends
  validate :page_numbers_are_positive

  before_validation :normalize_body_and_pages

  scope :inbox_for, ->(user) { where(recipient_id: user.id).order(created_at: :desc) }
  scope :unread, -> { where(read_at: nil) }

  def unread?
    read_at.nil?
  end

  def mark_read!
    update!(read_at: Time.current) if read_at.nil?
  end

  def as_json(_options = {})
    {
      id: id,
      sender_id: sender_id,
      recipient_id: recipient_id,
      sender: sender&.as_json,
      recipient: recipient&.as_json,
      body: body,
      page_numbers: page_numbers || [],
      mushaf_id: mushaf_id,
      read_at: read_at,
      created_at: created_at,
      updated_at: updated_at
    }
  end

  private

  def normalize_body_and_pages
    self.body = body.to_s.strip
    self.page_numbers = Array(page_numbers).map(&:to_i).select { |n| n > 0 }.uniq.sort
  end

  def sender_not_recipient
    return if sender_id.blank? || recipient_id.blank?
    errors.add(:recipient, "cannot be yourself") if sender_id == recipient_id
  end

  def must_be_friends
    return if sender_id.blank? || recipient_id.blank?
    return if sender_id == recipient_id

    unless Friendship.accepted_between?(sender, recipient)
      errors.add(:base, "You can only message accepted friends")
    end
  end

  def page_numbers_are_positive
    Array(page_numbers).each do |n|
      unless n.is_a?(Integer) && n > 0
        errors.add(:page_numbers, "must be positive integers")
        break
      end
    end
  end
end
