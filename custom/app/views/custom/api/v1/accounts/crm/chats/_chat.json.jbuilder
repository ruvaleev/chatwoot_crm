last_message = chat.messages.non_activity_messages.where(private: false).first
json.id chat.display_id
json.contact do
  json.id chat.contact_id
  json.name chat.contact.name
  json.labels chat.contact.label_list
end
json.inbox do
  json.id chat.inbox_id
  json.name chat.inbox.name
  json.freelancer chat.inbox.crm_freelancer&.slice(:id, :name)
end
json.assignee chat.assignee&.slice(:id, :name)
json.status chat.crm_status
json.waiting_since chat.waiting_since&.to_i
json.last_activity_at chat.last_activity_at.to_i
json.unread_count chat.unread_incoming_messages.count
json.last_message do
  if last_message
    json.content last_message.content.to_s.truncate(200)
    json.incoming last_message.incoming?
    json.status last_message.status
    json.attachment_type last_message.attachments.first&.file_type
    json.created_at last_message.created_at.to_i
  else
    json.nil!
  end
end
