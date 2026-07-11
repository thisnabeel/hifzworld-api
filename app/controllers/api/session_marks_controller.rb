module Api
  class SessionMarksController < ApplicationController
    before_action :authenticate_user!

    def destroy
      mark = SessionMark.find(params[:id])
      session = mark.review_session

      return render_forbidden("Only the listener can undo marks") unless mark.listener_id == current_user.id
      return render json: { error: "Session is not active" }, status: :unprocessable_entity unless session.active?

      mark.destroy!
      ReviewSessionChannel.broadcast_mark_deleted(mark)
      head :no_content
    rescue ActiveRecord::RecordNotFound
      render_not_found
    end
  end
end
