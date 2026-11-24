require 'rails_helper'

RSpec.describe 'The new interface as the main one', type: :request do
  let(:account) { create(:account) }
  let(:freelancer) { create(:user, account: account, role: :agent, custom_attributes: { crm_freelancer: true }) }
  let(:manager) { create(:user, account: account, role: :administrator) }

  # The old dashboard page itself is not what is tested: skip building its assets.
  before do
    allow_any_instance_of(ActionView::Base).to receive(:vite_client_tag).and_return('') # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(ActionView::Base).to receive(:vite_javascript_tag).and_return('') # rubocop:disable RSpec/AnyInstance
  end

  def sign_in_cookie(user)
    cookies['cw_d_session_info'] = user.create_new_auth_token.to_json
  end

  it 'opens the new interface at the root' do
    get '/'

    expect(response).to redirect_to('/crm/')
  end

  it 'sends a signed-in freelancer from the old dashboard to the new one' do
    sign_in_cookie(freelancer)

    get '/app/accounts/1/dashboard'

    expect(response).to redirect_to('/crm/')
  end

  it 'keeps the old dashboard for managers and before sign-in' do
    sign_in_cookie(manager)
    get '/app/accounts/1/dashboard'
    expect(response).to have_http_status(:success)

    cookies.delete('cw_d_session_info')
    get '/app/login'
    expect(response).to have_http_status(:success)
  end

  it 'does not trust a forged cookie' do
    cookies['cw_d_session_info'] = { 'uid' => freelancer.uid, 'client' => 'x', 'access-token' => 'forged' }.to_json

    get '/app/accounts/1/dashboard'

    expect(response).to have_http_status(:success)
  end
end
