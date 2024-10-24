Feature: Suzie views a petition
  In order to read a petition and potentially sign it
  As Suzie the signer
  I want to view a petition of my choice from a list, seeing the vote count, closed and open dates, along with the reason for rejection if applicable

  Scenario: Suzie views a petition gathering sponsors
    Given a validated petition "Spend more money on Defence"
    When I view the petition
    Then I should see "This petition is gathering support"
    And I should see a link called "rules for petitions" linking to "/help#rules"

  Scenario: Suzie views a petition waiting to be moderated
    Given a sponsored petition "Spend more money on Defence"
    When I view the petition
    Then I should see "We’re checking this petition"

  Scenario: Suzie views an open petition
    Given an open petition "Spend more money on Defence"
    When I view the petition
    Then I should see the petition details
    And I should see "Spend more money on Defence - Petitions" in the browser page title
    And I should see the vote count and open dates
    And I should not see "Closed petition"
    And I can share it via Email
    And I can share it via Facebook
    And I can share it via Twitter
    And I can share it via Whatsapp

  Scenario: Suzie views an open, translated petition on the English-only website
    Given the Gaelic website is disabled
    And an open petition exists with action_en: "Raise benefits", background_en: "Because they're too low", action_gd: "Àrdaich buannachdan", background_gd: "Leis gu bheil iad ro ìosal"
    When I go to the petition page for "Raise benefits"
    Then I should see both petitions content

  Scenario: Suzie views an open, untranslated petition on the English-only website
    Given the Gaelic website is disabled
    And an open, untranslated petition exists with action: "Raise benefits", background: "They're too low", previous_action: "I spoke to my MP"
    When I go to the petition page for "Raise benefits"
    Then I should not see both petitions content

  Scenario: Suzie views a petition containing urls, email addresses and html tags
    Given an open petition exists with action: "Defence review", additional_details: "<i>We<i> like http://www.google.com and bambi@gmail.com"
    When I go to the petition page for "Defence review"
    Then the markup should be valid
    And I should see "<i>We<i>"
    And I should see a link called "http://www.google.com" linking to "http://www.google.com"
    And I should see a link called "bambi@gmail.com" linking to "mailto:bambi@gmail.com"

  Scenario: Suzie sees reason for rejection if appropriate
    Given a petition "Please bring back Eldorado" has been rejected with the reason "We like http://www.google.com and bambi@gmail.com"
    When I view the petition
    Then I should see the petition details
    And I should see the reason for rejection
    And I should see "We like http://www.google.com and bambi@gmail.com"
    And I should see a link called "http://www.google.com" linking to "http://www.google.com"
    And I should see a link called "bambi@gmail.com" linking to "mailto:bambi@gmail.com"
    And I should not see the vote count
    And I should see submitted date
    And I cannot sign the petition

  Scenario: Suzie cannot sign a closed petition
    Given a petition "Spend more money on Defence" has been closed
    When I view the petition
    Then I should see the petition details
    And I cannot sign the petition

  Scenario: Suzie sees an 'under consideration' message when viewing a closed petition
    Given a petition "Spend more money on Defence" has been closed
    When I view the petition
    Then I should see "Under consideration"

  Scenario: Suzie sees the creator when viewing a closed petition
    Given a petition "Spend more money on Defence" has been closed
    When I view the petition
    Then I should see the petition creator

  Scenario: Suzie cannot sign a completed petition
    Given a petition "Spend more money on Defence" has been completed
    When I view the petition
    Then I should see the petition details
    And I cannot sign the petition

  Scenario: Suzie sees a 'closed' message when viewing a completed petition
    Given a petition "Spend more money on Defence" has been completed
    When I view the petition
    Then I should see "Closed petition"

  Scenario: Suzie sees the creator when viewing a completed petition
    Given a petition "Spend more money on Defence" has been completed
    When I view the petition
    Then I should see the petition creator

  Scenario: Suzie does not see information about other parliamentary business when there is none
    Given an open petition "Ban Badger Baiting"
    When I view the petition
    Then I should not see "Other parliamentary business"

  Scenario: Suzie sees information about other parliamentary business when there is some
    Given a petition "Ban Badger Baiting" has other parliamentary business
    When I view the petition
    Then I should see the other parliamentary business items

  Scenario: Suzie does not see information about other parliamentary business when it is disabled
    Given a petition "Ban Badger Baiting" has other parliamentary business
    And the site has disabled other parliamentary business
    When I view the petition
    Then I should not see the other parliamentary business items

  Scenario: Suzie sees information about the outcomes when viewing a debated petition
    Given a petition "Ban Badger Baiting" has been debated 2 days ago
    When I view the petition
    Then I should see the date of the debate is 2 days ago
    And I should see links to the transcript, video and research
    And I should see a summary of the debate outcome

  Scenario: Suzie views a petition which has a scheduled debate date
    Given the date is the "01/08/2015"
    And a petition "Spend more money on Defence" with a scheduled debate date of "18/08/2015"
    When I view the petition
    Then I should see "Parliament will debate this petition on 18 August 2015. You’ll be able to watch online on Scottish Parliament TV."

  Scenario: Suzie views a petition which will not be debated
    Given a petition "Spend more money on Defence" with a negative debate outcome
    When I view the petition
    Then I should see "The Citizen Participation and Public Petitions Committee decided not to refer this petition for a debate"

  Scenario: Suzie views a petition which was debated yesterday
    Given the date is the "27/10/2015"
    And a petition "Free the wombles" has been debated yesterday
    When I view the petition
    Then I should see "Parliament debated this petition on 26 October 2015"

  Scenario: Suzie does not see information about future signature targets when viewing a closed petition
    Given a petition "Spend more money on Defence" has been closed
    When I view the petition
    Then I should not see "At 50 signatures…"
    Then I should not see "At 5,000 signatures…"

  Scenario: Suzie does not see information about future signature targets when viewing a completed petition
    Given a petition "Spend more money on Defence" has been completed
    When I view the petition
    Then I should not see "At 50 signatures…"
    Then I should not see "At 5,000 signatures…"

  Scenario: Suzie sees information about future signature targets when viewing an open petition which has not passed the threshold for referral or debate
    Given an open petition "Spend more money on Defence"
    When I view the petition
    Then I should see "At 5,000 signatures…"

  @javascript
  Scenario: Suzie does not see information about a future signature targets when viewing an open petition which has passed the threshold for referral and debate
    Given a petition "Spend more money on Defence" exists with a debate outcome and with referral threshold met
    When I view the petition
    Then I should not see "At 50 signatures…"
    Then I should not see "At 5,000 signatures…"
    And I should see a summary of the debate outcome

  Scenario: Suzie sees a closed petition that collected signatures
    Given a closed petition "Spend more money on science" that is collecting signatures
    When I view the petition
    Then I should see "1 signature"

  Scenario: Suzie sees a closed petition that did not collect signatures
    Given a closed petition "Spend more money on science" that is not collecting signatures
    When I view the petition
    Then I should see " This petition did not collect signatures"

  Scenario Outline: Suzie sees the correct wording for petitions with a ScotParl link
    Given a <state> petition "My petition" exists
    And the petition has a ScotParl link "https://www.parliament.scot/"
    When I view the petition
    Then I should see a link called "<copy>" linking to "https://www.parliament.scot/"

    Scenarios:
      | state     | copy                                                                                                  |
      | closed    | Find out about the Citizen Participation and Public Petitions Committee’s discussion of this petition |
      | completed | Find out about the decisions taken on this petition                                                   |

  Scenario: Suzie sees a message when viewing a petition and signature collection has been paused
    Given petitions are not collecting signatures
    And an open petition "Spend more money on Defence"
    When I view the petition
    Then I should see "This petition has stopped collecting signatures"
    And I cannot sign the petition

  Scenario: Suzie sees a message when viewing a petition and a message has been enabled
    Given a petition page message has been enabled
    And an open petition "Spend more money on Defence"
    When I view the petition
    Then I should see "The Scottish Parliament Election will be held on 6 May 2021"
    And I can sign the petition

  Scenario: Suzie sees a message when viewing a closed petition and a message has been enabled
    Given a petition page message has been enabled
    And a closed petition "Spend more money on Defence"
    When I view the petition
    Then I should see "The Scottish Parliament Election will be held on 6 May 2021"
    And I cannot sign the petition

  Scenario: Suzie sees previous action details on petitions created before 1 Jan 2024
    Given an open petition "Ban Badger Baiting" with a previous action of "Written to my MSP" was created on "2023/12/12"
    When I view the petition
    Then I should see "Written to my MSP"

  Scenario: Suzie sees previous action details on petitions created before 1 Jan 2024
    Given an open petition "Ban Badger Baiting" with a previous action of "Written to my MSP" was created on "2024/01/02"
    When I view the petition
    Then I should not see "Written to my MSP"
