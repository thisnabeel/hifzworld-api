module Api
  class HealthController < ApplicationController
    def show
      render json: { status: "ok", service: "hifzworld-api" }
    end
  end
end
