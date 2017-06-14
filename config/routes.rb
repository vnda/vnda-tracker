require 'sidekiq/web'

Rails.application.routes.draw do
  root to: 'shops#index'

  resources :shops do
    resources :trackings do
      get :refresh
    end
  end

  resources :trackings

  get  ':token/search/:code', to: 'search#show', defaults: { format: 'json' }
  post 'intelipost/receive_hook', to: 'intelipost#receive_hook'

  mount Sidekiq::Web => '/sidekiq'
end
