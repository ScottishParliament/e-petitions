Before do
  default_url_options[:protocol] = 'https'
end

Before do
  FactoryBot.create(:constituency, :glasgow_provan)
  FactoryBot.create(:postcode, :glasgow_provan)
  FactoryBot.create(:member, :glasgow_provan)
end

Before do
  RateLimit.create!(
    burst_rate: 10, burst_period: 60,
    sustained_rate: 20, sustained_period: 300,
    allowed_domains: "example.com", allowed_ips: "127.0.0.1"
  )
end

Before do
  stub_request(:post, NotifyMock.url).to_rack(NotifyMock.app)
end

Before do
  ::RSpec::Mocks.setup
end

After do
  ::RSpec::Mocks.verify
ensure
  ::RSpec::Mocks.teardown
end

Before do
  Rails.cache.clear
end

After do
  Site.reload
end

Before('@gaelic') do
  I18n.locale = :"gd-GB"
end

Before('not @gaelic') do
  I18n.locale = :"en-GB"
end

After do
  page.driver.options[:headers] = nil
end

After do
  ENV["INLINE_UPDATES"] = "true"
end

Before('@admin') do
  Capybara.app_host = 'https://moderate.petitions.parliament.scot'
  Capybara.default_host = 'https://moderate.petitions.parliament.scot'
end

Before('not @admin') do
  Capybara.app_host = 'https://petitions.parliament.scot'
  Capybara.default_host = 'https://petitions.parliament.scot'
end

Before('@skip') do
  skip_this_scenario
end

Before do
  ActiveRecord::FixtureSet.create_fixtures("#{::Rails.root}/spec/fixtures", ["rejection_reasons"])
end

After do
  ActiveRecord::FixtureSet.reset_cache
end
