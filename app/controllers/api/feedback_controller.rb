module Api
  class FeedbackController < ApplicationController
    before_action :authenticate_user!

    def index
      sessions = ReviewSession.where(reciter: current_user, status: "ended")
                              .includes(:mushaf_bundle, :listener, :session_marks)
                              .order(ended_at: :desc)

      render json: sessions.map do |session|
        marks = session.session_marks.active.order(page_number: :asc, created_at: :asc)
        session.as_json(mark_count: marks.size).merge(
          marks: marks.map(&:as_json)
        )
      end
    end
  end
end
