require 'rails_helper'

RSpec.describe 'CRM chats API', type: :request do
  let(:account) { create(:account, locale: 'ru') }
  let(:inbox) { create(:inbox, account: account) }
  let(:freelancer) { create(:user, account: account, role: :agent, custom_attributes: { crm_freelancer: true }) }
  let(:manager) { create(:user, account: account, role: :agent) }
  let!(:own) { create(:conversation, account: account, inbox: inbox, assignee: freelancer) }
  let!(:foreign) { create(:conversation, account: account, inbox: inbox, assignee: manager) }
  let(:chats_path) { "/api/v1/accounts/#{account.id}/crm/chats" }

  before do
    create(:inbox_member, inbox: inbox, user: freelancer)
    create(:inbox_member, inbox: inbox, user: manager)
  end

  it 'lists only the freelancer chats with the last message and the client name' do
    create(:message, account: account, inbox: inbox, conversation: own, message_type: :incoming, content: 'crm hello')

    get chats_path, headers: freelancer.create_new_auth_token, as: :json

    expect(response.parsed_body['payload'].pluck('id')).to eq([own.display_id])
    expect(response.parsed_body.dig('payload', 0, 'last_message')).to include('content' => 'crm hello', 'incoming' => true)
    expect(response.parsed_body.dig('payload', 0, 'contact', 'name')).to eq(own.contact.name)
  end

  it 'lists every chat of the inbox for other agents' do
    get chats_path, headers: manager.create_new_auth_token, as: :json

    expect(response.parsed_body['payload'].pluck('id')).to contain_exactly(own.display_id, foreign.display_id)
  end

  it 'masks a client named after their number for the freelancer' do
    own.contact.update!(name: '+15550104477', phone_number: '+15550104477')

    get chats_path, headers: freelancer.create_new_auth_token, as: :json

    expect(response.parsed_body.dig('payload', 0, 'contact', 'name')).to eq('Клиент •••77')
    expect(response.body).not_to include('15550104477')
  end

  describe 'order' do
    let!(:second) { create(:conversation, account: account, inbox: inbox, assignee: freelancer) }
    let!(:answered) { create(:conversation, account: account, inbox: inbox, assignee: freelancer) }

    before do
      own.update!(waiting_since: 5.minutes.ago, last_activity_at: 1.minute.ago)
      second.update!(waiting_since: 20.minutes.ago, last_activity_at: 10.minutes.ago)
      answered.update!(waiting_since: nil, last_activity_at: 30.seconds.ago)
    end

    it 'lists the latest message first, like a messenger' do
      get chats_path, headers: freelancer.create_new_auth_token, as: :json
      expect(response.parsed_body['payload'].pluck('id')).to eq([answered.display_id, own.display_id, second.display_id])

      get chats_path, params: { filter: 'waiting' }, headers: freelancer.create_new_auth_token
      expect(response.parsed_body['payload'].pluck('id')).to eq([own.display_id, second.display_id])
      expect(response.parsed_body.dig('meta', 'waiting_count')).to eq(2)
    end

    it 'puts the longest wait first on request' do
      get chats_path, params: { sort: 'waiting' }, headers: freelancer.create_new_auth_token

      expect(response.parsed_body['payload'].pluck('id')).to eq([second.display_id, own.display_id, answered.display_id])
    end

    it 'rejects an unknown order' do
      get chats_path, params: { sort: 'random' }, headers: freelancer.create_new_auth_token

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  it 'hides a chat from the own list only and brings it back' do
    post "#{chats_path}/#{own.display_id}/hide", headers: freelancer.create_new_auth_token, as: :json

    get chats_path, headers: freelancer.create_new_auth_token, as: :json
    expect(response.parsed_body['payload']).to be_empty
    expect(response.parsed_body.dig('meta', 'hidden_count')).to eq(1)

    get chats_path, params: { filter: 'hidden' }, headers: freelancer.create_new_auth_token
    expect(response.parsed_body['payload'].pluck('id')).to eq([own.display_id])

    get chats_path, headers: manager.create_new_auth_token, as: :json
    expect(response.parsed_body['payload'].pluck('id')).to include(own.display_id)

    delete "#{chats_path}/#{own.display_id}/hide", headers: freelancer.create_new_auth_token, as: :json
    get chats_path, headers: freelancer.create_new_auth_token, as: :json
    expect(response.parsed_body['payload'].pluck('id')).to eq([own.display_id])
  end

  it 'brings a hidden chat back when the client writes again' do
    Custom::HiddenConversation.create!(user: freelancer, conversation: own)

    perform_enqueued_jobs { create(:message, account: account, inbox: inbox, conversation: own, message_type: :incoming) }

    expect(Custom::HiddenConversation.where(conversation: own)).to be_empty
  end

  it 'rejects an unknown filter' do
    get chats_path, params: { filter: 'everything' }, headers: freelancer.create_new_auth_token

    expect(response).to have_http_status(:unprocessable_content)
  end

  it 'denies chats of other conversations' do
    get "#{chats_path}/#{foreign.display_id}", headers: freelancer.create_new_auth_token, as: :json
    expect(response).to have_http_status(:not_found)

    post "#{chats_path}/#{foreign.display_id}/hide", headers: freelancer.create_new_auth_token, as: :json
    expect(response).to have_http_status(:not_found)
  end

  it 'shows the chat with its deal and the manager brief' do
    brief = create(:message, account: account, inbox: inbox, conversation: own, private: true, content: 'crm brief', sender: manager)
    own.update!(custom_attributes: { 'crm_status' => 'handed_off', 'crm_budget' => '1000', 'crm_brief_message_id' => brief.id })

    get "#{chats_path}/#{own.display_id}", headers: freelancer.create_new_auth_token, as: :json

    expect(response.parsed_body).to include('status' => 'handed_off', 'hidden' => false)
    expect(response.parsed_body['deal']).to include('budget' => '1000')
    expect(response.parsed_body['brief']).to include('content' => 'crm brief', 'author' => manager.name)
  end

  it 'lets the freelancer move the deal only within their statuses' do
    patch "#{chats_path}/#{own.display_id}", params: { status: 'won', deal_amount: '500' }, headers: freelancer.create_new_auth_token, as: :json
    expect(response.parsed_body).to include('status' => 'won')
    expect(own.reload.custom_attributes).to include('crm_status' => 'won', 'crm_deal_amount' => '500')

    patch "#{chats_path}/#{own.display_id}", params: { status: 'qualifying' }, headers: freelancer.create_new_auth_token, as: :json
    expect(response).to have_http_status(:unprocessable_content)
    expect(own.reload.crm_status).to eq('won')
  end

  it 'rejects an unknown status from other agents' do
    patch "#{chats_path}/#{own.display_id}", params: { status: 'archived' }, headers: manager.create_new_auth_token, as: :json

    expect(response).to have_http_status(:unprocessable_content)
  end

  describe 'manager tabs, filters and search' do
    let(:other_inbox) { create(:inbox, account: account, name: 'Number B') }
    let!(:unassigned) { create(:conversation, account: account, inbox: inbox) }

    before { create(:inbox_member, inbox: other_inbox, user: manager) }

    it 'lists new, own and per-number chats with counters' do
      elsewhere = create(:conversation, account: account, inbox: other_inbox, assignee: manager)

      get chats_path, params: { filter: 'new' }, headers: manager.create_new_auth_token
      expect(response.parsed_body['payload'].pluck('id')).to eq([unassigned.display_id])
      expect(response.parsed_body['meta']).to include('new_count' => 1, 'mine_count' => 2)
      expect(response.parsed_body.dig('meta', 'inboxes').pluck('name')).to include('Number B')

      get chats_path, params: { filter: 'mine', inbox_id: other_inbox.id }, headers: manager.create_new_auth_token
      expect(response.parsed_body['payload'].pluck('id')).to eq([elsewhere.display_id])
    end

    it 'filters by deal status, chats without one being new' do
      own.update!(custom_attributes: { 'crm_status' => 'won' })

      get chats_path, params: { status: 'won' }, headers: manager.create_new_auth_token
      expect(response.parsed_body['payload'].pluck('id')).to eq([own.display_id])

      get chats_path, params: { status: 'new' }, headers: manager.create_new_auth_token
      expect(response.parsed_body['payload'].pluck('id')).to contain_exactly(foreign.display_id, unassigned.display_id)

      get chats_path, params: { status: 'archived' }, headers: manager.create_new_auth_token
      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'searches names, phones and messages for managers' do
      unassigned.contact.update!(name: 'Crm Olga', phone_number: '+15550104477')
      create(:message, account: account, inbox: inbox, conversation: foreign, content: 'crm needle')

      { 'olga' => unassigned, '0104477' => unassigned, 'needle' => foreign }.each do |query, chat|
        get chats_path, params: { q: query }, headers: manager.create_new_auth_token
        expect(response.parsed_body['payload'].pluck('id')).to eq([chat.display_id])
      end
    end

    it 'never finds a client by phone for the freelancer' do
      own.contact.update!(name: 'Crm Olga', phone_number: '+15550104477')

      get chats_path, params: { q: '0104477' }, headers: freelancer.create_new_auth_token
      expect(response.parsed_body['payload']).to be_empty

      get chats_path, params: { q: 'olga' }, headers: freelancer.create_new_auth_token
      expect(response.parsed_body['payload'].pluck('id')).to eq([own.display_id])
    end
  end

  describe 'hand-off' do
    let!(:incoming) { create(:conversation, account: account, inbox: inbox) }

    it 'assigns the number freelancer with a pinned brief' do
      post "#{chats_path}/#{incoming.display_id}/handoff", params: { brief: 'crm wants a kitchen' },
                                                           headers: manager.create_new_auth_token, as: :json

      expect(response.parsed_body).to include('status' => 'handed_off')
      expect(response.parsed_body.dig('inbox', 'freelancer', 'id')).to eq(freelancer.id)
      expect(incoming.reload.assignee).to eq(freelancer)
      expect(incoming.crm_brief).to have_attributes(content: 'crm wants a kitchen', private: true, sender: manager)

      get "#{chats_path}/#{incoming.display_id}", headers: freelancer.create_new_auth_token, as: :json
      expect(response.parsed_body['brief']).to include('content' => 'crm wants a kitchen')
    end

    it 'shows the client phone to managers only' do
      incoming.contact.update!(phone_number: '+15550104477')

      get "#{chats_path}/#{incoming.display_id}", headers: manager.create_new_auth_token, as: :json
      expect(response.parsed_body['phone_number']).to eq('+15550104477')
    end

    it 'is not available to freelancers' do
      post "#{chats_path}/#{own.display_id}/handoff", params: { brief: 'crm' }, headers: freelancer.create_new_auth_token, as: :json

      expect(response).to have_http_status(:forbidden)
    end

    it 'needs a freelancer on the number' do
      bare_inbox = create(:inbox, account: account)
      create(:inbox_member, inbox: bare_inbox, user: manager)
      chat = create(:conversation, account: account, inbox: bare_inbox)

      post "#{chats_path}/#{chat.display_id}/handoff", params: { brief: 'crm' }, headers: manager.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(chat.reload.assignee).to be_nil
    end
  end

  it 'leaves Evolution service chat out of the lists and counters' do
    service_contact = create(:contact, account: account, name: 'WhatsApp', phone_number: '+123456')
    service = create(:conversation, account: account, inbox: inbox, contact: service_contact)

    get chats_path, headers: manager.create_new_auth_token, as: :json

    expect(response.parsed_body['payload'].pluck('id')).not_to include(service.display_id)
    expect(response.parsed_body.dig('meta', 'new_count')).to eq(0)
  end
end
