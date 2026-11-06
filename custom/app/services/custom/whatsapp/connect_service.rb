# Links a WhatsApp number to Chatwoot through Evolution API's built-in Chatwoot integration.
# Idempotent: reuses the bridge user and an existing instance, then (re)starts the connection,
# which makes Evolution post a fresh QR code into the inbox's "EvolutionAPI" conversation.
class Custom::Whatsapp::ConnectService
  BRIDGE_EMAIL = 'whatsapp-bridge@crm.invalid'.freeze
  INSTANCE_SETTINGS = {
    integration: 'WHATSAPP-BAILEYS',
    qrcode: true,
    groupsIgnore: true,
    alwaysOnline: false,
    readMessages: false,
    syncFullHistory: false,
    chatwootSignMsg: false,
    chatwootReopenConversation: true,
    chatwootConversationPending: false,
    chatwootImportContacts: false,
    chatwootImportMessages: false,
    chatwootMergeBrazilContacts: false,
    chatwootOrganization: 'WhatsApp'
  }.freeze

  pattr_initialize [:account!, :instance_name!, :inbox_name!]

  # Returns Evolution's connect response: connection state when already linked, QR data otherwise.
  def perform
    create_instance unless evolution_request(:get, '/instance/fetchInstances').any? { |instance| instance['name'] == instance_name }
    evolution_request(:get, "/instance/connect/#{instance_name}")
  end

  private

  def create_instance
    evolution_request(:post, '/instance/create', body: instance_payload.to_json)
  end

  def instance_payload
    INSTANCE_SETTINGS.merge(
      instanceName: instance_name,
      chatwootAccountId: account.id.to_s,
      chatwootToken: bridge_user.access_token.token,
      chatwootUrl: chatwoot_url,
      chatwootNameInbox: inbox_name,
      # Evolution falls back to a logo hosted on evolution-api.com, which Chatwoot would download.
      chatwootLogo: "#{chatwoot_url}/brand-assets/logo_thumbnail.svg"
    )
  end

  def bridge_user
    @bridge_user ||= begin
      user = User.find_or_create_by!(email: BRIDGE_EMAIL) do |new_user|
        new_user.name = 'WhatsApp'
        new_user.password = "#{SecureRandom.alphanumeric(24)}aA1!"
        new_user.skip_confirmation!
      end
      AccountUser.find_or_create_by!(account: account, user: user) { |account_user| account_user.role = :administrator }
      user
    end
  end

  # URL Evolution uses to reach Chatwoot; differs from FRONTEND_URL on the server (internal network).
  def chatwoot_url
    ENV.fetch('CRM_EVOLUTION_CHATWOOT_URL') { ENV.fetch('FRONTEND_URL') }
  end

  def evolution_request(method, path, body: nil)
    response = HTTParty.send(method, "#{ENV.fetch('EVOLUTION_API_URL')}#{path}",
                             body: body, headers: { 'apikey' => ENV.fetch('EVOLUTION_API_KEY'), 'Content-Type' => 'application/json' })
    raise "Evolution API #{method.upcase} #{path} failed: #{response.code} #{response.body}" unless response.success?

    response.parsed_response
  end
end
