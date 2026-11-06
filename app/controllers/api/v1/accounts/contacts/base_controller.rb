class Api::V1::Accounts::Contacts::BaseController < Api::V1::Accounts::BaseController
  before_action :ensure_contact

  private

  def ensure_contact
    @contact = Current.account.contacts.find(params[:contact_id])
  end
end

# CRM: extension point for custom/ (crm/docs/core-changes.md)
Api::V1::Accounts::Contacts::BaseController.prepend_mod_with('Api::V1::Accounts::Contacts::BaseController')
