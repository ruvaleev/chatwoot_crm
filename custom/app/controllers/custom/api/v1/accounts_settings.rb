# Companies are closed to freelancers (Custom::CompanyPolicy), so their dashboard treats the feature as off:
# no Companies menu and no company picker on the contact form.
module Custom::Api::V1::AccountsSettings
  def show
    super
    return unless current_user.crm_freelancer?

    account = JSON.parse(response.body)
    account['features'].delete('companies')
    response.body = account.to_json
  end
end
