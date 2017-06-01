Rails.application.routes.draw do

  post 'polly/slash'
  get 'polly/auth', as: 'polly_auth'

  get 'caniuse/slash'

  get 'home/index'

  post 'frink/slash'
  get  'frink/auth', as: 'frink_auth'

  post 'morbo/slash'
  get  'morbo/auth', as: 'morbo_auth'

  post 'caniuse/slash'
  get  'caniuse/auth', as: 'caniuse_auth'

  post 'weather/slash'
  get  'weather/alexa'
  get  'weather/auth', as: 'weather_auth'

  post 'citibike/slash'
  get  'citibike/auth', as: 'citibike_auth'

  post 'cabi/slash' => 'capital_bikeshare#slash'
  get  'cabi/auth'  => 'capital_bikeshare#auth', as: 'cabi_auth'

  post 'beer/slash'
  get  'beer/auth', as: 'beer_auth'

  post 'metro/slash'
  get  'metro/flash_briefing'
  get  'metro/auth', as: 'metro_auth'

  post 'link/slash'
  get  'link/auth', as: 'link_auth'

  post 'memefier/memefy'
  get  'memefier/memefy'
  post 'memefier/palette'
  get  'memefier/auth', as: 'memefier_auth'

  post 'custom/:action', controller: 'custom'

  root 'home#index'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
