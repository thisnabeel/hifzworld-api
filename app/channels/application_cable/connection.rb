module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      token = request.params[:token].presence || bearer_token
      raise UnauthorizedError unless token

      user_id = JwtService.decode(token)
      User.find(user_id)
    rescue JwtService::Error, ActiveRecord::RecordNotFound
      raise UnauthorizedError
    end

    def bearer_token
      header = request.headers["Authorization"].to_s
      return nil unless header.start_with?("Bearer ")

      header.delete_prefix("Bearer ").strip
    end
  end
end
