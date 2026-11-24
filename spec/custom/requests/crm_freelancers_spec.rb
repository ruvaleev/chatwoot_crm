require 'rails_helper'

RSpec.describe 'CRM freelancers and invitations', type: :request do
  let(:account) { create(:account) }
  let(:manager) { create(:user, account: account, role: :administrator) }
  let(:channel) { create(:channel_api, account: account, webhook_url: 'http://evolution.test/chatwoot/webhook/number-a') }
  let!(:number) { channel.inbox.tap { |inbox| inbox.update!(name: 'Number A') } }
  let(:freelancers_path) { "/api/v1/accounts/#{account.id}/crm/freelancers" }
  let(:password) { 'Crm-Passw0rd!' }

  around do |example|
    with_modified_env(FRONTEND_URL: 'https://chat.example.test') { example.run }
  end

  describe 'managing freelancers' do
    it 'adds a freelancer on a number and returns a one-time sign-in link' do
      post freelancers_path, params: { name: 'Anna', login: 'anna.v', number_id: number.id }, headers: manager.create_new_auth_token, as: :json

      user = User.find_by!(email: 'anna.v@crm.invalid')
      expect(user).to have_attributes(name: 'Anna', crm_freelancer?: true)
      expect(account.account_users.find_by!(user: user)).to be_agent
      expect(number.reload.crm_freelancer).to eq(user)
      expect(response.parsed_body['invite_url']).to start_with('https://chat.example.test/crm/invite#')
      token = response.parsed_body['invite_url'].split('/crm/invite#').last
      expect(Custom::Invitation.find_by(token_digest: token)).to be_nil # only the digest is stored
      expect(Custom::Invitation.find_usable(token).user).to eq(user)
    end

    it 'lists freelancers with their number and clients' do
      freelancer = create(:user, account: account, role: :agent, custom_attributes: { crm_freelancer: true })
      create(:inbox_member, inbox: number, user: freelancer)
      create(:conversation, account: account, inbox: number, assignee: freelancer)

      get freelancers_path, headers: manager.create_new_auth_token, as: :json

      expect(response.parsed_body['payload']).to contain_exactly(
        include('id' => freelancer.id, 'number' => include('id' => number.id), 'clients_count' => 1)
      )
      expect(response.parsed_body['numbers']).to contain_exactly(include('id' => number.id, 'freelancer_id' => freelancer.id))
    end

    it 'rejects a malformed or taken login' do
      post freelancers_path, params: { name: 'Anna', login: 'Anna V' }, headers: manager.create_new_auth_token, as: :json
      expect(response).to have_http_status(:unprocessable_content)

      create(:user, email: 'anna.v@crm.invalid')
      post freelancers_path, params: { name: 'Anna', login: 'anna.v' }, headers: manager.create_new_auth_token, as: :json
      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'moves a freelancer to another number' do
      freelancer = create(:user, account: account, role: :agent, custom_attributes: { crm_freelancer: true })
      create(:inbox_member, inbox: number, user: freelancer)
      other = create(:channel_api, account: account, webhook_url: 'http://evolution.test/chatwoot/webhook/number-b').inbox

      patch "#{freelancers_path}/#{freelancer.id}", params: { number_id: other.id }, headers: manager.create_new_auth_token, as: :json

      expect(freelancer.reload.inboxes).to contain_exactly(other)
    end

    it 'takes the access away and returns the clients to the queue' do
      freelancer = create(:user, account: account, role: :agent, custom_attributes: { crm_freelancer: true })
      create(:inbox_member, inbox: number, user: freelancer)
      chat = create(:conversation, account: account, inbox: number, assignee: freelancer)
      session = freelancer.create_new_auth_token
      manager_session = manager.create_new_auth_token

      perform_enqueued_jobs do
        delete "#{freelancers_path}/#{freelancer.id}", headers: manager_session, as: :json
      end

      expect(account.account_users.find_by(user: freelancer)).to be_nil
      expect(chat.reload.assignee).to be_nil
      get '/api/v1/profile', headers: session, as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it 'is closed to freelancers' do
      freelancer = create(:user, account: account, role: :agent, custom_attributes: { crm_freelancer: true })

      get freelancers_path, headers: freelancer.create_new_auth_token, as: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'sign-in link' do
    let(:freelancer) { create(:user, account: account, role: :agent, name: 'Anna', email: 'anna.v@crm.invalid') }
    let(:token) { Custom::Invitation.issue!(freelancer) }

    it 'shows who it is for and sets the password once' do
      post '/api/v1/crm/invitation', params: { token: token }, as: :json
      expect(response.parsed_body).to eq('name' => 'Anna', 'login' => 'anna.v')

      post '/api/v1/crm/invitation/accept', params: { token: token, password: password, password_confirmation: password }, as: :json
      expect(response).to have_http_status(:success)
      expect(freelancer.reload.valid_password?(password)).to be(true)

      post '/api/v1/crm/invitation', params: { token: token }, as: :json
      expect(response).to have_http_status(:not_found)
    end

    it 'stops working after a day or when a new link is issued' do
      expired = token
      travel 25.hours do
        post '/api/v1/crm/invitation', params: { token: expired }, as: :json
        expect(response).to have_http_status(:not_found)
      end

      replaced = Custom::Invitation.issue!(freelancer)
      Custom::Invitation.issue!(freelancer)
      post '/api/v1/crm/invitation', params: { token: replaced }, as: :json
      expect(response).to have_http_status(:not_found)
    end

    it 'keeps the link usable after a weak password' do
      post '/api/v1/crm/invitation/accept', params: { token: token, password: 'short', password_confirmation: 'short' }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      post '/api/v1/crm/invitation', params: { token: token }, as: :json
      expect(response).to have_http_status(:success)
    end
  end
end
