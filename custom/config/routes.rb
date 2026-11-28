# Routes of the new interface (crm/PRD.md, stage D). Listed next to config/routes.rb (see
# custom/config/initializers/crm_routes.rb), so they reload in development like the main routes file.
Rails.application.routes.draw do
  # The token travels in the body (filtered from logs), never in a path.
  post '/api/v1/crm/invitation', to: 'custom/api/v1/crm/invitations#show', defaults: { format: 'json' }
  post '/api/v1/crm/invitation/accept', to: 'custom/api/v1/crm/invitations#accept', defaults: { format: 'json' }
  get '/crm', to: 'custom/crm#index', as: :crm
  get '/crm/*path', to: 'custom/crm#index', format: false

  scope 'api/v1/accounts/:account_id/crm', module: 'custom/api/v1/accounts/crm', as: :crm_api, defaults: { format: 'json' } do
    resources :chats, only: [:index, :show, :update] do
      member do
        post :hide
        post :handoff
        post :unassign
        delete :hide, action: :unhide
      end
    end
    resource :settings, only: [:show, :update]
    resource :schedule, only: [:show, :update]
    resource :push_subscription, only: [:create, :destroy]
    resources :templates, only: [:index, :create, :update, :destroy]
    resources :freelancers, only: [:index, :create, :update, :destroy] do
      post :invite, on: :member
    end
    resources :numbers, only: [:index, :create, :update] do
      member do
        post :connect
        post :restart
        get :state
        post :logout
      end
    end
  end
end
