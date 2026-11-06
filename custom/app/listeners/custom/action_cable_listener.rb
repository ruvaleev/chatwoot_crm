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

  # Every user listens to the account stream (RoomChannel), so with freelancers around address users one by one.
  def broadcast(account, tokens, event_name, data)
    if tokens == [account_token(account)] && account.users.any?(&:crm_freelancer?)
      tokens = account.users.reject(&:crm_freelancer?).map(&:pubsub_token)
    end

    super(account, tokens, event_name, data)
  end
end
