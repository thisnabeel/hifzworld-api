require "net/http"
require "json"
require "jwt"

class AppleAuthService
  class Error < StandardError; end

  APPLE_KEYS_URL = URI("https://appleid.apple.com/auth/keys")
  APPLE_ISSUER = "https://appleid.apple.com"

  def self.verify!(identity_token:)
    raise Error, "identity_token is required" if identity_token.blank?

    header = JWT.decode(identity_token, nil, false).last
    kid = header["kid"]
    raise Error, "Missing key id" if kid.blank?

    key = fetch_apple_key(kid)
    payload, = JWT.decode(
      identity_token,
      key,
      true,
      algorithms: ["RS256"],
      iss: APPLE_ISSUER,
      verify_iss: true,
      aud: Figaro.env.apple_client_id!,
      verify_aud: true
    )

    apple_sub = payload["sub"]
    raise Error, "Missing subject" if apple_sub.blank?

    {
      apple_sub: apple_sub,
      email: payload["email"]
    }
  end

  def self.fetch_apple_key(kid)
    keys = cached_keys
    jwk = keys.find { |entry| entry["kid"] == kid }
    raise Error, "Apple public key not found" unless jwk

    JWT::JWK.import(jwk).public_key
  end

  def self.cached_keys
    @cached_keys ||= begin
      response = Net::HTTP.get_response(APPLE_KEYS_URL)
      raise Error, "Unable to fetch Apple keys" unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body).fetch("keys")
    end
  end
end
