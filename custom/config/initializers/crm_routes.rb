# Routes of the new interface (crm/PRD.md, stage D), appended so config/routes.rb stays untouched.
Rails.application.routes.append do
  get '/crm', to: 'custom/crm#index', as: :crm
  get '/crm/*path', to: 'custom/crm#index', format: false

  scope 'api/v1/accounts/:account_id/crm', module: 'custom/api/v1/accounts/crm', as: :crm_api, defaults: { format: 'json' } do
    resources :chats, only: [:index, :show, :update] do
      member do
        post :hide
        post :handoff
        delete :hide, action: :unhide
      end
    end
  end
end
