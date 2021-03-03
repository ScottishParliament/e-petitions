@admin
Feature: Moderator looks at a single petition

  Background:
    Given I am logged in as a moderator

  Scenario Outline: Seeing the correct petition status
    Given a <state> petition "My petition" exists
    When I view all petitions
    And I follow "My petition"
    Then I should see the <status> petition status

    Scenarios:
      | state     | status                |
      | open      | Collecting signatures |
      | closed    | Under consideration   |
      | completed | Closed                |
