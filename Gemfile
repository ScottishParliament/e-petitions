source 'https://rubygems.org'

# Load environment variables
gem 'dotenv-rails', require: 'dotenv/rails-now'

gem 'rails', '6.1.7.6'

gem 'rake'
gem 'pg'
gem 'authlogic'
gem 'will_paginate'
gem 'json'
gem 'delayed_job_active_record'
gem 'whenever'
gem 'appsignal'
gem 'faraday'
gem 'faraday_middleware'
gem 'net-http-persistent'
gem 'sass-rails', '< 6'
gem 'textacular'
gem 'uglifier'
gem 'bcrypt'
gem 'faker', require: false
gem 'slack-notifier'
gem 'daemons'
gem 'jquery-rails'
gem 'delayed-web'
gem 'dalli'
gem 'connection_pool'
gem 'lograge'
gem 'logstash-logger'
gem 'jbuilder'
gem 'image_processing'
gem 'maxminddb'
gem 'redcarpet'
gem 'scrypt'

gem 'aws-sdk-codedeploy', require: false
gem 'aws-sdk-cloudwatchlogs', require: false
gem 'aws-sdk-s3', require: false
gem 'aws-sdk-sesv2', require: false
gem 'aws-sdk-sqs', require: false
gem 'shoryuken', require: false

group :development, :test do
  gem 'simplecov'
  gem 'brakeman', require: false
  gem 'bundler-audit', require: false
  gem 'rspec-rails'
  gem 'pry'
  gem 'guard'
  gem 'guard-cucumber', require: false
  gem 'guard-rspec', require: false
end

group :test do
  gem 'nokogiri'
  gem 'shoulda-matchers'
  gem 'cucumber', '~> 2.4.0'
  gem 'cucumber-rails', require: false
  gem 'database_cleaner'
  gem 'capybara'
  gem 'factory_bot_rails'
  gem 'email_spec'
  gem 'launchy'
  gem 'webdrivers'
  gem 'webmock'
  gem 'rails-controller-testing'
end

group :production do
  gem 'puma', '< 6'
end
