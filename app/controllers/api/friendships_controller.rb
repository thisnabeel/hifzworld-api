module Api
  class FriendshipsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_friendship, only: %i[accept destroy]

    def index
      friends = Friendship.friends_of(current_user).includes(:requester, :recipient)
      incoming = current_user.received_friend_requests.pending.includes(:requester, :recipient)
      outgoing = current_user.sent_friend_requests.pending.includes(:requester, :recipient)

      render json: {
        friends: friends.map { |f| f.as_json_for(current_user) },
        pending_incoming: incoming.map { |f| f.as_json_for(current_user) },
        pending_outgoing: outgoing.map { |f| f.as_json_for(current_user) }
      }
    end

    def create
      recipient = find_recipient
      return render_not_found("No Hifz.World user found with that email or handle") unless recipient
      return render json: { error: "Cannot add yourself" }, status: :unprocessable_entity if recipient.id == current_user.id

      existing = Friendship.between(current_user, recipient)
      if existing
        if existing.status == "accepted"
          return render json: { error: "Already friends" }, status: :unprocessable_entity
        end
        if existing.recipient_id == current_user.id
          existing.update!(status: "accepted")
          return render json: existing.as_json_for(current_user)
        end
        return render json: existing.as_json_for(current_user)
      end

      friendship = Friendship.new(
        requester: current_user,
        recipient: recipient,
        status: "pending"
      )

      if friendship.save
        render json: friendship.as_json_for(current_user), status: :created
      else
        render_unprocessable(friendship)
      end
    end

    def accept
      return render_forbidden("Only the recipient can accept") unless @friendship.recipient_id == current_user.id
      return render json: { error: "Already accepted" }, status: :unprocessable_entity if @friendship.status == "accepted"

      @friendship.update!(status: "accepted")
      render json: @friendship.as_json_for(current_user)
    end

    def destroy
      unless [@friendship.requester_id, @friendship.recipient_id].include?(current_user.id)
        return render_forbidden("Access denied")
      end

      @friendship.destroy!
      head :no_content
    end

    private

    def set_friendship
      @friendship = Friendship.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render_not_found
    end

    def find_recipient
      if params[:handle].present?
        User.find_by(handle: params[:handle].to_s.delete_prefix("@").downcase)
      elsif params[:email].present?
        User.find_by("LOWER(email) = ?", params[:email].to_s.downcase.strip)
      end
    end
  end
end
