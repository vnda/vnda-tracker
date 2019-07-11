# frozen_string_literal: true

require 'sidekiq/web'

Rails.application.routes.draw do
  root to: 'shops#index'

  resources :shops do
    resources :trackings do
      get :refresh
    end
  end

  resources :trackings

  get  ':token/search', to: 'search#show', defaults: { format: 'json' }
  get  ':token/search/:code', to: 'search#show', defaults: { format: 'json' }
  get  ':shop_name/:code', to: 'search#show'
  post 'intelipost/receive_hook', to: 'intelipost#create'

  mount Sidekiq::Web => '/sidekiq'
end
