# Team settings (crm/design/brief.md, "Настройки команды"): everyone reads them (thresholds, refusal reasons),
# only managers change them.
class Custom::Api::V1::Accounts::Crm::SettingsController < Api::V1::Accounts::BaseController
  before_action :ensure_manager, only: :update

  def show
    render json: Current.account.crm_settings
  end

  def update
    account = Current.account
    account.crm_settings = settings_params.to_h
    return render_could_not_create_error('settings_invalid') unless account.save

    render json: account.crm_settings
  end

  private

  def settings_params
    params.permit(:overdue_minutes, :overdue_minutes_off_hours, :notification_locale, lost_reasons: [])
  end

  def ensure_manager
    head :forbidden if Current.user.crm_freelancer?
  end
end
