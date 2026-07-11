module Api
  class FeedbackController < ApplicationController
    before_action :authenticate_user!

    def index
      sessions = ReviewSession.where(reciter: current_user, status: "ended")
                              .includes(:mushaf_bundle, :listener, :session_marks)
                              .order(ended_at: :desc)

      render json: sessions.map do |session|
        session.as_json(mark_count: session.session_marks.size).merge(
          marks: session.session_marks.order(page_number: :asc, created_at: :asc).map(&:as_json)
        )
      end
    end
  end
end
