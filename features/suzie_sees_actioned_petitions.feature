Feature: Suzie sees actioned petitions
  In order to make the site more engaging for browsing
  As Suzie the signer
  I want to see counts and links to petitions that have been actioned

  Scenario: There are no actioned petitions
    Given I am on the home page
    Then I should see an empty open petitions section
    And I should see an empty referral threshold section
    And I should see an empty debate threshold section

  Scenario: There are petitions referred to the committee
    Given there are 2 petitions that have been referred to the committee
    And I am on the home page
    Then I should see 2 petitions counted in the referral threshold section
    And I should see 2 petitions listed in the referral threshold section
    And I should see an empty debate threshold section

  Scenario: There are petitions debated by Parliament
    Given there are 3 petitions debated by Parliament
    And I am on the home page
    And I should see 3 petitions counted in the debate threshold section
    And I should see 3 petitions listed in the debate threshold section

  Scenario: There are petitions referred to the committee and petitions debated by Parliament
    Given there are 5 petitions that have been referred to the committee
    And there are 2 petitions debated by Parliament
    And I am on the home page
    Then I should see 5 petitions counted in the referral threshold section
    And I should see 4 petitions listed in the referral threshold section
    And I should see 2 petitions counted in the debate threshold section
    And I should see 2 petitions listed in the debate threshold section

  Scenario: There are petitions debated by Parliament with video, transcript and debate pack urls
    Given there is 1 petition debated by Parliament with a transcript url
    And there is 1 petition debated by Parliament with both video and transcript urls
    And there is 1 petition debated by Parliament with all debate outcome urls
    And I am on the home page
    Then I should see 2 debated petition video links
    And I should see 3 debated petition transcript links
    And I should see 1 debated petition debate pack links
    And I should see 3 petitions counted in the debate threshold section
    And I should see 3 petitions listed in the debate threshold section

  Scenario: There was a petition debated without any debate outcome
    Given a petition "Free the wombles" has been debated yesterday
    And a petition "Ban Badger Baiting" has been debated 12 days ago
    And I am on the home page
    Then I should see "Ban Badger Baiting"
    And I should not see "Free the wombles"
