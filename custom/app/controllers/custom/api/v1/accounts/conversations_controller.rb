module Custom::Api::V1::Accounts::ConversationsController
  # A freelancer may start conversations only with clients they already see and only for themselves.
  # The visibility check runs inside the transaction because an inbox locked to a single conversation
  # returns the existing one, which can be assigned to someone else.
  # Current.user can be an AgentBot here (bots may create conversations).
  def create
    return super unless Current.user.try(:crm_freelancer?)

    raise ActiveRecord::RecordNotFound unless @contact_inbox.contact.crm_visible_to?(Current.user)

    ActiveRecord::Base.transaction do
      super
      raise ActiveRecord::RecordNotFound unless @conversation.crm_visible_to?(Current.user)
    end
  end

  private

  # Checked before the contact inbox is built for the contact.
  def contact
    super
    raise ActiveRecord::RecordNotFound if Current.user.try(:crm_freelancer?) && @contact && !@contact.crm_visible_to?(Current.user)
  end
end
