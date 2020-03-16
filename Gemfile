source 'https://rubygems.org'
git_source(:github){ |repo| "https://github.com/#{repo}.git" }

ruby '2.6.3'

gem 'dalli'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.2.3'
# Use postgresql as the database for Active Record
gem 'pg', '>= 0.18', '< 2.0'
# Use Puma as the app server
gem 'puma', '~> 3.12'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker
gem 'webpacker'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'mini_racer', platforms: :ruby

gem 'messagebird-rest', require: 'messagebird'

gem "olive_branch"

gem 'activerecord-import'

gem 'dotenv-rails', '~> 2.2.1', groups: %i[development test]

gem 'devise-pwned_password'

gem 'postmark-rails'
gem 'remove_emoji'

gem 'api_cache'
gem 'moneta'

gem "csv"
gem 'delayed_job_active_record'
gem 'devise'
gem "slim-rails"

gem "httparty"
gem 'json'

# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
gem 'jbuilder_cache_multi'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'
gem 'rubocop', require: false

gem 'simple_form'

gem 'capybara'
gem 'capybara-screenshot'
gem 'selenium-webdriver'
group :test do
  gem "chromedriver-helper"
end
group :production, :development do
  gem 'webdrivers', '~> 4.0'
end

gem 'exception_notification'

# Use ActiveStorage variant
# gem 'mini_magick', '~> 4.8'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'factory_bot_rails'
  gem 'poltergeist'
  gem 'pry-rails'
  gem 'rspec-rails'
  gem 'sinatra', require: false
  gem 'spring-commands-rspec'
  gem 'timecop'
  gem 'webmock'
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'web-console', '>= 3.3.0'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'foreman'
  gem "letter_opener"
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

group :test do
  # Easy installation and use of chromedriver to run system tests with Chrome
  gem "vcr"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
