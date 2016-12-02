source 'https://rubygems.org'
ruby '2.3.1'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.0.0'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'

# Front-end
gem 'autoprefixer-rails'
gem 'turbolinks', '~> 5'
gem 'jquery-rails'
gem 'sass-rails', '~> 5.0'
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails', '~> 4.2'

# Caching
gem 'dalli'

# Things needed for the Slack apps
gem 'httparty'
gem 'text'
gem 'imgix'
gem 'gemoji'
gem 'aws-sdk'

# For Heroku
gem 'figaro'

# Tracking
gem 'mixpanel-ruby'

group :production do
  gem 'passenger'
  gem 'pg'
  gem 'lograge'
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platform: :mri
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console'
  gem 'listen', '~> 3.1'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  # Use sqlite3 as the database for Active Record
  gem 'sqlite3'
  gem 'foreman'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
