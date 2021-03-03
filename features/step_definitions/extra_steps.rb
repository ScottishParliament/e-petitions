Given(/^a sysadmin user exists with first_name: "([^"]*)", last_name: "([^"]*)", email: "([^"]*)", password: "([^"]*)", password_confirmation: "([^"]*)"$/) do |first_name, last_name, email, password, password_confirmation|
  @user = FactoryBot.create(:sysadmin_user, first_name: first_name, last_name: last_name, email: email, password: password, password_confirmation: password_confirmation)
end

Given(/^a moderator user exists with first_name: "([^"]*)", last_name: "([^"]*)", email: "([^"]*)", password: "([^"]*)", password_confirmation: "([^"]*)"$/) do |first_name, last_name, email, password, password_confirmation|
  @user = FactoryBot.create(:moderator_user, first_name: first_name, last_name: last_name, email: email, password: password, password_confirmation: password_confirmation)
end

Given(/^a moderator user exists with email: "([^"]*)", password: "([^"]*)", password_confirmation: "([^"]*)"$/) do |email, password, password_confirmation|
  @user = FactoryBot.create(:moderator_user, email: email, password: password, password_confirmation: password_confirmation)
end

Given(/^a moderator user exists with email: "([^"]*)", password: "([^"]*)", password_confirmation: "([^"]*)", force_password_reset: true$/) do |email, password, password_confirmation|
  @user = FactoryBot.create(:moderator_user, email: email, password: password, password_confirmation: password_confirmation, force_password_reset: true)
end

Given(/^a moderator user exists with email: "([^"]*)", first_name: "([^"]*)", last_name: "([^"]*)"$/) do |email, first_name, last_name|
  @user = FactoryBot.create(:moderator_user, first_name: first_name, last_name: last_name, email: email)
end

Given(/^a moderator user exists with email: "([^"]*)", first_name: "([^"]*)", last_name: "([^"]*)", failed_login_count: (\d+)$/) do |email, first_name, last_name, failed_login_count|
  @user = FactoryBot.create(:moderator_user, first_name: first_name, last_name: last_name, email: email, failed_login_count: failed_login_count)
end

Given(/^(\d+) moderator users exist$/) do |number|
  number.times do |count|
    FactoryBot.create(:moderator_user)
  end
end

Given(/^(\d+) petitions exist with state: "([^"]*)"$/) do |number, state|
  number.times do |count|
    FactoryBot.create(:petition, state: state)
  end
end

When(/^a moderator user should exist with email: "([^"]*)", failed_login_count: "([^"]*)"$/) do |email, failed_login_count|
  admin_user = AdminUser.where(email: email, failed_login_count: failed_login_count)
  expect(admin_user).to exist
end

Given(/^a moderator user exists with email: "([^"]*)", first_name: "([^"]*)", last_name: "([^"]*)", failed_login_count: "([^"]*)"$/) do |email, first_name, last_name, failed_login_count|
  @user = FactoryBot.create(:moderator_user, email: email, first_name: first_name, last_name: last_name, failed_login_count: failed_login_count)
end

Then(/^a admin user should not exist with email: "([^"]*)"$/) do |email|
  admin_users = AdminUser.where(email: email)
  expect(admin_users).to eq([])
end

Given(/^an open petition exists with action: "([^"]*)"$/) do |action|
  @petition = FactoryBot.create(:open_petition, action: action)
end

Given(/^a referred petition exists with action: "([^"]*)"$/) do |action|
  @petition = FactoryBot.create(:referred_petition, action: action)
end

Given(/^a rejected petition exists with action: "([^"]*)"$/) do |action|
  @petition = FactoryBot.create(:rejected_petition, action: action)
end

Given(/^a hidden petition exists with action: "([^"]*)"$/) do |action|
  @petition = FactoryBot.create(:hidden_petition, action: action)
end

Then(/^a validated signature should exist with name: "([^"]*)", location_code: "([^"]*)", postcode: "([^"]*)"$/) do |name, location_code, postcode|
  signature = Signature.where(name: name, location_code: location_code, postcode: postcode)
  expect(signature).to exist
end

Given(/^a sponsored petition exists with action: "([^"]*)"$/) do |action|
  @petition = FactoryBot.create(:sponsored_petition, action: action)
end

Then(/^a petition should exist with action: "([^"]*)", state: "([^"]*)"$/) do |action, state|
  petition = Petition.where(action: action, state: state)
  expect(petition).to exist
end

Then(/^a petition exists with state: "([^"]*)", action_en: "([^"]*)", action_gd: "([^"]*)", closed_at: "([^"]*)"$/) do |state, action_en, action_gd, closed_at|
  petition = Petition.where(state: state, action_en: action_en, action_gd: action_gd, closed_at: closed_at)
  expect(petition).to exist
end

Then(/^a signature exists with state: "([^"]*)", name: "([^"]*)", email: "([^"]*)", postcode: "([^"]*)"$/) do |state, name, email, postcode|
  signature = Signature.where(state: state, name: name, email: email, postcode: postcode)
  expect(signature).to exist
end

Then(/^a contact exists with address: "([^"]*)", phone_number: "([^"]*)"$/) do |address, phone_number|
  @contact = FactoryBot.create(:contact, address: address, phone_number: phone_number)
end

Given(/^a tag exists with name: "([^"]*)"$/) do |name|
  @tag = FactoryBot.create(:tag, name: name)
end

Given(/^an sponsored petition exists with action: "([^"]*)"$/) do |action|
  @petition = FactoryBot.create(:sponsored_petition, action: action)
end

Given(/^an open petition exists with action_en: "([^"]*)", action_gd: "([^"]*)", background_en: "([^"]*)", background_gd: "([^"]*)"$/) do |action_en, action_gd, background_en, background_gd|
  @petition = FactoryBot.create(:open_petition, action_en: action_en, action_gd: action_gd, background_en: background_en, background_gd: background_gd)
end

Given(/^an open petition exists with action_en: "([^"]*)", background_en: "([^"]*)", action_gd: "([^"]*)", background_gd: "([^"]*)"$/) do |action_en, background_en, action_gd, background_gd|
  @petition = FactoryBot.create(:open_petition, action_en: action_en, action_gd: action_gd, background_en: background_en, background_gd: background_gd)
end

Given(/^a closed petition exists with action: "([^"]*)"$/) do |action|
  @petition = FactoryBot.create(:closed_petition, action: action)
end

Given(/^an open petition exists with action: "([^"]*)", background: "([^"]*)"$/) do |action, background|
  @petition = FactoryBot.create(:open_petition, action: action, background: background)
end

Given(/^an open, untranslated petition exists with action: "([^"]*)", background: "([^"]*)"(?:, previous_action: "([^"]*)")?$/) do |action, background, previous_action|
  @petition = FactoryBot.create(:open_petition, action: action, background: background, previous_action: previous_action)

  remove_lang = @petition.english? ? 'gd' : 'en'

  %i[action background previous_action additional_details].each do |attr|
    @petition["#{attr}_#{remove_lang}"] = nil
  end

  @petition.save
end

Given(/^an open, translated petition exists with action: "([^"]*)", background: "([^"]*)"(?:, previous_action: "([^"]*)")?$/) do |action, background, previous_action|
  @petition = FactoryBot.create(:open_petition, :translated, action: action, background: background, previous_action: previous_action)
end

Given(/^a pending petition exists with action_en: "([^"]*)", action_gd: "([^"]*)"$/) do |action_en, action_gd|
  @petition = FactoryBot.create(:pending_petition, action_en: action_en, action_gd: action_gd)
end

Given(/^a validated petition exists with action_en: "([^"]*)", action_gd: "([^"]*)"$/) do |action_en, action_gd|
  @petition = FactoryBot.create(:validated_petition, action_en: action_en, action_gd: action_gd)
end

Given(/^an open petition exists with action_en: "([^"]*)", additional_details: "([^"]*)", action_gd: "([^"]*)", additional_details_gd: "([^"]*)", closed_at: "([^"]*)"$/) do |action_en, additional_details, action_gd, additional_details_gd, closed_at|
  @petition = FactoryBot.create(:open_petition, action_en: action_en, additional_details: additional_details, action_gd: action_gd, additional_details_gd: additional_details_gd, closed_at: closed_at)
end

Given(/^an open petition exists with action_en: "([^"]*)", background: "([^"]*)", action_gd: "([^"]*)", background_gd: "([^"]*)", closed_at: "([^"]*)"$/) do |action_en, background, action_gd, background_gd, closed_at|
  @petition = FactoryBot.create(:open_petition, action_en: action_en, background: background, action_gd: action_gd, background_gd: background_gd, closed_at: closed_at)
end

Given(/^an open petition exists with action_en: "([^"]*)", action_gd: "([^"]*)", closed_at: "([^"]*)"$/) do |action_en, action_gd, closed_at|
  @petition = FactoryBot.create(:open_petition, action_en: action_en, action_gd: action_gd, closed_at: closed_at)
end

Given(/^a referred petition exists with action_en: "([^"]*)", action_gd: "([^"]*)", closed_at: "([^"]*)"$/) do |action_en, action_gd, closed_at|
  @petition = FactoryBot.create(:referred_petition, action_en: action_en, action_gd: action_gd, closed_at: closed_at)
end

Given(/^a referred petition exists with action: "([^"]*)", closed_at: (.*)$/) do |action, expr|
  timestamp = eval(expr)

  @petition = FactoryBot.create(:referred_petition, action: action, closed_at: timestamp)
end

Given(/^a rejected petition exists with action_en: "([^"]*)", action_gd: "([^"]*)"$/) do |action_en, action_gd|
  @petition = FactoryBot.create(:rejected_petition, action_en: action_en, action_gd: action_gd)
end

Given(/^a hidden petition exists with action_en: "([^"]*)", action_gd: "([^"]*)"$/) do |action_en, action_gd|
  @petition = FactoryBot.create(:hidden_petition, action_en: action_en, action_gd: action_gd)
end

Then(/^a petition should exist with action_en: "([^"]*)", action_gd: nil, state: "([^"]*)", locale: "([^"]*)"$/) do |action_en, state, locale|
  petition = Petition.where(action_en: action_en, action_gd: nil, state: state, locale: locale)
  expect(petition).to exist
end

Then(/^a petition should exist with action_en: "([^"]*)", action_gd: nil, state: "([^"]*)", locale: "([^"]*)", collect_signatures: (\w+)$/) do |action_en, state, locale, collect_signatures|
  petition = Petition.where(
    action_en: action_en,
    action_gd: nil,
    state: state,
    locale: locale,
    collect_signatures: collect_signatures,
  )

  expect(petition).to exist
end

Then(/^a petition should exist with action_gd: "([^"]*)", action_en: nil, state: "([^"]*)", locale: "([^"]*)"$/) do |action_gd, state, locale|
  petition = Petition.where(action_en: nil, action_gd: action_gd, state: state, locale: locale)
  expect(petition).to exist
end

Then(/^a signature should exist with email: "([^"]*)", state: "([^"]*)"$/) do |email, state|
  signature = Signature.where(email: email, state: state)
  expect(signature).to exist
end

Then(/^a petition should not exist with action: "([^"]*)", state: "([^"]*)"$/) do |action, state|
  petition = Petition.where(action: action, state: state)
  expect(petition).to eq([])
end

Then(/^a signature should not exist with email: "([^"]*)", state: "([^"]*)"$/) do |email, state|
  signature = Signature.where(email: email, state: state)
  expect(signature).to eq([])
end

Given(/^(\d+) open petitions exist with action: "([^"]*)"$/) do |number, action|
  number.times do |count|
    FactoryBot.create(:open_petition, action: action)
  end
end

Given(/^an open petition exists with action: "([^"]*)", additional_details: "([^"]*)"$/) do |action, additional_details|
  @petition = FactoryBot.create(:open_petition, action: action, additional_details: additional_details)
end

Given(/^an open petition exists with action: "([^"]*)", committee_note: "([^"]*)"$/) do |action, committee_note|
  @petition = FactoryBot.create(:open_petition, action: action, committee_note: committee_note)
end

Then(/^"([^"]*)" should be emailed a link for validating their signature$/) do |address|
  open_last_email_for(address)
  steps %{
    Then they should see "Please confirm your email" in the email subject
    When they open the email with subject "Please confirm your email"
  }
  steps %{
    Then they should see /Please click this link to confirm your email/ in the email body
  }
end

When(/^I confirm my email$/) do
  steps %Q(
    When I click the first link in the email
  )
end

Then(/^a petition should exist with action_en: "([^"]*)", state: "([^"]*)"$/) do |action_en, state|
  petition = Petition.where(action_en: action_en, state: state)
  expect(petition).to exist
end
