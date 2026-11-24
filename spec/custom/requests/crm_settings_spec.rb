require 'rails_helper'

RSpec.describe 'CRM team settings and templates', type: :request do
  let(:account) { create(:account) }
  let(:manager) { create(:user, account: account, role: :administrator) }
  let(:freelancer) { create(:user, account: account, role: :agent, custom_attributes: { crm_freelancer: true }) }
  let(:settings_path) { "/api/v1/accounts/#{account.id}/crm/settings" }
  let(:templates_path) { "/api/v1/accounts/#{account.id}/crm/templates" }

  describe 'team settings' do
    it 'gives everyone the defaults until the team sets its own' do
      get settings_path, headers: freelancer.create_new_auth_token, as: :json

      expect(response.parsed_body).to include('overdue_minutes' => 10, 'overdue_minutes_off_hours' => 60, 'notification_locale' => 'ru')
    end

    it 'lets a manager change them' do
      patch settings_path, params: { overdue_minutes: 15, lost_reasons: ['Дорого'] }, headers: manager.create_new_auth_token, as: :json

      expect(response.parsed_body).to include('overdue_minutes' => 15)
      expect(account.reload.crm_settings).to include('lost_reasons' => ['Дорого'], 'overdue_minutes_off_hours' => 60)
    end

    it 'rejects settings that make no sense' do
      [{ overdue_minutes: 0 }, { overdue_minutes_off_hours: -5 }, { notification_locale: 'de' }].each do |change|
        patch settings_path, params: change, headers: manager.create_new_auth_token, as: :json
        expect(response).to have_http_status(:unprocessable_content)
      end
      expect(account.reload.custom_attributes).not_to have_key('crm_settings')
    end

    it 'is read-only for freelancers' do
      patch settings_path, params: { overdue_minutes: 1 }, headers: freelancer.create_new_auth_token, as: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'freelancer schedule' do
    let(:schedule_path) { "/api/v1/accounts/#{account.id}/crm/schedule" }
    let(:schedule) { { time_zone: 'Asia/Bangkok', days: [1, 2, 3, 4, 5], from: '10:00', to: '19:00' } }

    it 'is set by the freelancer and seen by managers on their chats and in the list' do
      inbox = create(:inbox, account: account)
      create(:inbox_member, inbox: inbox, user: freelancer)
      create(:conversation, account: account, inbox: inbox, assignee: freelancer)

      patch schedule_path, params: schedule, headers: freelancer.create_new_auth_token, as: :json
      expect(response.parsed_body['schedule']).to include('from' => '10:00', 'days' => [1, 2, 3, 4, 5])

      get "/api/v1/accounts/#{account.id}/crm/chats", headers: manager.create_new_auth_token, as: :json
      expect(response.parsed_body.dig('payload', 0, 'assignee', 'schedule')).to include('time_zone' => 'Asia/Bangkok')
      expect(response.parsed_body.dig('payload', 0, 'inbox', 'freelancer', 'schedule')).to include('to' => '19:00')
    end

    it 'rejects a schedule that makes no sense' do
      [{ time_zone: 'Mars/Base' }, { from: '25:00' }, { days: [8] }].each do |change|
        patch schedule_path, params: schedule.merge(change), headers: freelancer.create_new_auth_token, as: :json
        expect(response).to have_http_status(:unprocessable_content)
      end
      expect(freelancer.reload.crm_schedule).to be_nil
    end
  end

  describe 'templates' do
    let!(:team) { create(:canned_response, account: account, short_code: 'hello', content: 'Hi!') }

    it 'lists the team templates and the own ones' do
      Custom::Template.create!(user: freelancer, short_code: 'mine', content: 'My text')
      Custom::Template.create!(user: manager, short_code: 'other', content: 'Not yours')

      get templates_path, headers: freelancer.create_new_auth_token, as: :json

      expect(response.parsed_body['team'].pluck('short_code')).to eq(['hello'])
      expect(response.parsed_body['personal'].pluck('short_code')).to eq(['mine'])
    end

    it 'lets everyone keep their own templates' do
      post templates_path, params: { short_code: 'mine', content: 'My text' }, headers: freelancer.create_new_auth_token, as: :json
      template_id = response.parsed_body['id']

      patch "#{templates_path}/#{template_id}", params: { content: 'Better' }, headers: freelancer.create_new_auth_token, as: :json
      expect(freelancer.crm_templates.find(template_id).content).to eq('Better')

      delete "#{templates_path}/#{template_id}", headers: manager.create_new_auth_token, as: :json
      expect(response).to have_http_status(:not_found)

      delete "#{templates_path}/#{template_id}", headers: freelancer.create_new_auth_token, as: :json
      expect(freelancer.crm_templates).to be_empty
    end

    it 'leaves the team templates to managers' do
      path = "/api/v1/accounts/#{account.id}/canned_responses"

      post path, params: { canned_response: { short_code: 'bye', content: 'Bye' } }, headers: freelancer.create_new_auth_token, as: :json
      expect(response).to have_http_status(:forbidden)
      delete "#{path}/#{team.id}", headers: freelancer.create_new_auth_token, as: :json
      expect(response).to have_http_status(:forbidden)

      post path, params: { canned_response: { short_code: 'bye', content: 'Bye' } }, headers: manager.create_new_auth_token, as: :json
      expect(response).to have_http_status(:success)
    end
  end
end
