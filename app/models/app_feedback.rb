class AppFeedback < ApplicationRecord
  CATEGORIES = %w[bug idea other].freeze

  belongs_to :user

  validates :message, presence: true, length: { minimum: 3, maximum: 5000 }
  validates :category, inclusion: { in: CATEGORIES }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  def as_json(_options = {})
    {
      id: id,
      message: message,
      email: email,
      category: category,
      created_at: created_at
    }
  end
end
