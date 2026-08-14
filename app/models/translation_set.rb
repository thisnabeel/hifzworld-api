class TranslationSet < ApplicationRecord
  has_many :verse_translations, dependent: :destroy

  validates :language, presence: true
  validates :translator, presence: true
  validates :display_name, presence: true
  validates :language, uniqueness: { scope: :translator }

  def self.default_set
    find_by(is_default: true) || find_by(language: "en", translator: "natadarrab")
  end

  def self.resolve(language: nil, translator: nil)
    if language.present? && translator.present?
      find_by(language: language, translator: translator)
    elsif language.present?
      where(language: language).order(is_default: :desc).first
    elsif translator.present?
      where(translator: translator).order(is_default: :desc).first
    else
      default_set
    end
  end

  def as_json(_options = {})
    {
      language: language,
      translator: translator,
      display_name: display_name
    }
  end
end
