# Upstream broadcasts conversation events to every inbox member and contact events to the whole account.
# Freelancers must only receive events of conversations assigned to them and no contact events.
module Custom::ActionCableListener
  CONVERSATION_ACCESS_REVOKED = 'conversation.crm_access_revoked'.freeze

  def self.prepended(base)
    base.public_instance_methods(false).each do |event_handler|
      define_method(event_handler) do |event|
        conversation = event.data[:conversation] || event.data[:message].try(:conversation)
        Custom::EventContext.set(conversation: conversation) { super(event) }
        crm_revoke_access(event) if event_handler == :assignee_changed
      end
    end
  end

  private

  # A freelancer no longer receives events of a reassigned conversation, so the frontend is told to drop it from the list.
  def crm_revoke_access(event)
    conversation = event.data[:conversation]
    previous_assignee = conversation.account.users.find_by(id: event.data.dig(:changed_attributes, 'assignee_id', 0))
    return if previous_assignee.nil? || conversation.crm_visible_to?(previous_assignee)

    broadcast(conversation.account, [previous_assignee.pubsub_token], CONVERSATION_ACCESS_REVOKED, { id: conversation.display_id })
  end

  def user_tokens(account, agents)
    conversation = Custom::EventContext.conversation
    return super if conversation.blank?

    super - account.users.reject { |user| conversation.crm_visible_to?(user) }.map(&:pubsub_token)
  end

  # Freelancers get the same events without client phone numbers. Every user listens to the account stream
  # (RoomChannel), so with freelancers around contact events are addressed to the other users one by one.
  def broadcast(account, tokens, event_name, data)
    freelancer_tokens = account.users.select(&:crm_freelancer?).map(&:pubsub_token)
    return super if freelancer_tokens.empty?

    tokens = account.users.reject(&:crm_freelancer?).map(&:pubsub_token) if tokens == [account_token(account)]
    super(account, tokens - freelancer_tokens, event_name, data)
    super(account, tokens & freelancer_tokens, event_name, Custom::PhoneScrubber.new(locale: account.locale).scrub(data))
  end
end
