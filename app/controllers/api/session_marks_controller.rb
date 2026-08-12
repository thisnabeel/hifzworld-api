module Api
  class SessionMarksController < ApplicationController
    before_action :authenticate_user!
    before_action :set_mark, only: %i[update destroy]

    def update
      session = @mark.review_session

      return render_forbidden("Only the listener can undo marks") unless @mark.listener_id == current_user.id
      return render json: { error: "Session is not active" }, status: :unprocessable_entity unless session.active?

      attrs = {}
      if params.key?(:unmarked_at)
        attrs[:unmarked_at] = parse_optional_time(params[:unmarked_at])
      end
      attrs[:note] = params[:note] if params.key?(:note)
      attrs[:mark_type] = params[:mark_type] if params.key?(:mark_type)

      if @mark.update(attrs)
        if @mark.unmarked?
          ReviewSessionChannel.broadcast_mark_deleted(@mark)
        else
          ReviewSessionChannel.broadcast_mark_created(@mark)
        end
        render json: @mark.as_json
      else
        render_unprocessable(@mark)
      end
    rescue ArgumentError
      render json: { error: "Invalid unmarked_at" }, status: :unprocessable_entity
    end

    def destroy
      session = @mark.review_session

      return render_forbidden("Only the listener can undo marks") unless @mark.listener_id == current_user.id
      return render json: { error: "Session is not active" }, status: :unprocessable_entity unless session.active?

      ReviewSessionChannel.broadcast_mark_deleted(@mark)
      @mark.destroy!
      head :no_content
    end

    private

    def parse_optional_time(value)
      return nil if value.blank?

      Time.iso8601(value.to_s)
    rescue ArgumentError
      Time.zone.parse(value.to_s) || raise(ArgumentError, "Invalid time")
    end

    def set_mark
      @mark = SessionMark.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render_not_found
    end
  end
end
