class LivekitTokenService
  def self.enabled?
    Figaro.env.livekit_url.present? &&
      Figaro.env.livekit_api_key.present? &&
      Figaro.env.livekit_api_secret.present?
  end

  def self.token_for(user:, room_name:)
    return nil unless enabled?

    begin
      require "livekit"
      token = LiveKit::AccessToken.new(
        api_key: Figaro.env.livekit_api_key!,
        api_secret: Figaro.env.livekit_api_secret!,
        identity: user.id,
        name: user.display_name
      )
      token.add_grant(LiveKit::VideoGrant.new(roomJoin: true, room: room_name))
      { url: Figaro.env.livekit_url!, token: token.to_jwt, room: room_name }
    rescue LoadError
      { url: Figaro.env.livekit_url!, room: room_name, token: nil, note: "Install livekit-server-sdk for tokens" }
    end
  end
end
