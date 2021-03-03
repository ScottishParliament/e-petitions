Then(/^I should see the (.*) petition status$/) do |status|
  within(:css, '.petition-meta-state') do
    expect(page).to have_content(status)
  end
end
