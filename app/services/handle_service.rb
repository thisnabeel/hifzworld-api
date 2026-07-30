module HandleService
  module_function

  def from_email(email)
    return nil if email.blank?

    local = email.to_s.split("@", 2).first.to_s
    sanitize(local)
  end

  def sanitize(raw)
    cleaned = raw.to_s.downcase.gsub(/[^a-z0-9_]/, "_").gsub(/_+\z/, "").gsub(/\A_+/, "").squeeze("_")
    cleaned = cleaned[0, 30]
    cleaned = "user" if cleaned.length < 3
    cleaned
  end

  def unique_for(base, excluding_user_id: nil)
    candidate = sanitize(base)
    return candidate unless taken?(candidate, excluding_user_id)

    2.upto(99) do |n|
      suffix = n.to_s
      truncated = candidate[0, 30 - suffix.length]
      next_candidate = "#{truncated}#{suffix}"
      return next_candidate unless taken?(next_candidate, excluding_user_id)
    end

    "#{candidate[0, 20]}#{SecureRandom.hex(4)}"
  end

  def taken?(handle, excluding_user_id)
    scope = User.where(handle: handle)
    scope = scope.where.not(id: excluding_user_id) if excluding_user_id
    scope.exists?
  end
end
