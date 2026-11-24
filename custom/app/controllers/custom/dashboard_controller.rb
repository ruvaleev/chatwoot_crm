# The new interface is the main one (crm/PRD.md, stage D4): the root opens it, and freelancers no longer get the old
# dashboard at /app. In production the old dashboard is not built (custom/config/vite_entrypoints.js, stage L3), so
# everyone goes to /crm; in development managers keep it for comparison.
module Custom::DashboardController
  def self.prepended(base)
    base.prepend_before_action :crm_redirect, only: :index
  end

  private

  def crm_redirect
    redirect_to '/crm/' if request.path == '/' || Rails.env.production? || crm_session_user&.crm_freelancer?
  end

  # The dashboard page itself is served without a session; the user is the one of the sign-in cookie both apps share.
  def crm_session_user
    session = JSON.parse(cookies['cw_d_session_info'].to_s)
    user = User.find_by(uid: session['uid'])
    user if user&.valid_token?(session['access-token'], session['client'])
  rescue JSON::ParserError
    nil
  end
end
