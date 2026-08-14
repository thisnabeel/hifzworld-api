class VerseTranslation < ApplicationRecord
  belongs_to :translation_set

  validates :verse_key, presence: true
  validates :text, presence: true
  validates :verse_key, uniqueness: { scope: :translation_set_id }
end
