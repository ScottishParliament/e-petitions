When(/^I look at the next petition on my list$/) do
  @petition = FactoryBot.create(:sponsored_petition, :with_additional_details, :action => "Petition 1", collect_signatures: true)
  visit admin_petition_url(@petition)
end

When(/^I look at the next petition on my list that is not collecting signatures and has reached referral threshold$/) do
  @petition = FactoryBot.create(:sponsored_petition, :with_additional_details, :action => "Petition 1", collect_signatures: false, referral_threshold_reached_at: Time.current)
  visit admin_petition_url(@petition)
end

When(/^I visit a sponsored petition with action: "([^"]*)", that has background: "([^"]*)" and additional details: "([^"]*)"$/) do |petition_action, background, additional_details|
  @sponsored_petition = FactoryBot.create(:sponsored_petition, action: petition_action, background: background, additional_details: additional_details)
  visit admin_petition_url(@sponsored_petition)
end

When(/^I visit a sponsored petition with action: "([^"]*)", that has background: "([^"]*)", and previous action: "([^"]*)", and additional details: "([^"]*)"$/) do |petition_action, background, previous_action, additional_details|
  @sponsored_petition = FactoryBot.create(:sponsored_petition, action: petition_action, background: background, previous_action: previous_action, additional_details: additional_details)
  visit admin_petition_url(@sponsored_petition)
end

When(/^I reject the petition with a reason code "([^"]*)"$/) do |reason_code|
  choose "Reject"
  select reason_code, :from => :petition_rejection_code
  click_button "Email petition creator"
end

When(/^I change the rejection status of the petition with a reason code "([^"]*)"$/) do |reason_code|
  click_on 'Change rejection reason'
  select reason_code, :from => :petition_rejection_code
  click_button "Email petition creator"
end

When(/^I reject the petition with a reason code "([^"]*)" and some explanatory text$/) do |reason_code|
  choose "Reject"
  select reason_code, :from => :petition_rejection_code
  fill_in :petition_rejection_details_en, :with => "See guidelines at http://direct.gov.uk"
  fill_in :petition_rejection_details_gd, :with => "Gweler y canllawiau yn http://direct.gov.uk"
  click_button "Email petition creator"
end

Then /^the petition is not available for signing$/ do
  visit petition_url(@petition)
  expect(page).not_to have_css("a", :text => "Sign")
end

When(/^I publish the petition$/) do
  choose "Approve"
  click_button "Email petition creator"
end

When(/^I flag the petition$/) do
  choose "Flag"
  click_button "Save without emailing"
end

Then /^the petition is still available for searching or viewing$/ do
  step %{I search for "Rejected petitions" with "#{@petition.action}"}
  step %{I should see the petition "#{@petition.action}"}
  step %{I view the petition}
  step %{I should see the petition details}
end

Then /^the explanation is displayed on the petition for viewing by the public$/ do
  step %{I view the petition}
  step %{I should see the reason for rejection}
end

Then /^the petition is not available for searching or viewing$/ do
  step %{I search for "All petitions" with "#{@petition.action}"}
  step %{I should not see the petition "#{@petition.action}"}
end

Then /^the petition will still show up in the back\-end reporting$/ do
  visit admin_petitions_url
  step %{I should see the petition "#{@petition.action}"}
end

Then /^the petition should be visible on the site for signing$/ do
  visit petition_url(@petition)
  expect(page).to have_css("a", :text => "Sign this petition")
end


Then(/^the petition should be visible on the site but not available for signing$/) do
  visit petition_url(@petition)
  expect(page).not_to have_css("a", :text => "Sign this petition")
end

Then(/^the petition can no longer be flagged$/) do
  expect(page).to have_no_field('Flag', visible: false)
end

Then(/^the creator should receive a notification email$/) do
  steps %Q(
    Then "#{@petition.creator.email}" should receive an email
    When they open the email
    Then they should see "published" in the email body
    And they should see /We published your petition/ in the email subject
  )
end

Then(/^the creator should not receive a notification email$/) do
  step %{"#{@petition.creator.email}" should receive no email with subject "We published your petition"}
end

Then(/^the creator should receive a (libel\/profanity )?rejection notification email$/) do |petition_is_libellous|
  @petition.reload
  @rejection_reason = RejectionReason.find_by!(code: @petition.rejection.code)

  steps %Q(
    Then "#{@petition.creator.email}" should receive an email
    When they open the email
    Then they should see "Unfortunately, we are not able to accept your proposed petition" in the email body
    And they should see "#{@rejection_reason.description}" in the email body
    And they should see "We rejected your petition" in the email subject
  )
  if petition_is_libellous
    step %{they should not see "#{petition_url(@petition)}" in the email body}
  else
    step %{they should see "#{petition_url(@petition)}" in the email body}
  end
end

Then(/^the creator should not receive a rejection notification email$/) do
  step %{"#{@petition.creator.email}" should receive no email with subject "We rejected your petition"}
end

When(/^I view all petitions$/) do
  click_on 'Petitions Admin'
  find("//a", :text => /^All Petitions/).click
end

Then /^I should see the petition "([^"]*)"$/ do |petition_action|
  expect(page).to have_link(petition_action)
end

Then /^I should not see the petition "([^"]*)"$/ do |petition_action|
  expect(page).not_to have_link(petition_action)
end

When(/^I filter the list to show "([^"]*)" petitions$/) do |option|
  select option
end

Then /^I should not see any "([^"]*)" petitions$/ do |state|
  expect(page).to have_no_css("td.state", :text => state)
end

Then /^I see relevant reason descriptions when I browse different reason codes$/ do
  choose "Reject"
  select "Duplicate petition", :from => :petition_rejection_code
  expect(page).to have_content "already a petition"
  select "Confidential, libellous, false, defamatory or references a court case", :from => :petition_rejection_code
  expect(page).to have_content "It included potentially confidential, libellous, false or defamatory information, or a reference to a case which is active in the UK courts."
end

Given(/^a moderator updates the petition activity$/) do
  steps %Q(
    Given I am logged in as a moderator
    And I view all petitions
    And I follow "#{@petition.action}"
    And I follow "Other parliamentary business"
    And I follow "New other parliamentary business"
    And I fill in "Subject in English" with "Get ready"
    And I fill in "Subject in Gaelic" with "Ullaich"
    And I fill in "Body in English" with "Parliament here it comes"
    And I fill in "Body in Gaelic" with "Pàrlamaid an seo thig e"
    And I press "Send email"
  )
end

Given /^the petition is translated$/ do
  (@sponsored_petition || @petition).tap do |petition|
    if petition.english?
      petition.update!(
        action_gd: petition.action_en,
        background_gd: petition.background_en,
        additional_details_gd: petition.additional_details_en,
        previous_action_gd: petition.previous_action_en
      )
    else
      petition.update!(
        action_en: petition.action_gd,
        background_en: petition.background_gd,
        additional_details_en: petition.additional_details_gd,
        previous_action_en: petition.previous_action_gd
      )
    end
  end
end

Given /^the petition is not translated$/ do
  (@sponsored_petition || @petition).tap do |petition|
    if petition.english?
      petition.update!(
        action_gd: nil,
        background_gd: nil,
        additional_details_gd: nil
      )
    else
      petition.update!(
        action_en: nil,
        background_en: nil,
        additional_details_en: nil
      )
    end
  end
end

Given /^the petition "([^"]*)" is translated$/ do |action|
  (Petition.find_by!(action: action)).tap do |petition|
    if petition.english?
      petition.update!(
        action_gd: petition.action_en,
        background_gd: petition.background_en,
        additional_details_gd: petition.additional_details_en
      )
    else
      petition.update!(
        action_en: petition.action_gd,
        background_en: petition.background_gd,
        additional_details_en: petition.additional_details_gd
      )
    end
  end
end

When /^I revisit the petition$/ do
  visit admin_petition_url(@petition)
end

Then /^it can still be approved$/ do
  expect(page).to have_field('Approve', visible: false)
end

Then /^it can still be rejected$/ do
  expect(page).to have_field('Reject', visible: false)
end

Then /^it can be restored to a sponsored state$/ do
  choose "Unflag"
  click_button "Save without emailing"
  expect(page).to have_content("Petition has been successfully updated")
  expect(page).to have_content("Status Sponsored")
end

Then /^the petition should still be unmoderated$/ do
  expect(@petition).not_to be_visible
end

When(/^I fill in the English petition details$/) do
  within(".//fieldset[@id='english-details']") do
    fill_in "Title", with: "Do stuff!"
    fill_in "Summary", with: "For reasons"
    fill_in "Previous action", with: "Here's what I've done before"
    fill_in "Background information", with: "Here's some more reasons"
  end
end

When(/^I fill in the Gaelic petition details$/) do
  within(".//fieldset[@id='gaelic-details']") do
    fill_in "Title", with: "Dèan stuth!"
    fill_in "Summary", with: "Airson adhbharan"
    fill_in "Previous action", with: "Seo na rinn mi roimhe"
    fill_in "Background information", with: "Seo beagan a bharrachd adhbharan"
  end
end
