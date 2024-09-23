Given /^a set of petitions$/ do
  3.times do |x|
    @petition = FactoryBot.create(:open_petition, :with_additional_details, :action => "Petition #{x}")
  end
end

Given(/^a set of (\d+) petitions$/) do |number|
  number.times do |x|
    @petition = FactoryBot.create(:open_petition, :with_additional_details, :action => "Petition #{x}")
  end
end

When(/^I navigate to the next page of petitions$/) do
  click_link "Next"
end

Given(/^an? ?(pending|validated|sponsored|flagged|open|closed|rejected|completed)? petition "([^"]*)"(?: exists)?$/) do |state, action|
  @petition = FactoryBot.create(:"#{state || 'open'}_petition", action: action)
end

Given(/^a (sponsored|flagged) petition "(.*?)" reached threshold (\d+) days? ago$/) do |state, action, age|
  @petition = FactoryBot.create(:petition, action: action, state: state, moderation_threshold_reached_at: age.days.ago)
end

Given(/^a petition "([^"]*)" with a negative debate outcome$/) do |action|
  @petition = FactoryBot.create(:not_debated_petition, action: action)
end

Given(/^a petition "([^"]*)" with a scheduled debate date of "(.*?)"$/) do |action, date|
  @petition = FactoryBot.create(:scheduled_debate_petition, action: action, scheduled_debate_date: date)
end

Given(/^an archived petition with action: "([^"]*)"$/) do |action|
  @petition = FactoryBot.create(:archived_petition, action: action)
end

Given(/^a closed petition "([^"]*)" that is (not )?collecting signatures$/) do |action, not_collecting_signatures|
  @petition = FactoryBot.create(:closed_petition, action: action, collect_signatures: !not_collecting_signatures)
end

Given(/^the petition "([^"]*)" has (\d+) validated signatures$/) do |petition_action, no_validated|
  petition = Petition.find_by(action: petition_action)
  (no_validated - 1).times { FactoryBot.create(:validated_signature, petition: petition) }
  petition.reload
  @petition.reload if @petition
end

Given(/^a petition "([^"]*)" has been closed$/) do |petition_action|
  @petition = FactoryBot.create(:closed_petition, :action => petition_action)
end

Given(/^a petition "([^"]*)" has been completed$/) do |petition_action|
  @petition = FactoryBot.create(:completed_petition, :action => petition_action)
end

Given(/^the petition has reached the referral threshold$/) do
  @petition.update!(referral_threshold_reached_at: @petition.open_at + 2.months)
end

Given(/^the petition has closed$/) do
  @petition.close!(Time.now)
end

Given(/^the petition has closed some time ago$/) do
  @petition.close!(2.days.ago)
end

Given(/^a petition "([^"]*)" has been rejected(?: with the reason "([^"]*)")?$/) do |petition_action, reason|
  reason_text = reason.nil? ? "It doesn't make any sense" : reason
  @petition = FactoryBot.create(:rejected_petition,
    :action => petition_action,
    :rejection_code => "irrelevant",
    :rejection_details => reason || "It doesn't make any sense")
end

When(/^I view the petition$/) do
  visit petition_url(@petition)
end

When /^I view all petitions from the home page$/ do
  visit home_url
  click_link "All petitions"
end

Then(/^I can choose the "(.*)" facet$/) do |facet|
  within :css, 'details.lists-of-petitions' do
    expect(page).to have_content(facet)
  end
end

When(/^I check for similar petitions$/) do
  fill_in "q", :with => "Rioters should loose benefits"
  click_button("Continue")
end

When(/^I choose to create a petition anyway$/) do
  click_link_or_button "My petition is different"
end

Then(/^I should see all petitions$/) do
  expect(page).to have_css("ol li", :count => 3)
end

Then(/^I should see the petition details$/) do
  expect(page).to have_content(@petition.action)
  expect(page).to have_content(@petition.background) if @petition.background?

  if @petition.additional_details?
    expect(page).to have_content(@petition.additional_details)
  end
end

Then(/^I should see the vote count and open dates$/) do
  @petition.reload
  expect(page).to have_css("p.signature-count-number", :text => "#{@petition.signature_count} #{'signature'.pluralize(@petition.signature_count)}")

  expect(page).to have_css("li.meta-created-by", :text => "Created by " + @petition.creator.name)
end

Then(/^I should not see the vote count$/) do
  @petition.reload
  expect(page).to_not have_css("p.signature-count-number", :text => @petition.signature_count.to_s + " signatures")
end

Then(/^I should see submitted date$/) do
  @petition.reload
  expect(page).to have_css("li", :text =>  "Date submitted " + @petition.created_at.strftime("%e %B %Y").squish)
end

Then(/^I should see the petition creator$/) do
  expect(page).to have_css("li.meta-created-by", :text => "Created by " + @petition.creator.name)
end

Then(/^I should see the reason for rejection$/) do
  @petition.reload
  expect(page).to have_content(@petition.rejection.details)
end

Then(/^I should be asked to search for a new petition$/) do
  expect(page).to have_content("What do you want us to do?")
  expect(page).to have_css("form textarea[name=q]")
end

Then(/^I should see my search query already filled in as the action of the petition$/) do
  expect(page).to have_field("What do you want us to do?", text: "Rioters should loose benefits")
end

Then(/^I can click on a link to return to the petition$/) do
  slug = ('PE%04d' % @petition.pe_number_id)
  expect(page).to have_css("a[href*='/petitions/#{slug}']")
end

When(/^I am allowed to make the petition action too long$/) do
  # NOTE: we do this to remove the maxlength attribtue on the petition
  # action input because any modern browser/driver will not let us enter
  # values longer than maxlength and so we can't test our JS validation
  page.execute_script "document.getElementById('petition_creator_action').removeAttribute('maxlength');"
end

When(/^I am allowed to make the creator name too long$/) do
  # NOTE: we do this to remove the maxlength attribtue on the petition
  # name input because any modern browser/driver will not let us enter
  # values longer than maxlength and so we can't test our JS validation
  page.execute_script "document.getElementById('petition_creator_name').removeAttribute('maxlength');"
end

When(/^I start a new petition/) do
  steps %Q(
    Given I am on the new petition page
    Then I should see "#{I18n.t(:"page_titles.petitions.check")}" in the browser page title
    And I should be connected to the server via an ssl connection
  )
end

When(/^I fill in the petition details/) do
  if I18n.locale == :"en-GB"
    steps %Q(
      When I fill in "What do you want us to do?" with "The wombats of wimbledon rock."
      And I fill in "Petition summary" with "Give half of Wimbledon rock to wombats!"
      And I fill in "Previous action taken" with "I asked my local MP and she said to create a petition"
      And I fill in "Background information" with "The racial tensions between the wombles and the wombats are heating up. Racial attacks are a regular occurrence and the death count is already in 5 figures. The only resolution to this crisis is to give half of Wimbledon common to the Wombats and to recognise them as their own independent state."
    )
  else
    steps %Q(
      When I fill in "What do you want us to do?" with "The wombats of wimbledon rock."
      And I fill in "Petition summary" with "Give half of Wimbledon rock to wombats!"
      And I fill in "Previous action taken" with "I asked my local MP and she said to create a petition"
      And I fill in "Background information" with "The racial tensions between the wombles and the wombats are heating up. Racial attacks are a regular occurrence and the death count is already in 5 figures. The only resolution to this crisis is to give half of Wimbledon common to the Wombats and to recognise them as their own independent state."
    )
  end
end

Then(/^I should see my constituency "([^"]*)"/) do |constituency|
  expect(page).to have_text(constituency)
end

Then(/^I should see my Member of the Scottish Parliament/) do
  expect(page).to have_text("Ivan McKee MSP")
end

Then(/^I can click on a link to visit my Member of the Scottish Parliament$/) do
  expect(page).to have_css("a[href*='https://www.parliament.scot/msps/current-and-previous-msps/ivan-mckee']")
end

Then(/^I should not see the text "([^"]*)"/) do |text|
  expect(page).to_not have_text(text)
end

Then(/^my petition should be validated$/) do
  @sponsor_petition.reload
  expect(@sponsor_petition.state).to eq Petition::VALIDATED_STATE
end

Then(/^the petition creator signature should be validated$/) do
  @sponsor_petition.reload
  expect(@sponsor_petition.creator.state).to eq Signature::VALIDATED_STATE
end

Then(/^I can share it via (.+)$/) do |service|
  case service
  when 'Email'
    within(:css, '.petition-share') do
      expect(page).to have_link('Email', href: %r[\Amailto:\?body=#{ERB::Util.url_encode(petition_url(@petition))}&subject=Petition%3A%20#{ERB::Util.url_encode(@petition.action)}\z])
    end
  when 'Facebook'
    within(:css, '.petition-share') do
      expect(page).to have_link('Facebook', href: %r[\Ahttps://www\.facebook\.com/sharer/sharer\.php\?ref=responsive&u=#{ERB::Util.url_encode(petition_url(@petition))}\z])
    end
  when 'Twitter'
    within(:css, '.petition-share') do
      expect(page).to have_link('Twitter', href: %r[\Ahttps://twitter\.com/intent/tweet\?text=Petition%3A%20#{ERB::Util.url_encode(@petition.action)}&url=#{ERB::Util.url_encode(petition_url(@petition))}\z])
    end
  when 'Whatsapp'
    within(:css, '.petition-share') do
      expect(page).to have_link('Whatsapp', href: %r[\Awhatsapp://send\?text=Petition%3A%20#{ERB::Util.url_encode(@petition.action + "\n" + petition_url(@petition))}\z])
    end
  else
    raise ArgumentError, "Unknown sharing service: #{service.inspect}"
  end
end

Given(/^the site is not collecting sponsors$/) do
  Site.instance.update!(
    minimum_number_of_sponsors: 0,
    threshold_for_moderation: 0
  )
end

Given(/^an? (open|closed|rejected) petition "(.*?)" with some (fraudulent)? ?signatures$/) do |state, petition_action, signature_state|
  petition_closed_at = state == 'closed' ? 1.day.ago : nil
  petition_state = state == 'closed' ? 'open' : state
  petition_args = {
    action: petition_action,
    open_at: 3.months.ago,
    closed_at: petition_closed_at
  }
  @petition = FactoryBot.create(:"#{state}_petition", petition_args)
  signature_state ||= "validated"
  5.times { FactoryBot.create(:"#{signature_state}_signature", petition: @petition) }
end

Given(/^the threshold for a Parliament debate is "(.*?)"$/) do |amount|
  Site.instance.update!(threshold_for_debate: amount)
end

Given(/^there are (\d+) petitions that have been referred to the committee$/) do |referred_count|
  referred_count.times do |count|
    petition = FactoryBot.create(:referred_petition, :action => "Petition #{count}")
  end
end

Given(/^a petition "(.*?)" exists with a debate outcome$/) do |action|
  @petition = FactoryBot.create(:debated_petition, action: action, debated_on: 1.day.ago)
end

Given(/^a petition "(.*?)" exists with a debate outcome and with referral threshold met$/) do |action|
  @petition = FactoryBot.create(:debated_petition, action: action, debated_on: 1.day.ago, overview: 'Everyone was in agreement, this petition must be made law!', referral_threshold_reached_at: 30.days.ago)
end

Given(/^a petition "(.*?)" exists awaiting debate date$/) do |action|
  @petition = FactoryBot.create(:awaiting_debate_petition, action: action)
end

Given(/^an? ?(pending|validated|sponsored|flagged|open)? petition "(.*?)" exists with tags "([^"]*)"$/) do |state, action, tags|
  tags = tags.split(",").map(&:strip)
  state ||= "open"
  tag_ids = tags.map { |tag| Tag.find_or_create_by(name: tag).id }

  @petition = FactoryBot.create(:open_petition, state: state, action: action, tags: tag_ids)
end

Given(/^there are (\d+) petitions with a scheduled debate date$/) do |scheduled_debate_petitions_count|
  scheduled_debate_petitions_count.times do |count|
    FactoryBot.create(:scheduled_debate_petition, action: "Petition #{count}")
  end
end

Given(/^there are (\d+) petitions with enough signatures to require a debate$/) do |debate_threshold_petitions_count|
  debate_threshold_petitions_count.times do |count|
    FactoryBot.create(:awaiting_debate_petition, action: "Petition #{count}")
  end
end

Given(/^a petition "(.*?)" has other parliamentary business$/) do |petition_action|
  @petition = FactoryBot.create(:open_petition, action: petition_action)
  @email = FactoryBot.create(:petition_email,
    petition: @petition,
    subject: "Committee to discuss #{petition_action}",
    body: "The Petition Committee will discuss #{petition_action} on the #{Date.tomorrow}"
  )
end

Then(/^I should see the other parliamentary business items$/) do
  steps %Q(
    Then I should see "Other parliamentary business"
    And I should see "Committee to discuss #{@petition.action}"
    And I should see "The Petition Committee will discuss #{@petition.action} on the #{Date.tomorrow}"
  )
end

Then(/^I should not see the other parliamentary business items$/) do
  steps %Q(
    Then I should not see "Other parliamentary business"
    And I should not see "Committee to discuss #{@petition.action}"
    And I should not see "The Petition Committee will discuss #{@petition.action} on the #{Date.tomorrow}"
  )
end

Then(/^the petition content should be copied over$/) do
  @petition.reload

  %i[action details previous_action additional_details].each do |attr|
    expect(@petition["#{attr}_gd"]).to eq @petition["#{attr}_en"]
  end
end

Then(/^the petition content should be reset$/) do
  @petition.reload

  %i[action details previous_action additional_details].each do |attr|
    expect(@petition["#{attr}_gd"]).to be_nil
  end
end

Then(/^I should see both petitions content$/) do
  s = %i[action details additional_details].map do |attr|
    [@petition["#{attr}_gd"], @petition["#{attr}_en"]]
  end.flatten

  steps s.map { |content| "Then I should see \"#{content}\"" }.join("\n")
end

Then(/^I should not see both petitions content$/) do
  expect(page).to have_selector(:css, ".petition .background", count: 1)
end

Then(/^I should see the petition's (\w+) timestamp$/) do |attribute|
  timestamp = @petition.send attribute

  expect(page).to have_text(DateHelpers.short_date_format(timestamp).gsub("\u00A0", " "))
end

When(/^I search all petitions for "(.*?)"$/) do |search_term|
  within :css, 'section[aria-labelledby=search-petitions-heading]' do
    fill_in :search, with: search_term

    if I18n.locale == :"en-GB"
      step %{I press "Search"}
    else
      step %{I press "Search"}
    end
  end
end

Given(/^the petition has a ScotParl link "([^"]*)"$/) do |url|
  @petition.update!(scot_parl_link: url)
end

Given(/^an open petition "([^"]*)" with a previous action of "([^"]*)" was created on "([^"]*)"$/) do |action, previous_action, date|
  travel_to(date) do
    @petition = FactoryBot.create(:open_petition, action: action, previous_action: previous_action)
  end
end
