module Custom::Api::V1::Accounts::BaseController
  def self.prepended(base)
    base.after_action :crm_scrub_client_phones, if: lambda {
      Current.user.try(:crm_freelancer?) && response.media_type == 'application/json' && response.body.present?
    }
  end

  private

  def crm_scrub_client_phones
    response.body = Custom::PhoneScrubber.new(locale: I18n.locale).scrub(JSON.parse(response.body)).to_json
  end
end
