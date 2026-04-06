Rails.application.routes.draw do
  root "home#index"
  post "/shorten", to: "home#shorten", as: :shorten

  get "/features", to: "home#features", as: :features
  get "/pricing", to: "home#pricing", as: :pricing
  get "/about", to: "home#about", as: :about
  get "/contact", to: "home#contact", as: :contact

  get "/signup", to: "users#new", as: :signup
  post "/signup", to: "users#create"

  get "/login", to: "sessions#new", as: :login
  post "/login", to: "sessions#create"
  delete "/logout", to: "sessions#destroy", as: :logout

  resources :links do
    member do
      patch :update_qr
      patch :toggle_active
    end
  end

  # Handle manifest (prevents conflict)
  get '/manifest.json', to: proc { [204, {}, ['']] }

  # Password unlock
  post '/:short_code/unlock', to: 'links#unlock', as: :unlock

  get '/:short_code',
  to: 'links#redirect',
  as: :short,
  constraints: {
    short_code: /[a-zA-Z0-9]{6}/   # 👈 EXACT length
  }
end