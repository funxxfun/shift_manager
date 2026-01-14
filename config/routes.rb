# config/routes.rb
Rails.application.routes.draw do
  root 'shifts#index'

  resources :shifts, only: [:index] do
    collection do
      get :weekly
      get :suggestions
      post :apply_suggestion
    end
  end

  resources :stores
  resources :staffs
  
  resources :imports, only: [:new, :create]

  # API
  namespace :api do
    namespace :v1 do
      resources :shifts, only: [:index]
      resources :suggestions, only: [:index]
    end
  end
end
