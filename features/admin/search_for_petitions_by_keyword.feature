@admin
Feature: Maggie searches for petitions by keyword
  In order to find petitions containing a certain keyword
  As Maggie
  I would like to be able to enter a keyword, and see all petitions that have the word in their action, background or supporting details

  Background:
    Given I am logged in as a moderator

  Scenario: When searching for keyword, it returns all petitions with keyword in action OR background OR additional_details
    Given an open petition exists with action_en: "Raise benefits", action_gd: "Àrdaich buannachdan", background_en: "Because they're too low", background_gd: "Leis gu bheil iad ro ìosal"
    And an open petition exists with action_en: "Help the poor", background_en: "Need higher benefits", action_gd: "Cuidich na bochdan", background_gd: "Feum air buannachdan nas àirde"
    And an open petition exists with action_en: "Help the homeless", background_en: "Could raise benefits", action_gd: "Cuidich na daoine gun dachaigh", background_gd: "A dh ’fhaodadh buannachdan a thogail"
    And an open petition exists with action_en: "Petition about something else", background_en: "Something else", action_gd: "Athchuinge mu rudeigin eile", background_gd: "Rud eile"
    When I search for petitions with keyword "benefits"
    Then I should see the following list of petitions:
          | Help the homeless |
          | Help the poor     |
          | Raise benefits    |
    When I search for petitions with keyword "buannachdan"
    Then I should see the following list of petitions:
          | Help the homeless |
          | Help the poor     |
          | Raise benefits    |

  Scenario: When searching for keyword, it returns all petitions no matter what petition state
    Given an open petition exists with action: "My open petition about benefits"
    And a closed petition exists with action: "My closed petition about benefits"
    And a rejected petition exists with action: "My rejected petition about benefits"
    And a hidden petition exists with action: "My hidden petition about benefits"
    And an open petition exists with action: "My open petition about something else"
    When I search for petitions with keyword "benefits"
    Then I should see the following list of petitions:
      | My hidden petition about benefits   |
      | My rejected petition about benefits |
      | My open petition about benefits     |
      | My closed petition about benefits   |

  Scenario: A user can search by keyword from the admin hub
    Given an open petition exists with action: "Raise benefits"
    And an open petition exists with action: "Help the poor", background: "Need higher benefits"
    And an open petition exists with action: "Help the homeless", background: "Could raise benefits"
    And an open petition exists with action: "Petition about something else"
    When I search for petitions with keyword "benefits" from the admin hub
    Then I should see the following list of petitions:
          | Help the homeless |
          | Help the poor     |
          | Raise benefits    |
