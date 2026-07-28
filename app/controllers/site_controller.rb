class SiteController < ActionController::Base
  # Public HTML pages for App Store Support / Privacy / Contact URLs.
  layout "site"

  def home
  end

  def support
  end

  def privacy
  end

  def contact
  end

  def invite
    @invite = DeckInvite.active.includes(:mushaf_bundle, :created_by).find_by(token: params[:token].to_s)
    return render plain: "This invite link is invalid or has expired.", status: :not_found unless @invite

    @bundle = @invite.mushaf_bundle
    @shared_by_name = @invite.created_by&.display_name.presence || "Someone"
    @deep_link = "hifzworld://invite/#{@invite.token}"
    store_id = ENV["IOS_APP_STORE_ID"].to_s.strip
    @app_store_url = store_id.present? ? "https://apps.apple.com/app/id#{store_id}" : nil
  end
end
