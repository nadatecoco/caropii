Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # API routes
  resources :food_entries, only: [:create]
  get 'food_entries/today', to: 'food_entries#today'
  delete 'food_entries/clear_today', to: 'food_entries#clear_today'
  
  # 栄養分析API
  post 'food_entries/analyze_nutrition', to: 'food_entries#analyze_nutrition'

  # Defines the root path route ("/")
  # root "posts#index"
end
