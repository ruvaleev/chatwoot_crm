# Notes, labels, contact inboxes, conversations and attachments of a contact.
module Custom::Api::V1::Accounts::Contacts::BaseController
  private

  def ensure_contact
    super
    raise ActiveRecord::RecordNotFound unless @contact.crm_visible_to?(Current.user)
  end
end
