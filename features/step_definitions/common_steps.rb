Given(/^the site is disabled$/) do
  Site.instance.update! enabled: false
end

Given(/^the site is protected$/) do
  Site.instance.update! protected: true, username: "username", password: "password"
end

Given(/^signature counting is handled by an external process$/) do
  ENV["INLINE_UPDATES"] = "false"
end

Given(/^the Gaelic website is disabled$/) do
  Site.instance.update! feature_flags: { disable_gaelic_website: true }
end

Given(/^the site has disabled email notifications$/) do
  Site.instance.update! feature_flags: { disable_notify_by_email: true }
end

Given(/^the site has disabled local petitions$/) do
  Site.instance.update! feature_flags: { disable_local_petitions: true }
end

Given(/^the site has disabled the register to vote link$/) do
  Site.instance.update! feature_flags: { disable_register_to_vote: true }
end

Given(/^the site has disabled other parliamentary business$/) do
  Site.instance.update! feature_flags: { disable_other_business: true }
end

Given(/^the request is not local$/) do
  page.driver.options[:headers] = { "REMOTE_ADDR" => "192.168.1.128" }
end

Then(/^I am asked for a username and password$/) do
  expect(page.status_code).to eq 401
end

Then(/^I will see a 503 error page$/) do
  expect(page.status_code).to eq 503
end

When(/^I click the shared link$/) do
  expect(@shared_link).not_to be_blank
  visit @shared_link
end

Then(/^I should not index the page$/) do
  expect(page).to have_css('meta[name=robots]', visible: false)
end

Then(/^I should index the page$/) do
  expect(page).not_to have_css('meta[name=robots]', visible: false)
end
