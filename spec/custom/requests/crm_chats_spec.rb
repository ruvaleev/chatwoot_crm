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

  it 'lists the chats waiting for an answer, the longest wait first' do
    second = create(:conversation, account: account, inbox: inbox, assignee: freelancer)
    own.update!(waiting_since: 5.minutes.ago)
    second.update!(waiting_since: 20.minutes.ago)
    create(:conversation, account: account, inbox: inbox, assignee: freelancer).update!(waiting_since: nil)

    get chats_path, params: { filter: 'waiting' }, headers: freelancer.create_new_auth_token

    expect(response.parsed_body['payload'].pluck('id')).to eq([second.display_id, own.display_id])
    expect(response.parsed_body.dig('meta', 'waiting_count')).to eq(2)
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
end
