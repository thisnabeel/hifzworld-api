module Api
  class BundlesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_bundle, only: %i[show update destroy share]

    def mine
      owned = current_user.owned_bundles.includes(bundle_shares: :shared_with).order(updated_at: :desc)
      shared_ids = BundleShare.accepted.where(shared_with: current_user).pluck(:mushaf_bundle_id)
      shared = MushafBundle.where(id: shared_ids).order(updated_at: :desc)

      render json: {
        owned: owned.map { |bundle| bundle.as_json(role: "owner") },
        shared: shared.map { |bundle| bundle.as_json(role: "shared") }
      }
    end

    def create
      bundle = current_user.owned_bundles.new(bundle_params)
      if bundle.save
        render json: bundle.as_json(role: "owner"), status: :created
      else
        render_unprocessable(bundle)
      end
    end

    def show
      return render_forbidden("Access denied") unless can_access?(@bundle)

      render json: @bundle.as_json(role: bundle_role(@bundle))
    end

    def update
      return render_forbidden("Only the owner can edit") unless @bundle.owner_id == current_user.id

      if @bundle.update(bundle_params)
        render json: @bundle.as_json(role: "owner")
      else
        render_unprocessable(@bundle)
      end
    end

    def destroy
      return render_forbidden("Only the owner can delete") unless @bundle.owner_id == current_user.id

      @bundle.destroy!
      head :no_content
    end

    def share
      return render_forbidden("Only the owner can share") unless @bundle.owner_id == current_user.id

      recipient = find_recipient
      return render_not_found("Recipient not found") unless recipient
      return render json: { error: "Cannot share with yourself" }, status: :unprocessable_entity if recipient.id == current_user.id

      share = BundleShare.find_or_initialize_by(mushaf_bundle: @bundle, shared_with: recipient)
      share.shared_by = current_user
      share.status = "pending"

      if share.save
        render json: share.as_json, status: :created
      else
        render_unprocessable(share)
      end
    end

    private

    def set_bundle
      @bundle = MushafBundle.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render_not_found
    end

    def bundle_params
      params.permit(:title, :description, :mushaf_id, page_numbers: [])
    end

    def find_recipient
      if params[:handle].present?
        User.find_by(handle: params[:handle].to_s.delete_prefix("@").downcase)
      elsif params[:email].present?
        User.find_by("LOWER(email) = ?", params[:email].downcase)
      end
    end

    def can_access?(bundle)
      bundle.owner_id == current_user.id ||
        BundleShare.accepted.exists?(mushaf_bundle: bundle, shared_with: current_user)
    end

    def bundle_role(bundle)
      bundle.owner_id == current_user.id ? "owner" : "shared"
    end
  end
end
