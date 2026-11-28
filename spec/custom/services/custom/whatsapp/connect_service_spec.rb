require 'rails_helper'

describe Custom::Whatsapp::ConnectService do
  subject(:service) { described_class.new(account: account, instance_name: 'number-a', inbox_name: 'Number A') }

  let(:account) { create(:account) }
  let(:evolution_url) { 'http://evolution.test' }
  let(:headers) { { 'Content-Type' => 'application/json' } }
  let(:qr_response) { { pairingCode: nil, code: 'qr-data', base64: 'data:image/png;base64,AAA', count: 1 } }
  let(:existing_instances) { [] }
  let(:fetch_response) { { status: 200, body: existing_instances.to_json, headers: headers } }
  let!(:fetch_request) do
    stub_request(:get, "#{evolution_url}/instance/fetchInstances").with(headers: { 'apikey' => 'evo-key' }).to_return(fetch_response)
  end
  let!(:create_request) { stub_request(:post, "#{evolution_url}/instance/create").to_return(status: 201, body: '{}', headers: headers) }
  let!(:connect_request) do
    stub_request(:get, "#{evolution_url}/instance/connect/number-a").to_return(status: 200, body: qr_response.to_json, headers: headers)
  end

  around do |example|
    with_modified_env(EVOLUTION_API_URL: evolution_url, EVOLUTION_API_KEY: 'evo-key', FRONTEND_URL: 'http://chatwoot.test',
                      CRM_EVOLUTION_CHATWOOT_URL: nil) { example.run }
  end

  it 'creates an instance linked to the account through an administrator bridge user' do
    expect(service.perform).to include('code' => 'qr-data')

    bridge_user = User.find_by!(email: described_class::BRIDGE_EMAIL)
    expect(bridge_user.account_users.find_by!(account: account)).to be_administrator
    expect(create_request.with(body: hash_including(
      'instanceName' => 'number-a', 'integration' => 'WHATSAPP-BAILEYS', 'chatwootAccountId' => account.id.to_s,
      'chatwootToken' => bridge_user.access_token.token, 'chatwootUrl' => 'http://chatwoot.test', 'chatwootNameInbox' => 'Number A',
      'chatwootSignMsg' => false, 'chatwootLogo' => 'http://chatwoot.test/brand-assets/logo_thumbnail.svg'
    ))).to have_been_made.once
    expect(connect_request).to have_been_made.once
  end

  it 'reuses the bridge user on repeated runs' do
    service.perform
    service.perform

    expect(User.where(email: described_class::BRIDGE_EMAIL).count).to eq(1)
    expect(fetch_request).to have_been_made.twice
  end

  context 'when the instance already exists' do
    let(:existing_instances) { [{ name: 'number-a', connectionStatus: 'open' }] }
    let(:qr_response) { { instance: { instanceName: 'number-a', state: 'open' } } }

    it 'only reconnects without creating a new instance' do
      expect(service.perform).to eq('instance' => { 'instanceName' => 'number-a', 'state' => 'open' })
      expect(create_request).not_to have_been_made
    end
  end

  context 'when Evolution rejects the request' do
    let(:fetch_response) { { status: 401, body: 'Unauthorized' } }

    it 'fails loudly' do
      expect { service.perform }.to raise_error(RuntimeError, /401/)
    end
  end

  it 'gives Evolution enough time to answer the outgoing message webhook' do
    service.perform

    expect(GlobalConfig.get_value('WEBHOOK_TIMEOUT')).to eq(described_class::WEBHOOK_TIMEOUT_SECONDS)
  end
end
