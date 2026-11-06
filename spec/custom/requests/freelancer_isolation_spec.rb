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

  it 'does not notify the freelancer about conversations they cannot open' do
    NotificationBuilder.new(notification_type: 'conversation_mention', user: freelancer, account: account, primary_actor: foreign).perform

    expect(freelancer.notifications).to be_empty
  end
end
