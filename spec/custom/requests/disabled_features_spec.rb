require 'rails_helper'

RSpec.describe 'Chatwoot features the CRM does not use', type: :request do
  let(:account) { create(:account) }
  let(:manager) { create(:user, account: account, role: :administrator) }
  let(:auth) { manager.create_new_auth_token }

  it 'answers 404 for their account API, whoever asks' do
    %W[/api/v1/accounts/#{account.id}/campaigns /api/v1/accounts/#{account.id}/portals /api/v1/accounts/#{account.id}/macros
       /api/v1/accounts/#{account.id}/integrations/apps /api/v2/accounts/#{account.id}/reports/summary].each do |path|
      get path, headers: auth

      expect(response).to have_http_status(:not_found), path
    end
  end

  it 'answers 404 for the help center, the website widget, surveys and other channels' do
    portal = create(:portal, account: account, slug: 'docs')
    ["/hc/#{portal.slug}/en", '/api/v1/widget/config', '/survey/responses/1', '/webhooks/telegram/1', '/platform/api/v1/users/1'].each do |path|
      get path

      expect(response).to have_http_status(:not_found), path
    end
  end

  it 'answers 404 however the path is written' do
    ['/api//v1/widget/config', '/installation//onboarding', '/platform/api/v1//users/1', '/hc/docs/'].each do |path|
      get path

      expect(response).to have_http_status(:not_found), path
    end
  end

  it 'keeps what the new interface and Evolution use' do
    %W[/api/v1/accounts/#{account.id}/conversations /api/v1/accounts/#{account.id}/contacts /api/v1/accounts/#{account.id}/inboxes
       /api/v1/accounts/#{account.id}/canned_responses /api/v1/accounts/#{account.id}/labels /api/v1/profile].each do |path|
      get path, headers: auth

      expect(response).to have_http_status(:ok), path
    end
  end

  it 'lets them through for the full upstream suite' do
    with_modified_env CRM_BLOCK_UNUSED_FEATURES: 'false' do
      get "/api/v1/accounts/#{account.id}/campaigns", headers: auth
    end

    expect(response).to have_http_status(:ok)
  end

  it 'gives a new account only the CRM features, and rake crm:features the existing ones' do
    expect(account.enabled_features.keys).to match_array(Custom::Features::BASE)

    account.enable_features!('reports')
    account.crm_limit_features!

    expect(account.reload.enabled_features.keys).to match_array(Custom::Features::BASE)
  end

  it 'turns on more features with CRM_EXTRA_FEATURES, their API included' do
    with_modified_env CRM_EXTRA_FEATURES: 'reports, macros' do
      account.crm_limit_features!
      get "/api/v1/accounts/#{account.id}/macros", headers: auth

      expect(response).to have_http_status(:ok)
      expect(account.reload.enabled_features.keys).to include('reports', 'macros')
    end
  end

  it 'fails on a feature name it does not know' do
    with_modified_env CRM_EXTRA_FEATURES: 'reprots' do
      expect { Custom::Features.enabled }.to raise_error(ArgumentError, /reprots/)
    end
  end
end
