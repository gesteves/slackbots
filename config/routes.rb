Rails.application.routes.draw do
  get  'frink/index'
  post 'frink/slash'
  get  'frink/auth', as: 'frink_auth'

  get  'weather/index'
  post 'weather/slash'
  get  'weather/auth', as: 'weather_auth'

  post 'cabi/slash' => 'capital_bikeshare#slash'
  get  'cabi/auth'   => 'capital_bikeshare#auth', as: 'cabi_auth'
  get  'cabi'        => 'capital_bikeshare#index'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
