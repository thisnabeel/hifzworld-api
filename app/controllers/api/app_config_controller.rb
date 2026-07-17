module Api
  class AppConfigController < ApplicationController
    # Public — used by the iOS force-update gate before sign-in.
    def show
      min = Figaro.env.min_app_version.to_s.strip
      store_id = Figaro.env.ios_app_store_id.to_s.strip

      render json: {
        min_app_version: min.presence,
        app_store_id: store_id.presence
      }
    end
  end
end
