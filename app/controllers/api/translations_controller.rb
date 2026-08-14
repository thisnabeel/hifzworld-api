module Api
  class TranslationsController < ApplicationController
    MAX_KEYS = 80

    def index
      keys = parse_keys(params[:keys])
      if keys.empty?
        return render json: { error: "keys is required" }, status: :unprocessable_entity
      end
      if keys.size > MAX_KEYS
        return render json: { error: "Too many keys (max #{MAX_KEYS})" }, status: :unprocessable_entity
      end

      set = TranslationSet.resolve(language: params[:language], translator: params[:translator])
      unless set
        return render json: { error: "Translation set not found" }, status: :not_found
      end

      rows = set.verse_translations.where(verse_key: keys).pluck(:verse_key, :text)
      render json: {
        translation_set: set.as_json,
        translations: rows.to_h
      }
    end

    private

    def parse_keys(raw)
      raw.to_s.split(",").map(&:strip).filter_map do |key|
        next unless key.match?(/\A\d+:\d+\z/)
        key
      end.uniq
    end
  end
end
