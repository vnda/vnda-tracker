require 'sidekiq/web'

Rails.application.routes.draw do
  root to: 'shops#index'

  resources :shops do
    resources :trackings
  end

  resources :trackings
  get ':token/search/:code', to: 'search#show', defaults: { format: 'json' }

  mount Sidekiq::Web => '/sidekiq'
end
