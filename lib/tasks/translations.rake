namespace :translations do
  AYAH_COUNTS = [
    7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52, 99, 128, 111, 110, 98, 135,
    112, 78, 118, 64, 77, 227, 93, 88, 69, 60, 34, 30, 73, 54, 45, 83, 182, 88, 75, 85,
    54, 53, 89, 59, 37, 35, 38, 29, 18, 45, 60, 49, 62, 55, 78, 96, 29, 22, 24, 13,
    14, 11, 11, 18, 12, 12, 30, 52, 52, 44, 28, 28, 20, 56, 40, 31, 50, 40, 46, 42,
    29, 19, 36, 25, 22, 17, 19, 26, 30, 20, 15, 21, 11, 8, 8, 19, 5, 8, 8, 11,
    11, 8, 3, 9, 5, 4, 7, 3, 6, 3, 5, 4, 5, 6
  ].freeze

  SOURCE_URL = "https://natadarrab-api-7-4298623a0ae3.herokuapp.com/revelations/search.json".freeze

  desc "Ensure English (default) and Urdu natadarrab translation sets exist"
  task ensure_sets: :environment do
    ensure_sets!
  end

  desc "Import natadarrab translations from Heroku (resumable). DELAY=0.2"
  task import_revelation: :environment do
    require "net/http"
    require "json"
    require "uri"

    english, urdu = ensure_sets!
    delay = (ENV["DELAY"] || "0.2").to_f
    existing = english.verse_translations.pluck(:verse_key).to_set
    missing = all_verse_keys.reject { |key| existing.include?(key) }
    puts "Missing #{missing.size} of #{all_verse_keys.size} English keys"

    uri = URI(SOURCE_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 30
    http.open_timeout = 15

    imported = 0
    missing.each_with_index do |key, index|
      body = { verses: key }.to_json
      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request.body = body

      response = http.request(request)
      unless response.is_a?(Net::HTTPSuccess)
        warn "HTTP #{response.code} for #{key}; retrying once"
        sleep 1
        response = http.request(request)
      end
      unless response.is_a?(Net::HTTPSuccess)
        warn "Skipping #{key}: HTTP #{response.code}"
        next
      end

      payload = JSON.parse(response.body)
      row = payload.is_a?(Array) ? payload.first : payload
      translation = row.is_a?(Hash) ? row["translation"] : nil
      en = translation.is_a?(Hash) ? translation["english"].to_s.strip : ""
      ur = translation.is_a?(Hash) ? translation["urdu"].to_s.strip : ""

      if en.present?
        VerseTranslation.upsert(
          {
            translation_set_id: english.id,
            verse_key: key,
            text: en,
            created_at: Time.current,
            updated_at: Time.current
          },
          unique_by: [:translation_set_id, :verse_key]
        )
      end
      if ur.present?
        VerseTranslation.upsert(
          {
            translation_set_id: urdu.id,
            verse_key: key,
            text: ur,
            created_at: Time.current,
            updated_at: Time.current
          },
          unique_by: [:translation_set_id, :verse_key]
        )
      end

      imported += 1
      if ((index + 1) % 50).zero?
        puts "Imported #{imported}/#{missing.size} (#{key})"
      end
      sleep delay if delay.positive?
    end

    print_status(english, urdu)
  end

  desc "Import from db/data/natadarrab_translations.json"
  task import_json: :environment do
    path = Rails.root.join("db/data/natadarrab_translations.json")
    abort "Missing #{path}" unless File.exist?(path)

    english, urdu = ensure_sets!
    payload = JSON.parse(File.read(path))
    now = Time.current
    en_rows = []
    ur_rows = []
    payload.each do |key, langs|
      next unless key.match?(/\A\d+:\d+\z/)
      en = langs["english"].to_s.strip
      ur = langs["urdu"].to_s.strip
      if en.present?
        en_rows << {
          translation_set_id: english.id,
          verse_key: key,
          text: en,
          created_at: now,
          updated_at: now
        }
      end
      if ur.present?
        ur_rows << {
          translation_set_id: urdu.id,
          verse_key: key,
          text: ur,
          created_at: now,
          updated_at: now
        }
      end
    end

    en_rows.each_slice(500) do |slice|
      VerseTranslation.upsert_all(
        slice.map { |row| row.merge(id: SecureRandom.uuid) },
        unique_by: [:translation_set_id, :verse_key]
      )
    end
    ur_rows.each_slice(500) do |slice|
      VerseTranslation.upsert_all(
        slice.map { |row| row.merge(id: SecureRandom.uuid) },
        unique_by: [:translation_set_id, :verse_key]
      )
    end
    print_status(english, urdu)
  end

  desc "Import JSON only when English coverage is incomplete"
  task import_json_if_needed: :environment do
    path = Rails.root.join("db/data/natadarrab_translations.json")
    next unless File.exist?(path)

    english, _urdu = ensure_sets!
    expected = all_verse_keys.size
    next if english.verse_translations.count >= expected

    Rake::Task["translations:import_json"].invoke
  end
    english, urdu = ensure_sets!
    print_status(english, urdu)
  end

  def ensure_sets!
    english = TranslationSet.find_or_create_by!(language: "en", translator: "natadarrab") do |set|
      set.display_name = "English (natadarrab)"
      set.is_default = true
    end
    unless english.is_default?
      english.update!(is_default: true)
    end
    urdu = TranslationSet.find_or_create_by!(language: "ur", translator: "natadarrab") do |set|
      set.display_name = "Urdu (natadarrab)"
      set.is_default = false
    end
    [english, urdu]
  end

  def all_verse_keys
    AYAH_COUNTS.flat_map.with_index(1) do |count, surah|
      (1..count).map { |ayah| "#{surah}:#{ayah}" }
    end
  end

  def print_status(english, urdu)
    expected = all_verse_keys.size
    en_count = english.verse_translations.count
    ur_count = urdu.verse_translations.count
    puts "English #{en_count}/#{expected}"
    puts "Urdu #{ur_count}/#{expected}"
    puts "COMPLETE" if en_count >= expected && ur_count >= expected
  end
end
