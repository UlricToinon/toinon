source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.0.0'

gem 'pg'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 4.0.0'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'

# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.0.0'

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

gem 'bootstrap-sass', '~> 3.2.0'
gem 'autoprefixer-rails'

#JS Runtimes to enable JS compatibility on Unix Server
gem 'therubyracer', :platforms => :ruby
gem 'execjs', :platforms => :ruby
# HAML
gem 'haml', '4.0.3'
gem 'html2haml'

gem 'font-awesome-rails'

# Use jquery as the JavaScript library
gem 'jquery-rails'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder'

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc', require: false
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'turbo-sprockets-rails3'
end

group :test do
  gem "factory_girl_rails"
  gem "capybara"
  gem "guard-rspec"  
  
end

group :development, :test do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem "rspec-rails"
  gem "thin"
  gem 'meta_request', '~> 0.3.0'
  gem 'capistrano-unicorn', require: false
end
# Use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# Use unicorn as the app server
group :production do
  gem 'unicorn'
end


# Use Capistrano for deployment
gem 'capistrano', '~> 2.15.5'
gem 'capistrano-ext'
gem 'rvm-capistrano'
gem 'unicorn'

# Use debugger
# gem 'debugger', group: [:development, :test]

# Installation gem google analytics
gem 'google-analytics-rails'

gem 'net-ssh', '2.7.0'