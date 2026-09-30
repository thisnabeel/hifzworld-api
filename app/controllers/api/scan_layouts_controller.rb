module Api
  # Word-tile layouts for scanned mushaf pages. Reads are public (coordinates and word IDs only,
  # never the page images); saving needs the editor token (SCAN_EDITOR_TOKEN).
  class ScanLayoutsController < ApplicationController
    before_action :authenticate_editor!, only: %i[update update_status]
    before_action :validate_mushaf_key

    # GET /api/scan_layouts/:mushaf_key?pages=3,12,402
    def index
      scope = ScanPageLayout.where(mushaf_key: params[:mushaf_key])
      if params[:pages].present?
        pages = params[:pages].to_s.split(",").map(&:to_i).select(&:positive?).first(1000)
        scope = scope.where(page: pages)
      end
      render json: { layouts: scope.order(:page).map(&:as_json) }
    end

    # GET /api/scan_layouts/:mushaf_key/statuses
    def statuses
      render json: { statuses: ScanPageStatus.where(mushaf_key: params[:mushaf_key]).order(:page).map(&:as_json) }
    end

    # PUT /api/scan_layouts/:mushaf_key/:page/status  { ready: true|false }
    def update_status
      status = ScanPageStatus.find_or_initialize_by(mushaf_key: params[:mushaf_key], page: params[:page].to_i)
      status.ready = ActiveModel::Type::Boolean.new.cast(params[:ready])
      if status.save
        render json: status.as_json
      else
        render_unprocessable(status)
      end
    end

    # GET /api/scan_layouts/:mushaf_key/:page
    def show
      layout = ScanPageLayout.find_by(mushaf_key: params[:mushaf_key], page: params[:page].to_i)
      return render_not_found("No saved layout for this page") unless layout

      render json: layout.as_json
    end

    # PUT /api/scan_layouts/:mushaf_key/:page
    #   { tiles: [{ ids: [..], x:, y:, width:, height: }, { ids: [], surah: 103, ... }, ...] }
    def update
      layout = ScanPageLayout.find_or_initialize_by(mushaf_key: params[:mushaf_key], page: params[:page].to_i)
      layout.tiles = tiles_param
      if layout.save
        render json: layout.as_json
      else
        render_unprocessable(layout)
      end
    end

    private

    def tiles_param
      raw = params.require(:tiles)
      raw = raw.map { |t| t.respond_to?(:to_unsafe_h) ? t.to_unsafe_h : t } if raw.is_a?(Array)
      Array(raw).map do |t|
        tile = {
          "ids" => Array(t["ids"]).map { |id| Integer(id, exception: false) },
          "x" => t["x"].to_f, "y" => t["y"].to_f,
          "width" => t["width"].to_f, "height" => t["height"].to_f
        }
        tile["surah"] = Integer(t["surah"], exception: false) if t["surah"].present?
        tile
      end
    end

    def validate_mushaf_key
      return if ScanPageLayout::MUSHAF_KEYS.include?(params[:mushaf_key])

      render_not_found("Unknown mushaf")
    end

    def authenticate_editor!
      expected = Figaro.env.scan_editor_token.to_s
      given = request.headers["X-Editor-Token"].to_s
      return if expected.present? && given.present? && ActiveSupport::SecurityUtils.secure_compare(given, expected)

      render_unauthorized("Editor token required")
    end
  end
end
