# A chat a user hid from their own list, like WhatsApp's archive. It comes back when the client writes again.
class Custom::HiddenConversation < ApplicationRecord
  self.table_name = 'crm_hidden_conversations'

  belongs_to :user
  belongs_to :conversation

  validates :conversation_id, uniqueness: { scope: :user_id }
end
