module Api
  class InvitesController < ApplicationController
    before_action :authenticate_user!

    def claim
      invite = DeckInvite.active.find_by(token: params[:token].to_s)
      return render_not_found("Invite not found") unless invite

      bundle = invite.mushaf_bundle
      if bundle.owner_id == current_user.id
        return render json: { error: "You already own this deck" }, status: :unprocessable_entity
      end

      share = BundleShare.find_or_initialize_by(mushaf_bundle: bundle, shared_with: current_user)
      share.shared_by = invite.created_by
      share.status = "accepted"

      if share.save
        render json: share.as_json
      else
        render_unprocessable(share)
      end
    end
  end
end
