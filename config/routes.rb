require 'sidekiq/web'

Rails.application.routes.draw do
  root to: 'shops#index'

  resources :shops do
    resources :trackings
  end

  resources :trackings

  mount Sidekiq::Web => '/sidekiq'
end
