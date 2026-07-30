module Api
  class UsersController < ApplicationController
    before_action :authenticate_user!

    def me
      current_user.ensure_handle!
      render json: current_user.as_json
    end

    def update
      attrs = {}
      if params.key?(:handle)
        attrs[:handle] = params[:handle]
      end
      if params[:display_name].present?
        attrs[:display_name] = params[:display_name]
      end

      if attrs.empty?
        return render json: { error: "Nothing to update" }, status: :unprocessable_entity
      end

      if params.key?(:handle) && params[:handle].present?
        normalized = HandleService.sanitize(params[:handle].to_s.delete_prefix("@"))
        if HandleService.taken?(normalized, current_user.id)
          return render json: { error: "Handle is already taken" }, status: :unprocessable_entity
        end
        attrs[:handle] = normalized
      end

      if current_user.update(attrs)
        render json: current_user.as_json
      else
        render_unprocessable(current_user)
      end
    end

    def destroy
      current_user.destroy!
      head :no_content
    end
  end
end
