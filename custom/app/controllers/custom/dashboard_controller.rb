# The new interface is the main one (crm/PRD.md, stage D4): the root opens it, and freelancers no longer get the old
# dashboard at /app. Managers keep /app during the transition (stage L takes it out of the production build).
module Custom::DashboardController
  def self.prepended(base)
    base.prepend_before_action :crm_redirect, only: :index
  end

  private

  def crm_redirect
    redirect_to '/crm/' if request.path == '/' || crm_session_user&.crm_freelancer?
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
