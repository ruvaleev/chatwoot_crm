# Evolution API reports a message it could not deliver to WhatsApp only as a private note from the bridge user
# ("🚨 The message could not be sent…", src/utils/translations/*.json), without saying which message failed.
# We mark the latest outgoing message WhatsApp never got (Evolution sets source_id on what it sent) as failed —
# the UI offers a retry — and drop the note.
class Custom::Whatsapp::SendFailure
  ALERT = '🚨'.freeze
  WINDOW = 5.minutes

  pattr_initialize :note

  def self.note?(message)
    message.private? && message.content.to_s.start_with?(ALERT) &&
      message.sender.try(:email) == Custom::Whatsapp::ConnectService::BRIDGE_EMAIL
  end

  def perform
    failed = note.conversation.messages.outgoing.where(private: false, source_id: nil, created_at: (note.created_at - WINDOW)..note.created_at)
                 .where.not(status: :failed).reorder(:created_at).last
    return if failed.nil?

    Messages::StatusUpdateService.new(failed, 'failed', note.content).perform
    note.destroy!
  end
end
