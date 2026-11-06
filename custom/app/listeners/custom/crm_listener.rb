# Entry point for fork-specific reactions to Chatwoot events (Telegram notifications, escalations, etc.).
class Custom::CrmListener < BaseListener
  def message_created(_event); end
end
