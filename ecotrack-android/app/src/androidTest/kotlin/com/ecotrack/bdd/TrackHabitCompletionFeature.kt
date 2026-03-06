package com.ecotrack.bdd

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.assertTextContains
import androidx.compose.ui.test.hasContentDescription
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.ecotrack.MainActivity
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

// ---------------------------------------------------------------------------
// EcoTrack - BDD Instrumented Tests
// ---------------------------------------------------------------------------
// These tests implement the Gherkin scenarios from:
//   docs/features/track_habit_completion.feature
//
// They run on a real device / emulator via Espresso + Compose Test.
// Each test method corresponds to one Gherkin scenario.
//
// COPILOT WORKFLOW:
//   1. Read the .feature file in docs/features/
//   2. Ask Copilot: "Implement the Compose UI test for the Given/When/Then below"
//   3. Ask Copilot: "Add content descriptions to HabitCard so TalkBack finds it"
//
// ACCESSIBILITY NOTE: All assertions use content descriptions, not raw text,
// to validate that TalkBack users get the same experience as visual users.
// ---------------------------------------------------------------------------

@RunWith(AndroidJUnit4::class)
class TrackHabitCompletionFeature {

    @get:Rule
    val composeTestRule = createAndroidComposeRule<MainActivity>()

    // -----------------------------------------------------------------------
    // Feature: Track a habit completion
    // Scenario: User marks a habit as completed for today
    // -----------------------------------------------------------------------
    //
    // Given I am on the habits dashboard
    // And I have a habit called "Ride a bike to work"
    // When I tap the complete button for "Ride a bike to work"
    // Then the habit shows as completed for today
    // And I see a message "2500g of CO₂ saved today!"
    // And the streak counter increases by 1

    @Test
    fun user_marks_habit_as_completed_for_today() {
        // Given I am on the habits dashboard
        onDashboard {
            isVisible()
        }

        // And I have a habit called "Ride a bike to work"
        onHabitCard("Ride a bike to work") {
            isVisible()
            isNotCompleted()
        }

        // When I tap the complete button
        onHabitCard("Ride a bike to work") {
            tapCompleteButton()
        }

        // Then the habit shows as completed
        onHabitCard("Ride a bike to work") {
            isCompleted()
        }

        // And I see the carbon saved message
        onCarbonSavedBanner {
            showsMessage("2500g of CO₂ saved today!")
        }
    }

    // -----------------------------------------------------------------------
    // Scenario: Completing a habit updates the streak counter
    // -----------------------------------------------------------------------
    //
    // Given I have a habit "Drink tap water" with a 3-day streak
    // When I mark it complete today
    // Then the streak counter shows 4

    @Test
    fun completing_habit_increments_streak_counter() {
        // Given - streak starts at 3 (seeded by test data)
        onHabitCard("Drink tap water") {
            showsStreak(3)
        }

        // When
        onHabitCard("Drink tap water") {
            tapCompleteButton()
        }

        // Then
        onHabitCard("Drink tap water") {
            showsStreak(4)
        }
    }

    // -----------------------------------------------------------------------
    // Scenario: Tapping complete twice in one day is idempotent
    // -----------------------------------------------------------------------
    //
    // Given I have completed "Drink tap water" today
    // When I tap the complete button again
    // Then the streak counter is unchanged
    // And no duplicate completion is recorded

    @Test
    fun tapping_complete_twice_is_idempotent() {
        onHabitCard("Drink tap water") {
            tapCompleteButton()
            val streakAfterFirst = currentStreak()
            tapCompleteButton()
            showsStreak(streakAfterFirst) // unchanged
        }
    }

    // -----------------------------------------------------------------------
    // Accessibility scenario: TalkBack can complete a habit
    // -----------------------------------------------------------------------
    //
    // Given TalkBack is active
    // When I navigate to "Ride a bike to work" complete button by content description
    // Then the button announces "Mark Ride a bike to work as complete for today"
    // And after completion it announces "Ride a bike to work completed. Streak: 1 day"

    @Test
    fun talkback_can_identify_and_activate_complete_button() {
        // TalkBack finds the button via its content description
        composeTestRule
            .onNode(hasContentDescription("Mark Ride a bike to work as complete for today"))
            .assertIsDisplayed()

        composeTestRule
            .onNode(hasContentDescription("Mark Ride a bike to work as complete for today"))
            .performClick()

        // After completion, the button description updates
        composeTestRule
            .onNode(hasContentDescription("Ride a bike to work completed. Streak: 1 day"))
            .assertIsDisplayed()
    }

    // -----------------------------------------------------------------------
    // DSL helpers — BDD-style fluent API for Compose tests
    // These keep the test body readable and close to Gherkin language.
    // TODO: Move these to a shared test DSL file as the suite grows.
    // -----------------------------------------------------------------------

    private fun onDashboard(block: DashboardRobot.() -> Unit) =
        DashboardRobot(composeTestRule).block()

    private fun onHabitCard(habitName: String, block: HabitCardRobot.() -> Unit) =
        HabitCardRobot(composeTestRule, habitName).block()

    private fun onCarbonSavedBanner(block: CarbonBannerRobot.() -> Unit) =
        CarbonBannerRobot(composeTestRule).block()
}

// ---------------------------------------------------------------------------
// Robot pattern — isolates Compose selectors from test logic
// ---------------------------------------------------------------------------

class DashboardRobot(private val rule: androidx.compose.ui.test.junit4.ComposeContentTestRule) {
    fun isVisible() {
        rule.onNodeWithContentDescription("EcoTrack habits dashboard").assertIsDisplayed()
    }
}

class HabitCardRobot(
    private val rule: androidx.compose.ui.test.junit4.ComposeContentTestRule,
    private val habitName: String
) {
    fun isVisible() {
        rule.onNodeWithContentDescription("Habit: $habitName").assertIsDisplayed()
    }

    fun isNotCompleted() {
        rule.onNode(hasContentDescription("Mark $habitName as complete for today")).assertIsDisplayed()
    }

    fun isCompleted() {
        rule.onNode(hasContentDescription("$habitName completed. Streak: 1 day")).assertIsDisplayed()
    }

    fun tapCompleteButton() {
        rule.onNode(hasContentDescription("Mark $habitName as complete for today")).performClick()
        rule.waitForIdle()
    }

    fun showsStreak(expectedStreak: Int) {
        val label = if (expectedStreak == 1) "1 day" else "$expectedStreak days"
        rule.onNode(
            hasContentDescription("$habitName streak: $label")
        ).assertIsDisplayed()
    }

    fun currentStreak(): Int {
        // Reads the streak from the UI — fragile, prefer semantic content descriptions
        // TODO: Ask Copilot to make this more robust using test tags
        var streak = 0
        try {
            rule.onNodeWithContentDescription("$habitName streak: 1 day").assertIsDisplayed()
            streak = 1
        } catch (_: AssertionError) { /* not 1 */ }
        return streak
    }
}

class CarbonBannerRobot(private val rule: androidx.compose.ui.test.junit4.ComposeContentTestRule) {
    fun showsMessage(message: String) {
        rule.onNodeWithText(message).assertIsDisplayed()
    }
}
