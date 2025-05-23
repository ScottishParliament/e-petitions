Feature: As Charlie
  In order to have an issue discussed in the Parliament
  I want to be able to create a petition and verify my email address.

Scenario: Charlie has to search for a petition before creating one
  Given a petition "Rioters should loose benefits"
  And a rejected petition "Rioters must loose benefits"
  Given I am on the home page
  When I follow "Start a petition" within ".//main"
  Then I should be asked to search for a new petition
  When I check for similar petitions
  Then I should see "Rioters should loose benefits"
  Then I should not see "Rioters must loose benefits"
  When I choose to create a petition anyway
  Then I should be on the new petition page
  And I should see my search query already filled in as the action of the petition

Scenario: Charlie sees a message when starting a petition and signature collection has been paused
  Given petitions are not collecting signatures
  When I am on the home page
  And I follow "Start a petition" within ".//main"
  Then I should see "Petitions have stopped collecting signatures"

Scenario: Charlie sees a message when starting a petition and a message has been enabled
  Given a home page message has been enabled
  When I am on the home page
  And I follow "Start a petition" within ".//main"
  Then I should see "Petition moderation is experiencing delays"

Scenario: Charlie cannot craft an xss attack when searching for petitions
  Given I am on the home page
  When I follow "Start a petition" within ".//main"
  Then I fill in "q" with "'onmouseover='alert(1)'"
  When I press "Continue"
  Then the markup should be valid

Scenario: Charlie creates a petition
  Given the site is not collecting sponsors
  And I start a new petition
  And I fill in the petition details
  And I press "Preview petition"
  And I press "This looks good"
  And I fill in my details as a creator
  And I fill in my creator contact details
  When I press "Continue"
  Then the markup should be valid
  And I am asked to review my email address
  When I press "Yes – this is my email address"
  Then a petition should exist with action_en: "The wombats of wimbledon rock.", action_gd: nil, state: "pending", locale: "en-GB", collect_signatures: true
  And there should be a "pending" signature with email "womboid@wimbledon.com" and name "Womboid Wibbledon"
  And "womboid@wimbledon.com" should be emailed a link for validating their signature
  When I confirm my email
  Then a petition should exist with action_en: "The wombats of wimbledon rock.", state: "sponsored"
  And I should see "We’re checking this petition"

Scenario: Charlie creates a petition and wants to collect signatures
  Given the date is the "20 April, 2020"
  And I start a new petition
  And I fill in the petition details
  And I press "Preview petition"
  And I press "This looks good"
  And I fill in my details as a creator
  And I fill in my creator contact details
  And I press "Continue"
  Then I am asked to review my email address
  When I press "Yes – this is my email address"
  Then a petition should exist with action_en: "The wombats of wimbledon rock.", action_gd: nil, state: "pending", locale: "en-GB", collect_signatures: true

Scenario: Charlie creates a petition when sponsor count is set to 0
  Given the site is not collecting sponsors
  And I start a new petition
  Then I should not see "email addresses for 0 supporters"
  And I fill in the petition details
  And I press "Preview petition"
  And I press "This looks good"
  And I fill in my details as a creator
  And I fill in my creator contact details
  When I press "Continue"
  Then the markup should be valid
  And I am asked to review my email address
  When I press "Yes – this is my email address"
  Then a petition should exist with action_en: "The wombats of wimbledon rock.", action_gd: nil, state: "pending", locale: "en-GB"
  And there should be a "pending" signature with email "womboid@wimbledon.com" and name "Womboid Wibbledon"
  Then I should see "We’ve emailed you a link to confirm your email address"
  And "Womboid Wibbledon" wants to be notified about the petition's progress
  And "womboid@wimbledon.com" should be emailed a link for validating their signature
  When I confirm my email
  Then a petition should exist with action_en: "The wombats of wimbledon rock.", state: "sponsored"
  And I should see "We’re checking this petition"

@gaelic
Scenario: Charlie creates a petition in Gaelic
  Given I start a new petition
  And I fill in the petition details
  And I press "Preview petition"
  And I press "This looks good"
  And I fill in my details as a creator
  And I fill in my creator contact details
  When I press "Continue"
  Then the markup should be valid
  And I am asked to review my email address
  When I press "Yes – this is my email address"
  Then a petition should exist with action_gd: "The wombats of wimbledon rock.", action_en: nil, state: "pending", locale: "gd-GB"
  And there should be a "pending" signature with email "womboid@wimbledon.com" and name "Womboid Wibbledon"
  And "Womboid Wibbledon" wants to be notified about the petition's progress
  And "womboid@wimbledon.com" should be emailed a link for gathering support from sponsors

Scenario: First person sponsors a petition
  When I have created a petition and told people to sponsor it
  And a sponsor supports my petition
  Then my petition should be validated
  And the petition creator signature should be validated

Scenario: Charlie creates a petition with invalid postcode SW14 9RQ
  Given I start a new petition
  And I fill in the petition details
  And I press "Preview petition"
  And I press "This looks good"
  And I fill in my details as a creator with postcode "SW14 9RQ"
  And I fill in my creator contact details
  And I press "Continue"
  Then I should not see the text "Your constituency is"

@javascript
Scenario: Charlie tries to submit an invalid petition
  Given I am on the new petition page

  When I press "Preview petition"
  Then I should see "Title must be completed"
  And I should see "Summary must be completed"
  And I should see "Previous action must be completed"
  And I should see "Background information must be completed"

  When I am allowed to make the petition action too long
  And I fill in "What do you want us to do?" with text longer than 100 characters
  And I fill in "Petition summary" with text longer than 500 characters
  And I fill in "Previous action taken" with text longer than 500 characters
  And I fill in "Background information" with text longer than 1100 characters
  And I press "Preview petition"

  Then I should see "Title is too long"
  And I should see "Summary is too long"
  And I should see "Previous action is too long"
  And I should see "Background information is too long"

  When I fill in "What do you want us to do?" with "=cmd"
  And I fill in "Petition summary" with "@cmd"
  And I fill in "Previous action taken" with "@cmd"
  And I fill in "Background information" with "+cmd"
  And I press "Preview petition"

  Then I should see "Title can’t start with a ‘=’, ‘+’, ‘-’ or ‘@’"
  And I should see "Summary can’t start with a ‘=’, ‘+’, ‘-’ or ‘@’"
  And I should see "Previous action can’t start with a ‘=’, ‘+’, ‘-’ or ‘@’"
  And I should see "Background information can’t start with a ‘=’, ‘+’, ‘-’ or ‘@’"

  When I fill in "What do you want us to do?" with "The wombats of wimbledon rock."
  And I fill in "Petition summary" with "Give half of Wimbledon rock to wombats!"
  And I fill in "Previous action taken" with "I asked my MP and she said to create a petition"
  And I fill in "Background information" with "The racial tensions between the wombles and the wombats are heating up. Racial attacks are a regular occurrence and the death count is already in 5 figures. The only resolution to this crisis is to give half of Wimbledon common to the Wombats and to recognise them as their own independent state."
  And I press "Preview petition"

  Then I should see a heading called "Check your petition"

  And I should see "The wombats of wimbledon rock."
  And I should see "The racial tensions between the wombles and the wombats are heating up. Racial attacks are a regular occurrence and the death count is already in 5 figures. The only resolution to this crisis is to give half of Wimbledon common to the Wombats and to recognise them as their own independent state."

  And I press "Go back and make changes"
  And the "What do you want us to do?" field should contain "The wombats of wimbledon rock."
  And the "Petition summary" field should contain "Give half of Wimbledon rock to wombats!"
  And the "Previous action taken" field should contain "I asked my MP and she said to create a petition"
  And the "Background information" field should contain "The racial tensions between the wombles and the wombats are heating up. Racial attacks are a regular occurrence and the death count is already in 5 figures. The only resolution to this crisis is to give half of Wimbledon common to the Wombats and to recognise them as their own independent state."

  And I press "Preview petition"
  And I press "This looks good"

  Then I should see a heading called "Sign your petition"

  When I press "Continue"
  Then I should see "Name must be completed"
  And I should see "Email must be completed"
  And I should see "Postcode must be completed"
  And I should see "Phone number must be completed"
  And I should see "Address must be completed"
  And I should see "Privacy notice must be accepted"

  When I fill in "Address" with text longer than 500 characters
  And I fill in "Phone number" with "32000000000000000000000000000000"
  And I press "Continue"
  Then I should see "Phone number is too long"
  And I should see "Address is too long"

  When I fill in "Name" with "=cmd"
  And I press "Continue"

  Then I should see "Name can’t start with a ‘=’, ‘+’, ‘-’ or ‘@’"

  When I am allowed to make the creator name too long
  When I fill in "Name" with text longer than 255 characters
  And I press "Continue"

  Then I should see "Name is too long"

  When I fill in my details as a creator
  And I fill in my creator contact details
  And I press "Continue"

  Then I should see a heading called "Make sure this is right"

  And I press "Back"
  And I fill in "Name" with "Mr. Wibbledon"

  And I press "Continue"

  Then I should see a heading called "Make sure this is right"

  When I fill in "Email" with ""
  And I press "Yes – this is my email address"
  Then I should see "Email must be completed"
  When I fill in "Email" with "womboid@wimbledon.com"
  And I press "Yes – this is my email address"

  Then I should see "We’ve emailed you a link"
  And a petition should exist with action: "The wombats of wimbledon rock.", state: "pending"
  And there should be a "pending" signature with email "womboid@wimbledon.com" and name "Mr. Wibbledon"

Scenario: Charlie creates a petition with a typo in his email
  Given I start a new petition
  And I fill in the petition details
  And I press "Preview petition"
  And I press "This looks good"
  And I fill in my details as a creator with email "charlie@hotmial.com"
  And I fill in my creator contact details
  And I press "Continue"
  Then my email is autocorrected to "charlie@hotmail.com"
  When I press "Yes – this is my email address"
  Then I should see "We’ve emailed you a link"
  And a petition should exist with action: "The wombats of wimbledon rock.", state: "pending"
  And a signature should exist with email: "charlie@hotmail.com", state: "pending"

Scenario: Charlie creates a petition when his email is autocorrected wrongly
  Given I start a new petition
  And I fill in the petition details
  And I press "Preview petition"
  And I press "This looks good"
  And I fill in my details as a creator with email "charlie@hotmial.com"
  And I fill in my creator contact details
  And I press "Continue"
  Then my email is autocorrected to "charlie@hotmail.com"
  When I fill in "Email" with "charlie@hotmial.com"
  And I press "Yes – this is my email address"
  Then I should see "We’ve emailed you a link"
  And a petition should exist with action: "The wombats of wimbledon rock.", state: "pending"
  And a signature should exist with email: "charlie@hotmial.com", state: "pending"

Scenario: Charlie creates a petition when blocked
  Given the IP address 127.0.0.1 is blocked
  And I start a new petition
  And I fill in the petition details
  And I press "Preview petition"
  And I press "This looks good"
  And I fill in my details as a creator
  And I fill in my creator contact details
  When I press "Continue"
  Then the markup should be valid
  And I am asked to review my email address
  When I press "Yes – this is my email address"
  Then a petition should not exist with action: "The wombats of wimbledon rock.", state: "pending"
  And a signature should not exist with email: "womboid@wimbledon.com", state: "pending"

Scenario: Charlie creates a petition when his IP address is rate limited
  Given the creator rate limit is 1 per hour
  And there are no allowed IPs
  And there are no blocked IPs
  And there are 2 petitions created from this IP address
  And I start a new petition
  And I fill in the petition details
  And I press "Preview petition"
  And I press "This looks good"
  And I fill in my details as a creator
  And I fill in my creator contact details
  When I press "Continue"
  Then the markup should be valid
  And I am asked to review my email address
  When I press "Yes – this is my email address"
  Then I should see "We’ve emailed you a link"
  And a petition should not exist with action: "The wombats of wimbledon rock.", state: "pending"
  And a signature should not exist with email: "womboid@wimbledon.com", state: "pending"
