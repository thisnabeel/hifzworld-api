module Api
  class MushafMarksController < ApplicationController
    before_action :authenticate_user!
    before_action :set_mark, only: %i[destroy]

    def index
      scope = MushafMark.includes(:subject, :marker).order(created_at: :desc)

      if params[:subject_id].present?
        subject = User.find(params[:subject_id])
        return render_forbidden("Access denied") unless can_view_subject_marks?(subject)

        scope = scope.where(subject: subject)
      else
        # Marks where the current user is subject or marker.
        scope = scope.where(subject_id: current_user.id).or(scope.where(marker_id: current_user.id))
      end

      if params[:marker_id].present?
        scope = scope.where(marker_id: params[:marker_id])
      end
      if params[:page].present?
        scope = scope.where(page_number: params[:page].to_i)
      end
      if params[:mushaf_id].present?
        scope = scope.where(mushaf_id: params[:mushaf_id].to_i)
      end
      if params[:from].present?
        scope = scope.where("created_at >= ?", Time.iso8601(params[:from]))
      end
      if params[:to].present?
        scope = scope.where("created_at <= ?", Time.iso8601(params[:to]))
      end

      limit = [[params.fetch(:limit, 200).to_i, 1].max, 500].min
      render json: { marks: scope.limit(limit).map(&:as_json) }
    rescue ArgumentError
      render json: { error: "Invalid date filter" }, status: :unprocessable_entity
    rescue ActiveRecord::RecordNotFound
      render_not_found
    end

    def create
      subject = User.find(params[:subject_id])
      return render_forbidden("You can only mark for yourself or an accepted friend") unless can_mark_for?(subject)

      attrs = mark_params.merge(subject: subject, marker: current_user)
      mark = MushafMark.find_or_initialize_by(
        subject: subject,
        mushaf_id: attrs[:mushaf_id],
        word_id: attrs[:word_id]
      )
      was_new = mark.new_record?
      mark.assign_attributes(attrs)

      if mark.save
        render json: mark.as_json, status: was_new ? :created : :ok
      else
        render_unprocessable(mark)
      end
    rescue ActiveRecord::RecordNotFound
      render_not_found("Subject not found")
    end

    def destroy
      unless @mark.marker_id == current_user.id || @mark.subject_id == current_user.id
        return render_forbidden("Access denied")
      end

      @mark.destroy!
      head :no_content
    end

    private

    def set_mark
      @mark = MushafMark.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render_not_found
    end

    def mark_params
      params.permit(:word_id, :verse_key, :page_number, :line_number, :word_position, :mushaf_id, :mark_type, :note)
    end

    def can_mark_for?(subject)
      subject.id == current_user.id || Friendship.accepted_between?(current_user, subject)
    end

    def can_view_subject_marks?(subject)
      subject.id == current_user.id ||
        Friendship.accepted_between?(current_user, subject) ||
        MushafMark.exists?(subject: subject, marker: current_user)
    end
  end
end
