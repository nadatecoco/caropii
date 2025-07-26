Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # API routes
  resources :food_entries, only: [:create]
  get 'food_entries/today', to: 'food_entries#today'
  
  # 健康データ分析API（統合）
  post 'health/analyze', to: 'health#analyze'
  
  # 旧API（互換性のため一時的に残す）
  post 'food_entries/analyze_nutrition', to: 'food_entries#analyze_nutrition'

  # Defines the root path route ("/")
  # root "posts#index"
end
