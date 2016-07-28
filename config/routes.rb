Rails.application.routes.draw do
  get 'caniuse/slash'

  get 'home/index'

  post 'frink/slash'
  get  'frink/auth', as: 'frink_auth'

  post 'caniuse/slash'
  get  'caniuse/auth', as: 'caniuse_auth'

  post 'weather/slash'
  get  'weather/auth', as: 'weather_auth'

  post 'citibike/slash'
  get  'citibike/auth', as: 'citibike_auth'

  post 'cabi/slash' => 'capital_bikeshare#slash'
  get  'cabi/auth'  => 'capital_bikeshare#auth', as: 'cabi_auth'

  post 'untappd/slash'
  get  'untappd/auth', as: 'untappd_auth'

  root 'home#index'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
