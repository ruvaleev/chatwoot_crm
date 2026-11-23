json.payload @freelancers do |freelancer|
  number = freelancer.inboxes.find { |inbox| inbox.account_id == Current.account.id }
  json.id freelancer.id
  json.name freelancer.name
  json.login freelancer.crm_login
  json.number number&.slice(:id, :name)
  json.clients_count freelancer.assigned_conversations.where(account: Current.account).count
  # Never signed in yet: the invitation link has not been used.
  json.invited freelancer.sign_in_count.zero?
end
json.numbers @numbers do |inbox|
  json.id inbox.id
  json.name inbox.name
  json.freelancer_id inbox.crm_freelancer&.id
end
