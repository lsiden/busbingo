Feature: Recognizing winning board states
  In order to create a functioning Bingo game
  As a programmer I need to represent board states
  and determine which board states are winners
  while optimizing the search based on the last tile covered.

  Scenario: No bingo
    Given the following board
      | . | x | . | x | . |
      | x | . | x | . | x |
      | . | x | . | x | . |
      | x | . | x | . | x |
      | . | x | . | x | . |
    When the last tile covered was (2, 3)
    Then I do not have bingo

  @row
  Scenario: Covered row
    Given the following board
      | . | x | . | x | . |
      | x | x | x | x | x |
      | . | x | . | x | . |
      | x | . | x | . | x |
      | . | x | . | x | . |
    When the last tile covered was (1, 3)
    And I do have bingo

  @column
  Scenario: Covered column
    Given the following board
      | . | x | . | x | . |
      | x | . | x | x | x |
      | . | x | . | x | . |
      | x | . | x | x | x |
      | . | x | . | x | . |
    When the last tile covered was (1, 3)
    And I do have bingo

  @rising
  Scenario: Covered rising diagonal
    Given the following board
      | . | x | . | x | x |
      | x | . | x | x | x |
      | . | x | x | x | . |
      | x | x | x | . | x |
      | x | x | . | x | . |
    When the last tile covered was (1, 3)
    Then I do have bingo

  @falling
  Scenario: Covered falling diagonal
    Given the following board
      | x | x | . | x | . |
      | x | x | x | . | x |
      | . | x | x | x | . |
      | x | . | x | x | x |
      | . | x | . | x | x |
    When the last tile covered was (3, 3)
    Then I do have bingo
