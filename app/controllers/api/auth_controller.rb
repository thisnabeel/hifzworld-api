module Api
  class AuthController < ApplicationController
    def apple
      if Figaro.env.apple_auth_skip_verify == "true"
        user = upsert_dev_user
      else
        claims = AppleAuthService.verify!(identity_token: params[:identity_token])
        user = User.find_or_initialize_by(apple_sub: claims[:apple_sub])
        user.email ||= claims[:email]
        user.display_name = params[:display_name].presence || user.display_name || "User"
        user.save!
      end

      render json: { token: JwtService.encode(user.id), user: user.as_json }
    rescue AppleAuthService::Error => e
      render json: { error: e.message }, status: :unauthorized
    rescue ActiveRecord::RecordInvalid => e
      render json: { error: e.record.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end

    private

    def upsert_dev_user
      apple_sub = params[:apple_sub].presence || "dev-#{params[:email].presence || SecureRandom.uuid}"
      user = User.find_or_initialize_by(apple_sub: apple_sub)
      user.display_name = params[:display_name].presence || "Dev User"
      user.email = params[:email]
      user.save!
      user
    end
  end
end
