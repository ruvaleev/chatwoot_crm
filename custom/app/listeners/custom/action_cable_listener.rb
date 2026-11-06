# Upstream broadcasts conversation events to every inbox member and contact events to the whole account.
# Freelancers must only receive events of conversations assigned to them and no contact events.
module Custom::ActionCableListener
  def self.prepended(base)
    base.public_instance_methods(false).each do |event_handler|
      define_method(event_handler) do |event|
        conversation = event.data[:conversation] || event.data[:message].try(:conversation)
        Custom::EventContext.set(conversation: conversation) { super(event) }
      end
    end
  end

  private

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
