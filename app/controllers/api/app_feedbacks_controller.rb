module Api
  class AppFeedbacksController < ApplicationController
    before_action :authenticate_user!

    def create
      feedback = current_user.app_feedbacks.new(feedback_params)
      feedback.email = feedback.email.presence || current_user.email

      if feedback.save
        render json: feedback.as_json, status: :created
      else
        render_unprocessable(feedback)
      end
    end

    private

    def feedback_params
      params.permit(:message, :email, :category)
    end
  end
end
