module Api
  class HeatsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_mark

    def index
      return render_forbidden("Access denied") unless can_view_mark?

      heats = @mark.heats.order(created_at: :desc)
      render json: { heats: heats.map(&:as_json), heats_count: @mark.heats_count }
    end

    def create
      return render_forbidden("Access denied") unless can_record_heat?

      heat = @mark.heats.create!(recorded_by: current_user)
      @mark.reload
      render json: heat.as_json, status: :created
    end

    private

    def set_mark
      @mark = MushafMark.find(params[:mushaf_mark_id])
    rescue ActiveRecord::RecordNotFound
      render_not_found
    end

    def can_view_mark?
      @mark.subject_id == current_user.id ||
        @mark.marker_id == current_user.id ||
        Friendship.accepted_between?(current_user, @mark.subject)
    end

    def can_record_heat?
      @mark.unmarked_at.nil? && (
        @mark.subject_id == current_user.id ||
        Friendship.accepted_between?(current_user, @mark.subject)
      )
    end
  end
end
