module Custom::Api::V1::Accounts::ContactsController
  private

  # index, active, search and filter all page through these two methods.
  def fetch_contacts(contacts)
    super(contacts.crm_visible_to(Current.user))
  end

  def fetch_contacts_with_has_more(contacts)
    super(contacts.crm_visible_to(Current.user))
  end

  def fetch_contact
    super
    raise ActiveRecord::RecordNotFound unless @contact.crm_visible_to?(Current.user)
  end
end
