Rails.application.routes.draw do
  resources :shops do
    resources :trackings
  end
end
