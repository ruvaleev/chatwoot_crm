module Custom::Api::V1::Accounts::ContactsController
  PHONE_FILTER_KEYS = %w[phone_number identifier].freeze

  private

  # index, active, search and filter all page through these two methods.
  def fetch_contacts(contacts)
    super(crm_scope(contacts))
  end

  def fetch_contacts_with_has_more(contacts)
    super(crm_scope(contacts))
  end

  # Freelancers can't look a client up by phone: that would confirm a number they are not shown.
  def crm_scope(contacts)
    return contacts.none if Current.user.crm_freelancer? && crm_phone_lookup?

    contacts.crm_visible_to(Current.user)
  end

  def crm_phone_lookup?
    Custom::PhoneScrubber.number_probe?(params[:q]) ||
      Array(params[:payload]).any? { |condition| PHONE_FILTER_KEYS.include?(condition[:attribute_key].to_s) }
  end

  # The contact form of a freelancer shows no phone and a masked name; saving it must not overwrite them.
  def contact_update_params
    return super unless Current.user.crm_freelancer?

    update_params = super.except(:phone_number, :identifier)
    update_params[:name].to_s.include?(Custom::PhoneScrubber::MASK) ? update_params.except(:name) : update_params
  end

  def fetch_contact
    super
    raise ActiveRecord::RecordNotFound unless @contact.crm_visible_to?(Current.user)
  end
end
