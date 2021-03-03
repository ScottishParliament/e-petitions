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

  Scenario: Suzie can see the closing date from the index page
    Given a petition "Good times" signed by "CHIC" that is collecting signatures
    When I view all petitions from the home page
    Then I should see "Collecting signatures until"

  Scenario: Suzie can see the closing date from the index page if no petitions are collecting signatures
    Given a petition "Good times" has been closed
    When I view all petitions from the home page
    Then I should see "Under consideration from "

  Scenario: Suzie can see the completion date from the index page
    Given a petition "Good times" has been completed
    When I view all petitions from the home page
    Then I should see "Closed on "

  Scenario: Suzie browses open petitions
    Given a petition "Good Times" signed by "CHIC" that is collecting signatures
    And a petition "Everybody Dance" signed by "CHIC" that is collecting signatures
    And a petition "Le Freak" signed by "CHIC" that is collecting signatures
    When I browse to see only "Collecting signatures" petitions
    Then I should see "3 petitions"
    And I should see the following ordered list of petitions:
      | Le Freak        |
      | Everybody Dance |
      | Good Times      |
    And the markup should be valid

  Scenario: Suzie browses referred petitions and sees them by most recently published
    Given a referred petition exists with action: "Good Times", closed_at: 1.year.ago
    And a referred petition exists with action: "Everybody Dance", closed_at: 2.years.ago
    And a referred petition exists with action: "Le Freak", closed_at: 3.days.ago
    When I browse to see only "Under consideration" petitions
    Then I should see the following ordered list of petitions:
      | Le Freak        |
      | Good Times      |
      | Everybody Dance |

  Scenario: Suzie browses referred petitions and can see when they've been closed
    Given a referred petition exists with action: "Le Freak", closed_at: 3.days.ago
    When I browse to see only "Under consideration" petitions
    Then I should see "Under consideration from"
    And I should see the petition's closed_at timestamp

  Scenario: Suzie browses closed petitions and sees them by most recently completed
    Given a completed petition exists with action: "Good Times", completed_at: 1.year.ago
    And a completed petition exists with action: "Everybody Dance", completed_at: 2.years.ago
    And a completed petition exists with action: "Le Freak", completed_at: 3.days.ago
    When I browse to see only "Closed" petitions
    Then I should see the following ordered list of petitions:
      | Le Freak        |
      | Good Times      |
      | Everybody Dance |

  Scenario: Suzie browses closed petitions and sees them by most recently completed
    Given a completed petition exists with action: "Good Times", completed_at: 1.year.ago
    When I browse to see only "Closed" petitions
    Then I should see "Closed by the Scottish Parliament on"
    Then I should see the petition's completed_at timestamp

  Scenario: Suzie browses open petitions and can see numbering in the list view
    Given a set of 101 petitions
    When I view all petitions from the home page
    Then I should see "2 of 3"
    And I navigate to the next page of petitions
    Then I should see "1 of 3"
    And I should see "3 of 3"
    And I navigate to the next page of petitions
    Then I should see "2 of 3"

  Scenario: Suzie browses petitions collecting signatures and can see the closing date
    Given a petition "Good times" signed by "CHIC" that is collecting signatures
    When I browse to see only "Collecting signatures" petitions
    Then I should see "Good times"
    And I should see "Collecting signatures until"

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
