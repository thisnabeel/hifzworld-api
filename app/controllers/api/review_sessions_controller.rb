module Api
  class ReviewSessionsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_session, only: %i[show join end_session marks create_mark update_state]

    def create
      bundle = MushafBundle.find(params[:mushaf_bundle_id])
      listener = User.find(params[:listener_id])

      return render_forbidden("Only bundle owner can start a session") unless bundle.owner_id == current_user.id
      return render_forbidden("Listener must have accepted the bundle share") unless share_accepted?(bundle, listener)

      start_page = bundle.page_numbers.min
      session = ReviewSession.create!(
        mushaf_bundle: bundle,
        reciter: current_user,
        listener: listener,
        status: "waiting",
        current_page: start_page,
        page_hidden: false,
        video_room_id: "review-#{SecureRandom.uuid}"
      )

      render json: session_payload(session), status: :created
    rescue ActiveRecord::RecordNotFound
      render_not_found
    rescue ActiveRecord::RecordInvalid => e
      render json: { error: e.record.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end

    def show
      return render_forbidden("Access denied") unless participant?(@session)

      render json: session_payload(@session)
    end

    def join
      return render_forbidden("Only the listener can join") unless @session.listener_id == current_user.id
      return render json: { error: "Session already ended" }, status: :unprocessable_entity if @session.ended?

      attrs = { status: "active", started_at: @session.started_at || Time.current }
      attrs[:current_page] ||= @session.mushaf_bundle.page_numbers.min if @session.current_page.blank?
      @session.update!(attrs)
      ReviewSessionChannel.broadcast_session_event(@session, "participant_joined", { user_id: current_user.id })
      ReviewSessionChannel.broadcast_state(@session)

      render json: session_payload(@session)
    end

    def end_session
      return render_forbidden("Only participants can end the session") unless participant?(@session)

      @session.update!(status: "ended", ended_at: Time.current)
      ReviewSessionChannel.broadcast_session_event(@session, "session_ended", { session_id: @session.id })

      render json: session_payload(@session)
    end

    def update_state
      return render_forbidden("Only the listener can drive the session") unless @session.listener_id == current_user.id
      return render json: { error: "Session is not active" }, status: :unprocessable_entity unless @session.active? || @session.status == "waiting"

      attrs = {}
      attrs[:current_page] = params[:current_page].to_i if params.key?(:current_page)
      attrs[:page_hidden] = ActiveModel::Type::Boolean.new.cast(params[:page_hidden]) if params.key?(:page_hidden)

      return render json: { error: "Nothing to update" }, status: :unprocessable_entity if attrs.empty?

      @session.update!(attrs)
      ReviewSessionChannel.broadcast_state(@session)
      render json: session_payload(@session)
    end

    def marks
      return render_forbidden("Access denied") unless participant?(@session)

      render json: @session.session_marks.order(created_at: :asc).map(&:as_json)
    end

    def create_mark
      return render_forbidden("Only the listener can mark mistakes") unless @session.listener_id == current_user.id
      return render json: { error: "Session is not active" }, status: :unprocessable_entity unless @session.active?

      mark = @session.session_marks.new(mark_params)
      mark.mushaf_bundle = @session.mushaf_bundle
      mark.listener = current_user
      # Default mark type to other; blackout presentation is client-side for reciter
      mark.mark_type = mark.mark_type.presence || "other"

      if mark.save
        if @session.current_page != mark.page_number
          @session.update!(current_page: mark.page_number)
          ReviewSessionChannel.broadcast_state(@session)
        end
        ReviewSessionChannel.broadcast_mark_created(mark)
        render json: mark.as_json, status: :created
      else
        render_unprocessable(mark)
      end
    end

    def pending
      bundle = MushafBundle.find(params[:mushaf_bundle_id])
      session = ReviewSession.where(
        mushaf_bundle: bundle,
        listener: current_user,
        status: %w[waiting active]
      ).order(created_at: :desc).first

      return render_not_found("No pending session") unless session

      render json: session_payload(session)
    rescue ActiveRecord::RecordNotFound
      render_not_found
    end

    private

    def set_session
      @session = ReviewSession.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render_not_found
    end

    def mark_params
      params.permit(:word_id, :verse_key, :page_number, :mushaf_id, :mark_type, :note)
    end

    def participant?(session)
      [session.reciter_id, session.listener_id].include?(current_user.id)
    end

    def share_accepted?(bundle, listener)
      BundleShare.accepted.exists?(mushaf_bundle: bundle, shared_with: listener)
    end

    def session_payload(session)
      session.as_json
    end
  end
end
