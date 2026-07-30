module Api
  class FriendBundlesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_friend
    before_action :require_accepted_friendship!

    def index
      bundles = @friend.owned_bundles.includes(bundle_shares: :shared_with).order(updated_at: :desc)
      render json: {
        friend: @friend.as_json,
        bundles: bundles.map { |bundle|
          ensure_coach_share!(bundle)
          bundle.as_json(role: "shared")
        }
      }
    end

    def create
      bundle = @friend.owned_bundles.new(bundle_params)
      if bundle.save
        ensure_coach_share!(bundle)
        render json: bundle.as_json(role: "shared"), status: :created
      else
        render_unprocessable(bundle)
      end
    end

    private

    def set_friend
      @friend = User.find(params[:user_id])
    rescue ActiveRecord::RecordNotFound
      render_not_found("Friend not found")
    end

    def require_accepted_friendship!
      return if performed?
      return if Friendship.accepted_between?(current_user, @friend)

      render_forbidden("You must be friends to view or create decks for this user")
    end

    def bundle_params
      params.permit(:title, :description, :mushaf_id, page_numbers: [])
    end

    # Coach can open/join review; owner sees coach as collaborator for Start Review.
    def ensure_coach_share!(bundle)
      share = BundleShare.find_or_initialize_by(mushaf_bundle: bundle, shared_with: current_user)
      share.shared_by ||= @friend
      share.status = "accepted"
      share.save! if share.changed? || share.new_record?
      share
    end
  end
end
