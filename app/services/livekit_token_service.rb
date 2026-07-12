require "jwt"
require "securerandom"

class LivekitTokenService
  def self.enabled?
    Figaro.env.livekit_url.present? &&
      Figaro.env.livekit_api_key.present? &&
      Figaro.env.livekit_api_secret.present?
  end

  def self.token_for(user:, room_name:)
    return nil unless enabled?

    # LiveKit access token (JWT) — video grant for room join
    # Spec: https://docs.livekit.io/home/server/generating-tokens/
    video_grant = {
      roomJoin: true,
      room: room_name,
      canPublish: true,
      canSubscribe: true
    }

    payload = {
      exp: 6.hours.from_now.to_i,
      iss: Figaro.env.livekit_api_key!,
      nbf: Time.current.to_i - 10,
      sub: user.id,
      name: user.display_name,
      video: video_grant,
      metadata: ""
    }

    token = JWT.encode(payload, Figaro.env.livekit_api_secret!, "HS256")

    {
      url: Figaro.env.livekit_url!,
      token: token,
      room: room_name
    }
  end
end
