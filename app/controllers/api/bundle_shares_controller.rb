module Api
  class BundleSharesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_share, only: :accept

    def index
      shares = current_user.incoming_shares.pending.includes(:mushaf_bundle, :shared_by).order(created_at: :desc)
      render json: shares.map(&:as_json)
    end

    def accept
      return render_forbidden("Not your share") unless @share.shared_with_id == current_user.id

      @share.update!(status: "accepted")
      render json: @share.as_json
    end

    private

    def set_share
      @share = BundleShare.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render_not_found
    end
  end
end
