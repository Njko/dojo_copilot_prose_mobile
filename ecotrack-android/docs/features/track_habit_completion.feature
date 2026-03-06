# EcoTrack - BDD Feature: Track Habit Completion
# Format: Gherkin (Cucumber-compatible)
#
# DOJO NOTE: These scenarios are the source of truth for the feature.
# The instrumented tests in TrackHabitCompletionFeature.kt implement them.
# Copilot can generate test steps if you share this file as context.
#
# USAGE: Ask Copilot —
#   "Given this Gherkin scenario, generate the Compose UI test using Robot pattern"

Feature: Track a habit completion
  As an eco-conscious user
  I want to mark my habits as complete each day
  So that I can track my environmental impact over time

  Background:
    Given I am logged in as "Alice"
    And I have the following habits:
      | Name                    | Category  | Frequency | Carbon saved (g) |
      | Ride a bike to work     | Transport | 5/week    | 2500             |
      | Drink tap water         | Water     | 7/week    | 50               |
      | Eat vegetarian meal     | Food      | 3/week    | 1800             |

  # -------------------------------------------------------------------------
  # Core completion flow
  # -------------------------------------------------------------------------

  Scenario: User marks a habit as completed for today
    Given I am on the habits dashboard
    And "Ride a bike to work" is not completed today
    When I tap the complete button for "Ride a bike to work"
    Then "Ride a bike to work" shows as completed for today
    And I see the message "2500g of CO₂ saved today!"
    And the completion is persisted after app restart

  Scenario: Completing a habit increments the streak counter
    Given "Drink tap water" has been completed for the last 3 consecutive days
    And "Drink tap water" is not completed today
    When I tap the complete button for "Drink tap water"
    Then the streak counter for "Drink tap water" shows "4 days"

  Scenario: Streak resets when a day is missed
    Given "Drink tap water" has been completed for the last 3 consecutive days
    And today is 2 days after the last completion
    When I view the habits dashboard
    Then the streak counter for "Drink tap water" shows "0 days"

  # -------------------------------------------------------------------------
  # Idempotency
  # -------------------------------------------------------------------------

  Scenario: Tapping complete twice in one day is idempotent
    Given "Drink tap water" is not completed today
    When I tap the complete button for "Drink tap water"
    And I tap the complete button for "Drink tap water" again
    Then the streak counter for "Drink tap water" shows "1 day"
    And only one completion is recorded for today

  # -------------------------------------------------------------------------
  # Carbon footprint aggregation
  # -------------------------------------------------------------------------

  Scenario: Weekly carbon savings are aggregated on dashboard
    Given I have completed the following habits this week:
      | Habit                   | Times completed |
      | Ride a bike to work     | 3               |
      | Eat vegetarian meal     | 2               |
    When I open the carbon footprint summary
    Then I see total savings of "11100g of CO₂"
    And I see the equivalent "92 km not driven by car"

  # -------------------------------------------------------------------------
  # Accessibility
  # -------------------------------------------------------------------------

  Scenario: TalkBack user can complete a habit
    Given TalkBack screen reader is enabled
    When I navigate to the complete button using TalkBack
    Then the button announces "Mark Ride a bike to work as complete for today"
    When I activate the button
    Then the button announces "Ride a bike to work completed. Streak: 1 day"
    And the carbon saved toast announces "2500 grams of CO2 saved"

  Scenario: Habit card provides full context to screen readers
    Given TalkBack screen reader is enabled
    When I navigate to the "Ride a bike to work" habit card
    Then TalkBack announces:
      """
      Habit: Ride a bike to work. Category: Transport.
      Frequency: 5 times per week. Streak: 0 days.
      Not completed today.
      """

  # -------------------------------------------------------------------------
  # Eco-conception (battery / network)
  # -------------------------------------------------------------------------

  Scenario: Completion is saved locally without network access
    Given the device has no network connection
    When I tap the complete button for "Ride a bike to work"
    Then "Ride a bike to work" shows as completed for today
    And the completion is queued for sync when connectivity returns

  Scenario: Syncing completions does not drain battery with frequent polling
    Given the device is on battery saver mode
    When completions are pending sync
    Then sync is deferred to the next WorkManager window
    And no foreground service or wake lock is used

  # -------------------------------------------------------------------------
  # Security
  # -------------------------------------------------------------------------

  Scenario: Completion data does not include personally identifiable information in logs
    Given log level is set to DEBUG
    When I tap the complete button for "Ride a bike to work"
    Then no log entry contains the user's email address
    And no log entry contains the user's full name
    And habit IDs in logs are anonymised UUIDs
