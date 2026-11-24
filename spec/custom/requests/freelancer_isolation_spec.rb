require 'rails_helper'

RSpec.describe 'Freelancer isolation', type: :request do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:freelancer) { create(:user, account: account, role: :agent, custom_attributes: { crm_freelancer: true }) }
  let(:manager) { create(:user, account: account, role: :agent) }
  let!(:own) { create(:conversation, account: account, inbox: inbox, assignee: freelancer) }
  let!(:foreign) { create(:conversation, account: account, inbox: inbox, assignee: manager) }
  let!(:unassigned) { create(:conversation, account: account, inbox: inbox) }
  let(:conversations_path) { "/api/v1/accounts/#{account.id}/conversations" }

  before do
    create(:inbox_member, inbox: inbox, user: freelancer)
    create(:inbox_member, inbox: inbox, user: manager)
  end

  it 'lists only conversations assigned to the freelancer' do
    get conversations_path, params: { assignee_type: 'all' }, headers: freelancer.create_new_auth_token, as: :json

    expect(response.parsed_body.dig('data', 'payload').pluck('id')).to eq([own.display_id])
    expect(response.parsed_body.dig('data', 'meta')).to include('all_count' => 1, 'unassigned_count' => 0)
  end

  it 'keeps the upstream inbox-wide view for other agents' do
    get conversations_path, params: { assignee_type: 'all' }, headers: manager.create_new_auth_token, as: :json

    expect(response.parsed_body.dig('data', 'payload').pluck('id'))
      .to contain_exactly(own.display_id, foreign.display_id, unassigned.display_id)
  end

  it 'filters only within assigned conversations' do
    filter = [{ attribute_key: 'status', filter_operator: 'equal_to', values: ['open'], query_operator: nil }]
    post "#{conversations_path}/filter", params: { payload: filter }, headers: freelancer.create_new_auth_token, as: :json

    expect(response.parsed_body['payload'].pluck('id')).to eq([own.display_id])
  end

  it 'denies opening conversations not assigned to the freelancer' do
    [foreign, unassigned].each do |conversation|
      get "#{conversations_path}/#{conversation.display_id}", headers: freelancer.create_new_auth_token, as: :json
      expect(response).to have_http_status(:unauthorized)

      get "#{conversations_path}/#{conversation.display_id}/messages", headers: freelancer.create_new_auth_token, as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    get "#{conversations_path}/#{own.display_id}", headers: freelancer.create_new_auth_token, as: :json
    expect(response).to have_http_status(:success)
  end

  it 'revokes access once the conversation is reassigned' do
    own.update!(assignee: manager)

    get "#{conversations_path}/#{own.display_id}", headers: freelancer.create_new_auth_token, as: :json

    expect(response).to have_http_status(:unauthorized)
  end

  it 'searches only assigned conversations and their messages' do
    [own, foreign, unassigned].each do |conversation|
      create(:message, account: account, inbox: inbox, conversation: conversation, content: 'crm needle')
    end

    get "/api/v1/accounts/#{account.id}/search/conversations", params: { q: '' }, headers: freelancer.create_new_auth_token, as: :json
    expect(response.parsed_body.dig('payload', 'conversations').pluck('id')).to eq([own.display_id])

    get "/api/v1/accounts/#{account.id}/search/messages", params: { q: 'needle' }, headers: freelancer.create_new_auth_token, as: :json
    expect(response.parsed_body.dig('payload', 'messages').pluck('conversation_id')).to eq([own.display_id])
  end

  it 'shows only contacts of assigned conversations' do
    contacts_path = "/api/v1/accounts/#{account.id}/contacts"

    get contacts_path, headers: freelancer.create_new_auth_token, as: :json
    expect(response.parsed_body['payload'].pluck('id')).to eq([own.contact_id])

    get "#{contacts_path}/search", params: { q: foreign.contact.name }, headers: freelancer.create_new_auth_token, as: :json
    expect(response.parsed_body['payload']).to be_empty

    get "/api/v1/accounts/#{account.id}/search/contacts", params: { q: '' }, headers: freelancer.create_new_auth_token, as: :json
    expect(response.parsed_body.dig('payload', 'contacts').pluck('id')).to eq([own.contact_id])
  end

  it 'denies contacts and their nested resources outside assigned conversations' do
    contact_path = "/api/v1/accounts/#{account.id}/contacts/#{foreign.contact_id}"

    %w[/ /notes /labels /conversations].each do |suffix|
      get "#{contact_path}#{suffix.delete_suffix('/')}", headers: freelancer.create_new_auth_token, as: :json
      expect(response).to have_http_status(:not_found)
    end

    get "/api/v1/accounts/#{account.id}/contacts/#{own.contact_id}/notes", headers: freelancer.create_new_auth_token, as: :json
    expect(response).to have_http_status(:success)
  end

  it 'keeps all contacts visible to other agents' do
    get "/api/v1/accounts/#{account.id}/contacts", headers: manager.create_new_auth_token, as: :json

    expect(response.parsed_body['payload'].pluck('id')).to contain_exactly(own.contact_id, foreign.contact_id, unassigned.contact_id)
  end

  describe 'starting a conversation' do
    let(:message) { { content: 'crm hello' } }

    it 'starts a conversation for themselves with a client they see' do
      expect do
        post conversations_path, params: { inbox_id: inbox.id, contact_id: own.contact_id, assignee_id: freelancer.id, message: message },
                                 headers: freelancer.create_new_auth_token, as: :json
      end.to change(Conversation, :count).by(1)

      expect(response).to have_http_status(:success)
    end

    it 'denies starting a conversation with a client of other conversations' do
      expect do
        post conversations_path, params: { inbox_id: inbox.id, contact_id: foreign.contact_id, assignee_id: freelancer.id, message: message },
                                 headers: freelancer.create_new_auth_token, as: :json
        post conversations_path, params: { inbox_id: inbox.id, source_id: foreign.contact_inbox.source_id, assignee_id: freelancer.id },
                                 headers: freelancer.create_new_auth_token, as: :json
      end.not_to change(ContactInbox, :count)

      expect(response).to have_http_status(:not_found)
      expect(foreign.contact.conversations.count).to eq(1)
    end

    it 'denies a conversation that would not be assigned to the freelancer' do
      expect do
        post conversations_path, params: { inbox_id: inbox.id, contact_id: own.contact_id, message: message },
                                 headers: freelancer.create_new_auth_token, as: :json
      end.not_to change(Message, :count)

      expect(response).to have_http_status(:not_found)
      expect(own.contact.conversations.count).to eq(1)
    end
  end

  describe 'client phone number' do
    let(:contact_path) { "/api/v1/accounts/#{account.id}/contacts/#{own.contact_id}" }

    before { own.contact.update!(name: '+15550104477', phone_number: '+15550104477', identifier: '15550104477@s.whatsapp.net') }

    it 'is hidden from the freelancer in contacts and conversations' do
      get contact_path, headers: freelancer.create_new_auth_token, as: :json
      expect(response.parsed_body['payload']).to include('name' => 'Client •••77', 'phone_number' => nil, 'identifier' => nil)

      get conversations_path, headers: freelancer.create_new_auth_token, as: :json
      expect(response.parsed_body.dig('data', 'payload', 0, 'meta', 'sender')).to include('phone_number' => nil, 'identifier' => nil)
      expect(response.body).not_to include('15550104477')
    end

    it 'stays visible to other agents' do
      get contact_path, headers: manager.create_new_auth_token, as: :json

      expect(response.parsed_body['payload']).to include('phone_number' => '+15550104477')
    end

    it 'cannot be found by the freelancer through search, not even by a few digits' do
      %w[550104 4477].each do |digits|
        get "/api/v1/accounts/#{account.id}/contacts/search", params: { q: digits }, headers: freelancer.create_new_auth_token, as: :json
        expect(response.parsed_body['payload']).to be_empty

        get "/api/v1/accounts/#{account.id}/search", params: { q: digits }, headers: freelancer.create_new_auth_token, as: :json
        expect(response.parsed_body['payload']).to include('contacts' => [], 'conversations' => [])
      end

      filter = [{ attribute_key: 'phone_number', filter_operator: 'contains', values: ['555'], query_operator: nil }]
      post "/api/v1/accounts/#{account.id}/contacts/filter", params: { payload: filter }, headers: freelancer.create_new_auth_token, as: :json
      expect(response.parsed_body['payload']).to be_empty
    end

    it 'is not overwritten when the freelancer saves the contact form' do
      patch contact_path, params: { name: 'Client •••77', phone_number: '', identifier: '', email: 'anna@example.com' },
                          headers: freelancer.create_new_auth_token, as: :json

      expect(own.contact.reload).to have_attributes(name: '+15550104477', phone_number: '+15550104477',
                                                    identifier: '15550104477@s.whatsapp.net', email: 'anna@example.com')
    end
  end

  it 'does not notify the freelancer about conversations they cannot open' do
    NotificationBuilder.new(notification_type: 'conversation_mention', user: freelancer, account: account, primary_actor: foreign).perform

    expect(freelancer.notifications).to be_empty
  end

  it 'hides notifications of conversations reassigned away from the freelancer' do
    create(:notification, user: freelancer, account: account, primary_actor: own, notification_type: 'conversation_assignment')
    own.update!(assignee: manager)
    create(:message, account: account, inbox: inbox, conversation: own, content: 'crm after reassignment')

    get "/api/v1/accounts/#{account.id}/notifications", headers: freelancer.create_new_auth_token, as: :json

    expect(response.parsed_body.dig('data', 'payload')).to be_empty
    expect(response.parsed_body.dig('data', 'meta')).to include('count' => 0, 'unread_count' => 0)
  end

  it 'denies merging a client of other conversations' do
    post "/api/v1/accounts/#{account.id}/actions/contact_merge", params: { base_contact_id: own.contact_id, mergee_contact_id: foreign.contact_id },
                                                                 headers: freelancer.create_new_auth_token, as: :json

    expect(response).to have_http_status(:not_found)
    expect(foreign.reload.contact).to be_present
  end

  it 'denies companies, which list and search all contacts of the account' do
    account.enable_features!('companies')
    company = create(:company, account: account)
    foreign.contact.update!(company: company)

    get "/api/v1/accounts/#{account.id}/companies/#{company.id}/contacts", headers: freelancer.create_new_auth_token, as: :json
    expect(response).to have_http_status(:unauthorized)

    get "/api/v1/accounts/#{account.id}/companies", headers: freelancer.create_new_auth_token, as: :json
    expect(response).to have_http_status(:unauthorized)

    get "/api/v1/accounts/#{account.id}/companies/#{company.id}/contacts", headers: manager.create_new_auth_token, as: :json
    expect(response).to have_http_status(:success)
  end

  it 'turns the companies feature off in the account the freelancer dashboard loads' do
    account.enable_features!('companies')

    get "/api/v1/accounts/#{account.id}", headers: freelancer.create_new_auth_token, as: :json
    expect(response.parsed_body['features']).not_to have_key('companies')

    get "/api/v1/accounts/#{account.id}", headers: manager.create_new_auth_token, as: :json
    expect(response.parsed_body['features']).to include('companies' => true)
  end

  it 'labels in bulk only contacts the freelancer sees' do
    params = { type: 'Contact', ids: [own.contact_id, foreign.contact_id], labels: { add: ['crm-vip'] } }

    perform_enqueued_jobs do
      post "/api/v1/accounts/#{account.id}/bulk_actions", params: params, headers: freelancer.create_new_auth_token, as: :json
    end

    expect(response).to have_http_status(:success)
    expect(own.contact.reload.label_list).to eq(['crm-vip'])
    expect(foreign.contact.reload.label_list).to be_empty
  end
end
