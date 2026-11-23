# Entry point for fork-specific reactions to Chatwoot events (Telegram notifications, escalations, etc.).
class Custom::CrmListener < BaseListener
  def message_created(event)
    message, = extract_message_and_account(event)
    return Custom::Whatsapp::SendFailure.new(message).perform if Custom::Whatsapp::SendFailure.note?(message)
    return unless message.incoming?

    # A hidden chat comes back to every list as soon as the client writes again.
    message.conversation.crm_hidden_conversations.delete_all
  end
end
