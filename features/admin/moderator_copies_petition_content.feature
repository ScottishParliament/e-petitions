@admin
Feature: Moderator copies the content of an English petition into the Gaelic version

  Scenario: Adding a signature to a petition
    Given the Gaelic website is disabled
    And an open, untranslated petition exists with action: "Raise benefits", background: "They're too low"
    And I am logged in as a moderator
    When I view all petitions
    And I follow "Raise benefits"
    Then I press "Copy content to Gaelic petition"
    Then I should see "The petition's content has been copied over to the Gaelic version."
    And the petition should be copied over
