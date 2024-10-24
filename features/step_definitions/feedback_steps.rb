Given(/^the feedback page is disabled$/) do
  Site.instance.update! feature_flags: { disable_feedback_sending: true }
end

Then(/^I should be able to submit feedback$/) do
  page.driver.browser.header('User-Agent', 'Chrome')

  @feedback = FactoryBot.create(:feedback, comment: "I can't submit a petition for some reason")

  fill_in "feedback[email]", with: @feedback.email
  fill_in "feedback[petition_link_or_title]", with: @feedback.petition_link_or_title
  fill_in "feedback[comment]", with: @feedback.comment

  click_button("Send feedback")
  expect(page).to have_content("Thank")
end

Then(/^the site owners should be notified$/) do
  steps %Q(
    Then "#{Mail::Address.new(Site.feedback_email).address}" should receive an email
    When they open the email
    Then they should see "#{@feedback.email}" in the email body
    Then they should see "#{@feedback.petition_link_or_title}" in the email body
    Then they should see "#{@feedback.comment}" in the email body
    Then they should see "Chrome" in the email body
  )
end

Then(/^the site owners should not be notified$/) do
  steps %Q(
    Then "#{Mail::Address.new(Site.feedback_email).address}" should receive no emails
  )
end

Then(/^I cannot submit feedback without filling in the required fields$/) do
  click_button("Send feedback")
  expect(page).to have_content("must be completed")
  step %{"#{Mail::Address.new(Site.feedback_email).address}" should have no emails}
end

Given(/^there (?:are|is) (\d+) feedbacks? created from this IP address$/) do |count|
  count.times do
    FactoryBot.create(:feedback, ip_address: "127.0.0.1")
  end
end
