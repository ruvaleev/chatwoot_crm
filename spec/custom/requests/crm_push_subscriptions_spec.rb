require 'rails_helper'

RSpec.describe 'CRM push subscriptions API', type: :request do
  let(:account) { create(:account) }
  let(:freelancer) { create(:user, account: account, role: :agent, custom_attributes: { crm_freelancer: true }) }
  let(:manager) { create(:user, account: account, role: :administrator) }
  let(:path) { "/api/v1/accounts/#{account.id}/crm/push_subscription" }
  let(:device) { { endpoint: 'https://push.test/device-1', p256dh: 'key', auth: 'secret' } }

  it 'keeps one subscription per device, moving it to whoever signed in last' do
    post path, params: device, headers: freelancer.create_new_auth_token, as: :json
    post path, params: device, headers: manager.create_new_auth_token, as: :json

    expect(response).to have_http_status(:no_content)
    expect(NotificationSubscription.where(identifier: device[:endpoint]).pluck(:user_id)).to eq([manager.id])
  end

  it 'removes the device’s subscription on sign-out' do
    post path, params: device, headers: freelancer.create_new_auth_token, as: :json
    delete path, params: { endpoint: device[:endpoint] }, headers: freelancer.create_new_auth_token, as: :json

    expect(response).to have_http_status(:no_content)
    expect(freelancer.notification_subscriptions).to be_empty
  end

  it 'refuses a subscription without its keys' do
    post path, params: device.except(:auth), headers: freelancer.create_new_auth_token, as: :json

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body['error']).to eq('push_subscription_invalid')
  end
end
