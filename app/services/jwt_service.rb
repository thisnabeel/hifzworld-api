class JwtService
  class Error < StandardError; end

  EXPIRY = 30.days

  def self.encode(user_id)
    payload = {
      sub: user_id,
      exp: EXPIRY.from_now.to_i,
      iat: Time.current.to_i
    }
    JWT.encode(payload, secret, "HS256")
  end

  def self.decode(token)
    body, = JWT.decode(token, secret, true, algorithm: "HS256")
    body.fetch("sub")
  rescue JWT::DecodeError => e
    raise Error, e.message
  end

  def self.secret
    Figaro.env.jwt_secret!.tap do |value|
      raise Error, "JWT_SECRET is missing" if value.blank?
    end
  end
end
