Feature: Arnold searches from the home page
  In order to reduce the likelihood of a duplicate petition being made
  As a petition moderator
  I want to prominently show a petition search for the current petitions from the home page

Background:
    Given a pending petition exists with action_en: "Wombles are great", action_gd: "Mae Wombles yn wych"
    And a validated petition exists with action_en: "The Wombles of Wimbledon", action_gd: "Wombles Wimbledon"
    And an open petition exists with action_en: "Uncle Bulgaria", additional_details: "The Wombles are here", action_gd: "Yncl Bwlgaria", additional_details_gd: "Mae'r Wombles yma", closed_at: "1 minute from now"
    And an open petition exists with action_en: "Common People", background: "The Wombles belong to us all", action_gd: "Pobl Gyffredin", background_gd: "Mae'r Wombles yn perthyn i ni i gyd", closed_at: "11 days from now"
    And an open petition exists with action_en: "Overthrow the Wombles", action_gd: "Goresgyn y Wombles", closed_at: "1 year from now"
    And a referred petition exists with action_en: "The Wombles will rock Glasto", action_gd: "Bydd y Wombles yn siglo Glasto", closed_at: "1 minute ago"
    And a rejected petition exists with action_en: "Eavis vs the Wombles", action_gd: "Eavis vs y Wombles"
    And a hidden petition exists with action_en: "The Wombles are profane", action_gd: "Mae'r Wombles yn halogedig"
    And an open petition exists with action_en: "Wombles", action_gd: "Wombles", closed_at: "10 days from now"

Scenario: Arnold searches for petitions in English
  Given I am on the home page
  When I search all petitions for "Wombles"
  Then I should be on the all petitions page
  And I should see my search term "Wombles" filled in the search field
  And I should see "6 petitions"
  And I should see the following search results:
    | Wombles                            | 1 signature                                      |
    | Overthrow the Wombles              | 1 signature                                      |
    | Uncle Bulgaria                     | 1 signature                                      |
    | Common People                      | 1 signature                                      |
    | The Wombles will rock Glasto       | 1 signature Referred to the Petitions Committee  |
    | Eavis vs the Wombles               | Rejected                                         |

@gaelic
Scenario: Arnold searches for petitions in Gaelic
  Given I am on the home page
  When I search all petitions for "Wombles"
  Then I should see my search term "Wombles" filled in the search field
  And I should see "6 deiseb"
  And I should see the following search results:
    | Wombles                            | 1 llofnod                                    |
    | Goresgyn y Wombles                 | 1 llofnod                                    |
    | Yncl Bwlgaria                      | 1 llofnod                                    |
    | Pobl Gyffredin                     | 1 llofnod                                    |
    | Bydd y Wombles yn siglo Glasto     | 1 llofnod Cyfeiriwyd at y Pwyllgor Deisebau  |
    | Eavis vs y Wombles                 | Gwrthodwyd                                   |
  And the markup should be valid
