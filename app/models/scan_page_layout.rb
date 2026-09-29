# Hand-corrected word tiles for a scanned mushaf page (e.g. the Taj 13-line scan).
# Each tile maps a region of the page image (0…1 coordinates) to app word IDs, or to a surah number
# for a surah header box.
class ScanPageLayout < ApplicationRecord
  MUSHAF_KEYS = %w[taj13].freeze
  MAX_TILES = 400

  validates :mushaf_key, inclusion: { in: MUSHAF_KEYS }
  validates :page, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 1000 }
  validates :page, uniqueness: { scope: :mushaf_key }
  validate :tiles_shape

  def as_json(_options = {})
    {
      mushaf_key: mushaf_key,
      page: page,
      tiles: tiles,
      updated_at: updated_at
    }
  end

  private

  def tiles_shape
    unless tiles.is_a?(Array) && tiles.size.between?(1, MAX_TILES)
      errors.add(:tiles, "must be a list of 1–#{MAX_TILES} tiles")
      return
    end

    tiles.each_with_index do |tile, index|
      bound = tile.is_a?(Hash) && (valid_ids?(tile["ids"]) || surah_header?(tile))
      unless bound && %w[x y width height].all? { |k| unit?(tile[k]) }
        errors.add(:tiles, "tile #{index} needs word ids or a surah number, and x/y/width/height between 0 and 1")
        return
      end
    end
  end

  def valid_ids?(ids)
    ids.is_a?(Array) && ids.any? && ids.all? { |id| id.is_a?(Integer) && id.positive? }
  end

  # A surah header box (title + bismillah) is bound to its surah instead of words.
  def surah_header?(tile)
    tile["surah"].is_a?(Integer) && tile["surah"].between?(1, 114) && Array(tile["ids"]).empty?
  end

  def unit?(value)
    value.is_a?(Numeric) && value >= 0 && value <= 1
  end
end
