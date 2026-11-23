json.payload @numbers do |inbox, instance|
  json.id inbox.id
  json.name inbox.name
  json.instance inbox.crm_whatsapp_instance
  json.state instance&.dig('connectionStatus') || 'unknown'
  # The company's own number (WhatsApp id <phone>@s.whatsapp.net); only managers reach this endpoint.
  digits = instance&.dig('ownerJid').to_s.split('@').first
  json.phone_number digits.present? ? "+#{digits}" : nil
  json.disconnected_at instance&.dig('disconnectionAt')
  json.freelancer inbox.crm_freelancer&.slice(:id, :name)
end
json.freelancers @freelancers, :id, :name
