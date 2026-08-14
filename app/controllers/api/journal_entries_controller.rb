module Api
  class JournalEntriesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_entry, only: :update

    def index
      scope = current_user.journal_entries.order(entry_date: :desc)
      if params[:from].present?
        scope = scope.where("entry_date >= ?", Date.iso8601(params[:from]))
      end
      if params[:to].present?
        scope = scope.where("entry_date <= ?", Date.iso8601(params[:to]))
      end

      render json: {
        journal_entries: scope.limit(400).map(&:as_json),
        today: today_in_zone.iso8601
      }
    rescue ArgumentError
      render json: { error: "Invalid date filter" }, status: :unprocessable_entity
    end

    def create
      today = today_in_zone
      entry = current_user.journal_entries.find_or_initialize_by(entry_date: today)
      was_new = entry.new_record?
      entry.body = params[:body].to_s
      entry.time_zone = zone_name

      if entry.save
        render json: entry.as_json, status: was_new ? :created : :ok
      else
        render_unprocessable(entry)
      end
    rescue ArgumentError
      render json: { error: "Invalid time zone" }, status: :unprocessable_entity
    end

    def update
      unless @entry.entry_date == today_in_zone
        return render_forbidden("You can only edit today's journal")
      end

      @entry.body = params[:body].to_s if params.key?(:body)
      @entry.time_zone = zone_name

      if @entry.save
        render json: @entry.as_json
      else
        render_unprocessable(@entry)
      end
    rescue ArgumentError
      render json: { error: "Invalid time zone" }, status: :unprocessable_entity
    end

    private

    def set_entry
      @entry = current_user.journal_entries.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render_not_found
    end

    def zone_name
      name = params[:time_zone].to_s.presence || Time.zone&.name || "UTC"
      zone = Time.find_zone(name)
      raise ArgumentError, "Invalid time zone" if zone.nil?

      zone.tzinfo&.name || name
    end

    def today_in_zone
      zone = Time.find_zone(zone_name) || Time.zone
      Time.use_zone(zone) { Date.current }
    rescue ArgumentError
      Date.current
    end
  end
end
