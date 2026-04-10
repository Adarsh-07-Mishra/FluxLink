Rails.application.routes.draw do
  root "home#index"
  post "/shorten", to: "home#shorten", as: :shorten

  get "/features", to: "home#features", as: :features
  get "/pricing", to: "home#pricing", as: :pricing
  get "/about", to: "home#about", as: :about
  get "/contact", to: "home#contact", as: :contact
  get "/documents", to: "home#documents", as: :documents
  get "/terms", to: "home#terms", as: :terms
  get "/privacy", to: "home#privacy", as: :privacy
  get "/agreement", to: "home#agreement", as: :agreement
  post "/agreement", to: "home#accept_agreement", as: :accept_agreement
  get "/wifi-qr", to: "home#wifi_qr", as: :wifi_qr
  get "/wifi-qr/:id", to: "home#wifi_qr", as: :wifi_qr_show
  post "/wifi-qr", to: "home#generate_wifi_qr", as: :generate_wifi_qr

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