# config/routes.rb
Rails.application.routes.draw do
  root 'shifts#index'

  # 認証
  get    'login',  to: 'sessions#new'
  post   'login',  to: 'sessions#create'
  delete 'logout', to: 'sessions#destroy'

  resources :shifts, only: [:index] do
    collection do
      get :weekly
      get :monthly
      get :suggestions
    end
  end

  # 応援要請
  resources :support_requests, only: [:index, :create] do
    member do
      post :approve
      post :reject
    end
  end

  resources :stores do
    resource :operating_hours, only: [:edit, :update],
             controller: 'store_operating_hours'
  end
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
