Feature: Arnold searches from the home page
  In order to reduce the likelihood of a duplicate petition being made
  As a petition moderator
  I want to prominently show a petition search for the current petitions from the home page

Background:
    Given a pending petition exists with action_en: "Wombles are great", action_gd: "Tha Wombles sgoinneil"
    And a validated petition exists with action_en: "The Wombles of Wimbledon", action_gd: "Wombles Wimbledon"
    And an open petition exists with action_en: "Uncle Bulgaria", additional_details: "The Wombles are here", action_gd: "Uncle Bulgaria", additional_details_gd: "Tha na Wombles an seo", closed_at: "1 minute from now"
    And an open petition exists with action_en: "Common People", background: "The Wombles belong to us all", action_gd: "Daoine Cumanta", background_gd: "Buinidh na Wombles dhuinn uile", closed_at: "11 days from now"
    And an open petition exists with action_en: "Overthrow the Wombles", action_gd: "Thoir thairis na Wombles", closed_at: "1 year from now"
    And a referred petition exists with action_en: "The Wombles will rock Glasto", action_gd: "Bidh na Wombles a ’creag Glasto", closed_at: "1 minute ago"
    And a rejected petition exists with action_en: "Eavis vs the Wombles", action_gd: "Eavis vs na Wombles"
    And a hidden petition exists with action_en: "The Wombles are profane", action_gd: "Tha na Wombles gruamach"
    And an open petition exists with action_en: "Wombles", action_gd: "Wombles", closed_at: "10 days from now"

Scenario: Arnold searches for petitions in English
  Given I am on the home page
  When I search all petitions for "Wombles"
  Then I should be on the all petitions page
  And I should see my search term "Wombles" filled in the search field
  And I should see "6 petitions"
  And I should see the following search results:
    | Wombles                      |                          |
    | Overthrow the Wombles        |                          |
    | Uncle Bulgaria               |                          |
    | Common People                |                          |
    | The Wombles will rock Glasto | Under consideration from |
    | Eavis vs the Wombles         | Rejected                 |

@gaelic
Scenario: Arnold searches for petitions in Gaelic
  Given I am on the home page
  When I search all petitions for "Wombles"
  Then I should see my search term "Wombles" filled in the search field
  And I should see "6 petitions"
  And I should see the following search results:
    | Wombles                         |                          |
    | Thoir thairis na Wombles        |                          |
    | Uncle Bulgaria                  |                          |
    | Daoine Cumanta                  |                          |
    | Bidh na Wombles a ’creag Glasto | Under consideration from |
    | Eavis vs na Wombles             | Rejected                 |
  And the markup should be valid
