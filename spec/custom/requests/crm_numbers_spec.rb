require 'rails_helper'

RSpec.describe 'CRM numbers API', type: :request do
  let(:account) { create(:account) }
  let(:evolution_url) { 'http://evolution.test' }
  let(:headers) { { 'Content-Type' => 'application/json' } }
  let(:manager) { create(:user, account: account, role: :administrator) }
  let(:freelancer) { create(:user, account: account, role: :agent, custom_attributes: { crm_freelancer: true }) }
  let(:channel) { create(:channel_api, account: account, webhook_url: "#{evolution_url}/chatwoot/webhook/number-a") }
  # The channel factory creates the inbox itself.
  let!(:number) { channel.inbox.tap { |inbox| inbox.update!(name: 'Number A') } }
  let(:numbers_path) { "/api/v1/accounts/#{account.id}/crm/numbers" }
  let(:instances) { [{ name: 'number-a', connectionStatus: 'open', ownerJid: '15550104477@s.whatsapp.net', disconnectionAt: nil }] }

  around do |example|
    with_modified_env(EVOLUTION_API_URL: evolution_url, EVOLUTION_API_KEY: 'evo-key', FRONTEND_URL: 'http://chatwoot.test',
                      CRM_EVOLUTION_CHATWOOT_URL: nil) { example.run }
  end

  before do
    create(:inbox, account: account, name: 'Website')
    stub_request(:get, "#{evolution_url}/instance/fetchInstances").to_return(status: 200, body: instances.to_json, headers: headers)
  end

  it 'lists Evolution numbers with their state, phone and freelancer' do
    create(:inbox_member, inbox: number, user: freelancer)

    get numbers_path, headers: manager.create_new_auth_token, as: :json

    expect(response.parsed_body['payload']).to contain_exactly(
      include('id' => number.id, 'name' => 'Number A', 'state' => 'open', 'phone_number' => '+15550104477',
              'freelancer' => include('id' => freelancer.id))
    )
    expect(response.parsed_body['freelancers'].pluck('id')).to eq([freelancer.id])
  end

  it 'is closed to freelancers' do
    get numbers_path, headers: freelancer.create_new_auth_token, as: :json

    expect(response).to have_http_status(:forbidden)
  end

  it 'adds a number through Evolution and returns its QR code' do
    stub_request(:post, "#{evolution_url}/instance/create").to_return(status: 201, body: '{}', headers: headers)
    connect = stub_request(:get, %r{#{evolution_url}/instance/connect/crm-\w+})
              .to_return(status: 200, body: { base64: 'data:image/png;base64,AAA' }.to_json, headers: headers)

    post numbers_path, params: { name: 'Number B' }, headers: manager.create_new_auth_token, as: :json

    expect(response.parsed_body).to include('qr' => 'data:image/png;base64,AAA', 'instance' => start_with('crm-'))
    expect(a_request(:post, "#{evolution_url}/instance/create").with(body: hash_including('chatwootNameInbox' => 'Number B'))).to have_been_made
    expect(connect).to have_been_made
  end

  it 'reconnects and polls the state of a number' do
    stub_request(:get, "#{evolution_url}/instance/connect/number-a")
      .to_return(status: 200, body: { base64: 'data:image/png;base64,BBB' }.to_json, headers: headers)
    stub_request(:get, "#{evolution_url}/instance/connectionState/number-a")
      .to_return(status: 200, body: { instance: { instanceName: 'number-a', state: 'connecting' } }.to_json, headers: headers)

    post "#{numbers_path}/#{number.id}/connect", headers: manager.create_new_auth_token, as: :json
    expect(response.parsed_body).to include('qr' => 'data:image/png;base64,BBB')

    get "#{numbers_path}/#{number.id}/state", headers: manager.create_new_auth_token, as: :json
    expect(response.parsed_body).to eq('state' => 'connecting')
  end

  it 'assigns one freelancer per number and hands the number clients over with it' do
    other = create(:inbox, account: account)
    create(:inbox_member, inbox: other, user: freelancer)
    left_behind = create(:conversation, account: account, inbox: other, assignee: freelancer)
    previous = create(:user, account: account, role: :agent, custom_attributes: { crm_freelancer: true })
    create(:inbox_member, inbox: number, user: previous)
    client = create(:conversation, account: account, inbox: number, assignee: previous)

    patch "#{numbers_path}/#{number.id}", params: { freelancer_id: freelancer.id }, headers: manager.create_new_auth_token, as: :json

    expect(number.reload.members).to contain_exactly(freelancer)
    expect(other.reload.members).to be_empty
    expect(client.reload.assignee).to eq(freelancer)
    expect(left_behind.reload.assignee).to be_nil
  end

  it 'returns the clients to the new queue when the number is left without a freelancer' do
    create(:inbox_member, inbox: number, user: freelancer)
    client = create(:conversation, account: account, inbox: number, assignee: freelancer)

    patch "#{numbers_path}/#{number.id}", params: { freelancer_id: nil }, headers: manager.create_new_auth_token, as: :json

    expect(client.reload.assignee).to be_nil
  end

  it 'creates number inboxes without auto-assignment, so a manager qualifies new clients first' do
    evolution_channel = Channel::Api.create!(account: account, webhook_url: "#{evolution_url}/chatwoot/webhook/number-b")

    inbox = Inbox.create!(account: account, channel: evolution_channel, name: 'Number B')

    expect(inbox.enable_auto_assignment).to be(false)
    expect(create(:inbox, account: account).enable_auto_assignment).to be(true)
  end

  it 'refuses to assign a number to someone who is not a freelancer' do
    patch "#{numbers_path}/#{number.id}", params: { freelancer_id: manager.id }, headers: manager.create_new_auth_token, as: :json

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body['error']).to eq('not_freelancer')
  end

  it 'restarts the connection of a number without a QR code' do
    restart = stub_request(:post, "#{evolution_url}/instance/restart/number-a").to_return(status: 200, body: '{}', headers: headers)

    post "#{numbers_path}/#{number.id}/restart", headers: manager.create_new_auth_token, as: :json

    expect(restart).to have_been_made
  end

  it 'shows in the chat whether its number is connected' do
    chat = create(:conversation, account: account, inbox: number)
    state_url = "#{evolution_url}/instance/connectionState/number-a"
    stub_request(:get, state_url).to_return(status: 200, body: { instance: { state: 'close' } }.to_json, headers: headers)

    get "/api/v1/accounts/#{account.id}/crm/chats/#{chat.display_id}", headers: manager.create_new_auth_token, as: :json
    expect(response.parsed_body['number_state']).to eq('close')

    stub_request(:get, state_url).to_return(status: 502, body: 'Bad Gateway')
    get "/api/v1/accounts/#{account.id}/crm/chats/#{chat.display_id}", headers: manager.create_new_auth_token, as: :json
    expect(response.parsed_body['number_state']).to eq('unknown')
  end

  it 'disconnects a number in Evolution' do
    logout = stub_request(:delete, "#{evolution_url}/instance/logout/number-a").to_return(status: 200, body: '{}', headers: headers)

    post "#{numbers_path}/#{number.id}/logout", headers: manager.create_new_auth_token, as: :json

    expect(logout).to have_been_made
  end

  it 'knows only Evolution numbers' do
    website = account.inboxes.find_by!(name: 'Website')

    get "#{numbers_path}/#{website.id}/state", headers: manager.create_new_auth_token, as: :json

    expect(response).to have_http_status(:not_found)
  end
end
