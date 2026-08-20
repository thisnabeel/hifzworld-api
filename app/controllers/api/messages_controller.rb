module Api
  class MessagesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_message, only: %i[show read]

    def index
      scope = Message.inbox_for(current_user).includes(:sender, :recipient)
      if params[:with].present?
        scope = scope.where(sender_id: params[:with])
      end

      render json: {
        messages: scope.limit(200).map(&:as_json)
      }
    end

    def show
      render json: @message.as_json
    end

    def create
      message = Message.new(
        sender: current_user,
        recipient_id: params[:recipient_id],
        body: params[:body],
        page_numbers: params[:page_numbers],
        mushaf_id: params[:mushaf_id]
      )

      if message.save
        render json: message.as_json, status: :created
      else
        render_unprocessable(message)
      end
    end

    def read
      return render_forbidden("Only the recipient can mark a message read") unless @message.recipient_id == current_user.id

      @message.mark_read!
      render json: @message.as_json
    end

    def unread_count
      count = current_user.received_messages.unread.count
      render json: { count: count }
    end

    private

    def set_message
      @message = Message.includes(:sender, :recipient).find(params[:id])
      unless [@message.sender_id, @message.recipient_id].include?(current_user.id)
        return render_forbidden("Access denied")
      end
    rescue ActiveRecord::RecordNotFound
      render_not_found
    end
  end
end
