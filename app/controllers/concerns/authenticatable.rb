module Authenticatable
  extend ActiveSupport::Concern

  included do
    attr_reader :current_user
  end

  private

  def authenticate_user!
    token = bearer_token
    return render_unauthorized("Missing token") if token.blank?

    user_id = JwtService.decode(token)
    @current_user = User.find(user_id)
  rescue JwtService::Error, ActiveRecord::RecordNotFound
    render_unauthorized("Invalid token")
  end

  def bearer_token
    header = request.headers["Authorization"].to_s
    return nil unless header.start_with?("Bearer ")

    header.delete_prefix("Bearer ").strip
  end

  def render_unauthorized(message)
    render json: { error: message }, status: :unauthorized
  end

  def render_forbidden(message)
    render json: { error: message }, status: :forbidden
  end

  def render_not_found(message = "Not found")
    render json: { error: message }, status: :not_found
  end

  def render_unprocessable(record)
    render json: { error: record.errors.full_messages.join(", ") }, status: :unprocessable_entity
  end
end
