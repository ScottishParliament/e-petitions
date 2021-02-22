Feature: Suzy Singer searches by free text
  In order to find interesting petitions to sign for a particular area of government
  As Suzy the signer
  I want to search against petition action, background, supporting details

  Background:
    Given the date is the "21 April 2011 12:00"
    And a pending petition exists with action_en: "Wombles are great", action_gd: "Tha Wombles sgoinneil"
    And a validated petition exists with action_en: "The Wombles of Wimbledon", action_gd: "Wombles Wimbledon"
    And an open petition exists with action_en: "Uncle Bulgaria", additional_details: "The Wombles are here", action_gd: "Uncle Bulgaria", additional_details_gd: "Tha na Wombles an seo", closed_at: "1 minute from now"
    And an open petition exists with action_en: "Common People", background: "The Wombles belong to us all", action_gd: "Daoine Cumanta", background_gd: "Buinidh na Wombles dhuinn uile", closed_at: "11 days from now"
    And an open petition exists with action_en: "Overthrow the Wombles", action_gd: "Thoir thairis na Wombles", closed_at: "1 year from now"
    And a referred petition exists with action_en: "The Wombles will rock Glasto", action_gd: "Bidh na Wombles a ’creag Glasto", closed_at: "1 minute ago"
    And a rejected petition exists with action_en: "Eavis vs the Wombles", action_gd: "Eavis vs na Wombles"
    And a hidden petition exists with action_en: "The Wombles are profane", action_gd: "Tha na Wombles gruamach"
    And an open petition exists with action_en: "Wombles", action_gd: "Wombles", closed_at: "10 days from now"

    # debated
    Given a petition "Ban Badger Baiting" has been debated 2 days ago
    Given a petition "Leave EU" has been debated 18 days ago

  Scenario: Search for all visible petitions
    When I search for "All petitions" with "Wombles"
    Then I should see my search term "Wombles" filled in the search field
    And I should see "6 petitions"
    And I should see the following search results:
      | Wombles                            | 1 signature                                     |
      | Overthrow the Wombles              | 1 signature                                     |
      | Uncle Bulgaria                     | 1 signature                                     |
      | Common People                      | 1 signature                                     |
      | The Wombles will rock Glasto       | 1 signature Referred to the Petitions Committee |
      | Eavis vs the Wombles               | Rejected                                        |
    And the markup should be valid

  @gaelic
  Scenario: Search for all visible petitions in Gaelic
    When I search for "All petitions" with "Wombles"
    Then I should see my search term "Wombles" filled in the search field
    And I should see "6 petitions"
    And I should see the following search results:
      | Wombles                            | 1 signature                                     |
      | Thoir thairis na Wombles           | 1 signature                                     |
      | Uncle Bulgaria                     | 1 signature                                     |
      | Daoine Cumanta                     | 1 signature                                     |
      | Bidh na Wombles a ’creag Glasto    | 1 signature Referred to the Petitions Committee |
      | Eavis vs na Wombles                | Rejected                                        |
    And the markup should be valid

  Scenario: Search for petitions collecting signatures
    When I search for "Collecting signatures" with "Wombles"
    Then I should see my search term "Wombles" filled in the search field
    And I should see "4 petitions"
    And I should not see "Wombles are great"
    And I should not see "The Wombles of Wimbledon"
    But I should see the following search results:
      | Wombles                            | 1 signature |
      | Overthrow the Wombles              | 1 signature |
      | Uncle Bulgaria                     | 1 signature |
      | Common People                      | 1 signature |
    And the markup should be valid

  Scenario: See search counts
    When I go to the petitions page
    And I fill in "Wombles" as my search term
    And I press "Search"
    Then I should see a "collecting signatures" petition count of 4

  Scenario: Search for open petitions using multiple search terms
    When I search for "Collecting signatures" with "overthrow the"
    Then I should see the following search results:
      | Overthrow the Wombles | 1 signature |

  @gaelic
  Scenario: Search for open petitions using multiple search terms in Gaelic
    When I search for "All petitions" with "Thoir thairis"
    Then I should see the following search results:
      | Thoir thairis na Wombles | 1 signature |

  Scenario: Search for petitions under consideration
    When I search for "Under consideration" with "WOMBLES"
    Then I should see the following search results:
      | The Wombles will rock Glasto | 1 signature          |

  Scenario: Paginate through open petitions
    Given 51 open petitions exist with action: "International development spending"
    When I search for "Collecting signatures" with "International"
    And I follow "Next"
    Then I should see 1 petition
    And I follow "Previous"
    Then I should see 50 petitions
