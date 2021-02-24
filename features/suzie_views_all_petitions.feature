Feature: Suzy Signer views all petitions
  In order to find interesting petitions to sign for a particular area of government
  As Suzy the signer
  I want to look through all the petitions

  Scenario:
    Given a set of petitions
    When I view all petitions from the home page
    Then I should see all petitions
    And the markup should be valid

  Scenario: Suzie can browse with facets
    Given I view all petitions from the home page
    Then I can choose the "Collecting signatures" facet
    And I can choose the "Under consideration" facet
    And I can choose the "Closed" facet

  Scenario: Suzie browses open petitions
    Given a petition "Free the wombles" exists with a signature count of 500
    And a petition "Force supermarkets to give unsold food to charities" exists with a signature count of 500000
    And a petition "Make every monday bank holiday" exists with a signature count of 1000
    When I browse to see only "Collecting signatures" petitions
    Then I should see "3 petitions"
    And I should see the following ordered list of petitions:
     | Make every monday bank holiday                      |
     | Force supermarkets to give unsold food to charities |
     | Free the wombles                                    |
    And the markup should be valid

  Scenario: Suzie browses open petitions and can see numbering in the list view
    Given a set of 101 petitions
    When I view all petitions from the home page
    Then I should see "2 of 3"
    And I navigate to the next page of petitions
    Then I should see "1 of 3"
    And I should see "3 of 3"
    And I navigate to the next page of petitions
    Then I should see "2 of 3"

  Scenario: Downloading the JSON data for petitions
    Given a set of petitions
    And I am on the all petitions page
    Then I should see all petitions
    And the markup should be valid
    When I click the JSON link
    Then I should be on the all petitions JSON page
    And the JSON should be valid

  Scenario: Downloading the CSV data for petitions
    Given a set of petitions
    And I am on the all petitions page
    Then I should see all petitions
    And the markup should be valid
    When I click the CSV link
    Then I should get a download with the filename "all-petitions.csv"
