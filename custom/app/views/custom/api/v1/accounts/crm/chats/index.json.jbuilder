json.meta do
  json.waiting_count @counts[:waiting]
  json.new_count @counts[:new]
  json.mine_count @counts[:mine]
  json.hidden_count @counts[:hidden]
  json.inboxes @inboxes, :id, :name
  json.assignees @assignees, :id, :name
  json.page @chats.current_page
  # Not !last_page?: an empty result has zero pages, so page 1 is never the last and the list would load on and on.
  json.has_more @chats.next_page.present?
end
json.payload @chats, partial: 'custom/api/v1/accounts/crm/chats/chat', as: :chat
