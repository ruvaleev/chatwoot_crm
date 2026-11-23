json.meta do
  json.waiting_count @counts[:waiting]
  json.new_count @counts[:new]
  json.mine_count @counts[:mine]
  json.hidden_count @counts[:hidden]
  json.inboxes @inboxes, :id, :name
  json.page @chats.current_page
  json.has_more !@chats.last_page?
end
json.payload @chats, partial: 'custom/api/v1/accounts/crm/chats/chat', as: :chat
