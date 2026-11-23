json.meta do
  json.waiting_count @waiting_count
  json.hidden_count @hidden_count
  json.page @chats.current_page
  json.has_more !@chats.last_page?
end
json.payload @chats, partial: 'custom/api/v1/accounts/crm/chats/chat', as: :chat
