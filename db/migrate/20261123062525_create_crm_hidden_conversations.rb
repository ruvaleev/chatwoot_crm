# CRM: chats a user hid from their own list (crm/PRD.md, stage D). See crm/docs/core-changes.md.
class CreateCrmHiddenConversations < ActiveRecord::Migration[7.2]
  def change
    create_table :crm_hidden_conversations do |t|
      t.references :user, null: false, index: false
      t.references :conversation, null: false, index: true
      t.timestamps
    end
    add_index :crm_hidden_conversations, [:user_id, :conversation_id], unique: true
  end
end
