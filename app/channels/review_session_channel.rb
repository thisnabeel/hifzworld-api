class ReviewSessionChannel < ApplicationCable::Channel
  def subscribed
    session = ReviewSession.find(params[:session_id])
    reject unless [session.reciter_id, session.listener_id].include?(current_user.id)

    stream_for session
  end

  def self.broadcast_mark_created(mark)
    broadcast_to(mark.review_session, { event: "mark_created", mark: mark.as_json })
  end

  def self.broadcast_mark_deleted(mark)
    broadcast_to(
      mark.review_session,
      { event: "mark_deleted", mark_id: mark.id, word_id: mark.word_id }
    )
  end

  def self.broadcast_session_event(session, event, payload = {})
    broadcast_to(session, { event: event, payload: payload })
  end

  def self.broadcast_state(session)
    broadcast_to(
      session,
      {
        event: "state_changed",
        payload: {
          current_page: session.current_page,
          page_hidden: session.page_hidden
        }
      }
    )
  end
end
