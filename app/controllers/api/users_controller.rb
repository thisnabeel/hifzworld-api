module Api
  class UsersController < ApplicationController
    before_action :authenticate_user!

    def me
      render json: current_user.as_json
    end
  end
end
