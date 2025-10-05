ENV['RAILS_ENV'] ||= 'test'
require 'spec_helper'
require File.expand_path('../../config/environment', __FILE__)
require 'faker'
require 'rspec/rails'
require 'webmock/rspec'

# Use webmock to disable net connections except for localhost and exceptions
WebMock.disable_net_connect!(
  allow_localhost: true,
  allow: 'chromedriver.storage.googleapis.com'
)

Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  config.fixture_paths = "#{::Rails.root}/spec/fixtures"
  config.global_fixtures = %i[rejection_reasons]
  config.include Requests::JsonHelpers, type: :request

  config.backtrace_exclusion_patterns << /gems/
end
