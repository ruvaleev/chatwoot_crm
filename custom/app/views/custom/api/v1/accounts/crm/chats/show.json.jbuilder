json.partial! 'custom/api/v1/accounts/crm/chats/chat', chat: @chat
# Scrubbed for freelancers like every phone in their responses.
json.phone_number @chat.contact.phone_number
json.number_state @number_state if @number_state
json.hidden Current.user.crm_hidden_conversations.exists?(conversation: @chat)
json.deal @chat.crm_deal
json.brief do
  brief = @chat.crm_brief
  if brief
    json.content brief.content
    json.author brief.sender&.name
    json.created_at brief.created_at.to_i
  else
    json.nil!
  end
end
