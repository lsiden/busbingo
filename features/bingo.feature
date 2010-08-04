Feature: Recognizing winning board states
  In order to create a functioning Bingo game
  As a programmer I need to represent board states
  and determine which board states are winners

@empty
  Scenario: Empty board
    Given the following board
      | . | . | . | . | . |
      | . | . | . | . | . |
      | . | . | . | . | . |
      | . | . | . | . | . |
      | . | . | . | . | . |
    Then I count 0 covered squares
    And I do not have bingo

  Scenario: No bingo
    Given the following board
      | . | x | . | x | . |
      | x | . | x | . | x |
      | . | x | . | x | . |
      | x | . | x | . | x |
      | . | x | . | x | . |
    Then I count 12 covered squares
    And I do not have bingo

  Scenario: Covered row
    Given the following board
      | . | x | . | x | . |
      | x | x | x | x | x |
      | . | x | . | x | . |
      | x | . | x | . | x |
      | . | x | . | x | . |
    Then I count 14 covered squares
    And I do have bingo

  Scenario: Covered column
    Given the following board
      | . | x | . | x | . |
      | x | . | x | x | x |
      | . | x | . | x | . |
      | x | . | x | x | x |
      | . | x | . | x | . |
    Then I count 14 covered squares
    And I do have bingo

  Scenario: Covered rising diagonal
    Given the following board
      | . | x | . | x | x |
      | x | . | x | x | x |
      | . | x | x | x | . |
      | x | x | x | . | x |
      | x | x | . | x | . |
    Then I do have bingo

  Scenario: Covered falling diagonal
    Given the following board
      | x | x | . | x | . |
      | x | x | x | . | x |
      | . | x | x | x | . |
      | x | . | x | x | x |
      | . | x | . | x | x |
    Then I do have bingo
