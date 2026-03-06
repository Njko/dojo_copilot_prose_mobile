package com.ecotrack.domain.model

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import java.time.LocalDate

// ---------------------------------------------------------------------------
// EcoTrack - TDD Starter: HabitTest
// ---------------------------------------------------------------------------
// RED phase: ALL tests in this file are currently FAILING.
// Your job (with Copilot) is to make them GREEN without changing the tests.
//
// PROSE methodology applied here:
//   P - Progressive: tests are ordered from simple to complex
//   R - Reduced Scope: only Habit domain logic, no Android framework
//   O - Orchestrated: each test sets up its own fixture via `buildHabit()`
//   S - Safety: no network, no DB, pure unit tests (fast, deterministic)
//   E - Explicit: test names describe the business rule being verified
//
// TDD WORKFLOW:
//   1. Run tests => RED (all fail with NotImplementedError)
//   2. Ask Copilot to implement the method under test
//   3. Run tests => GREEN
//   4. Refactor with Copilot assistance
//   5. Run tests again => still GREEN
// ---------------------------------------------------------------------------

@RunWith(RobolectricTestRunner::class)
class HabitTest {

    // -----------------------------------------------------------------------
    // Fixtures
    // -----------------------------------------------------------------------

    private fun buildHabit(
        name: String = "Ride a bike to work",
        frequencyPerWeek: Int = 5,
        category: HabitCategory = HabitCategory.TRANSPORT,
        carbonSavedGrams: Int = 2500,
        completions: List<HabitCompletion> = emptyList()
    ): Habit = Habit(
        name = name,
        description = "Use a bicycle instead of a car for commuting",
        category = category,
        frequencyPerWeek = frequencyPerWeek,
        ecoImpact = EcoImpact(carbonSavedGrams = carbonSavedGrams),
        completions = completions
    )

    private fun completionsForDays(habit: Habit, vararg daysAgo: Long): List<HabitCompletion> =
        daysAgo.map { days ->
            HabitCompletion(habitId = habit.id, completedOn = LocalDate.now().minusDays(days))
        }

    // -----------------------------------------------------------------------
    // Habit invariants
    // -----------------------------------------------------------------------

    @Test
    fun `habit name must not be blank`() {
        val exception = runCatching { buildHabit(name = "  ") }.exceptionOrNull()
        assertTrue("Expected IllegalArgumentException for blank name", exception is IllegalArgumentException)
    }

    @Test
    fun `frequency must be between 1 and 7`() {
        val tooLow = runCatching { buildHabit(frequencyPerWeek = 0) }.exceptionOrNull()
        val tooHigh = runCatching { buildHabit(frequencyPerWeek = 8) }.exceptionOrNull()
        assertTrue("Expected exception for frequency 0", tooLow is IllegalArgumentException)
        assertTrue("Expected exception for frequency 8", tooHigh is IllegalArgumentException)
    }

    @Test
    fun `habit with valid frequency 1 to 7 is created successfully`() {
        (1..7).forEach { freq ->
            val habit = buildHabit(frequencyPerWeek = freq)
            assertEquals(freq, habit.frequencyPerWeek)
        }
    }

    // -----------------------------------------------------------------------
    // currentStreak() — IMPLEMENT THIS METHOD IN DomainModels.kt
    // -----------------------------------------------------------------------

    @Test
    fun `streak is zero when no completions`() {
        val habit = buildHabit()
        // TODO: implement Habit.currentStreak()
        assertEquals(0, habit.currentStreak())
    }

    @Test
    fun `streak is one when completed only today`() {
        val habit = buildHabit()
        val withCompletion = habit.copy(
            completions = completionsForDays(habit, 0L)
        )
        assertEquals(1, withCompletion.currentStreak())
    }

    @Test
    fun `streak counts consecutive days ending today`() {
        val habit = buildHabit()
        val withCompletions = habit.copy(
            completions = completionsForDays(habit, 0L, 1L, 2L, 3L)
        )
        assertEquals(4, withCompletions.currentStreak())
    }

    @Test
    fun `streak resets when a day is missed`() {
        val habit = buildHabit()
        // days 0 (today), 1 (yesterday), then gap, then 3, 4
        val withCompletions = habit.copy(
            completions = completionsForDays(habit, 0L, 1L, 3L, 4L)
        )
        assertEquals(2, withCompletions.currentStreak())
    }

    @Test
    fun `streak is zero when last completion was two or more days ago`() {
        val habit = buildHabit()
        val withCompletions = habit.copy(
            completions = completionsForDays(habit, 2L, 3L, 4L)
        )
        assertEquals(0, withCompletions.currentStreak())
    }

    // -----------------------------------------------------------------------
    // completionRateForWeek() — IMPLEMENT THIS METHOD IN DomainModels.kt
    // -----------------------------------------------------------------------

    @Test
    fun `completion rate is 0 percent when no completions this week`() {
        val habit = buildHabit(frequencyPerWeek = 5)
        val weekStart = LocalDate.now().with(java.time.DayOfWeek.MONDAY)
        // completions from previous week — should not count
        val pastCompletions = (1L..3L).map { days ->
            HabitCompletion(habitId = habit.id, completedOn = weekStart.minusDays(days))
        }
        val withPastCompletions = habit.copy(completions = pastCompletions)
        assertEquals(0.0, withPastCompletions.completionRateForWeek(weekStart), 0.001)
    }

    @Test
    fun `completion rate is 100 percent when all target completions done`() {
        val habit = buildHabit(frequencyPerWeek = 3)
        val weekStart = LocalDate.now().with(java.time.DayOfWeek.MONDAY)
        val completions = listOf(
            HabitCompletion(habitId = habit.id, completedOn = weekStart),
            HabitCompletion(habitId = habit.id, completedOn = weekStart.plusDays(1)),
            HabitCompletion(habitId = habit.id, completedOn = weekStart.plusDays(2))
        )
        val withCompletions = habit.copy(completions = completions)
        assertEquals(1.0, withCompletions.completionRateForWeek(weekStart), 0.001)
    }

    @Test
    fun `completion rate is capped at 100 percent even with extra completions`() {
        val habit = buildHabit(frequencyPerWeek = 2)
        val weekStart = LocalDate.now().with(java.time.DayOfWeek.MONDAY)
        // 4 completions but target is 2 — rate should be 1.0, not 2.0
        val completions = (0L..3L).map { days ->
            HabitCompletion(habitId = habit.id, completedOn = weekStart.plusDays(days))
        }
        val withCompletions = habit.copy(completions = completions)
        assertEquals(1.0, withCompletions.completionRateForWeek(weekStart), 0.001)
    }

    // -----------------------------------------------------------------------
    // EcoImpact — value object arithmetic
    // -----------------------------------------------------------------------

    @Test
    fun `ecoImpact addition combines all fields`() {
        val a = EcoImpact(carbonSavedGrams = 100, waterSavedMilliliters = 500, energySavedWh = 20)
        val b = EcoImpact(carbonSavedGrams = 200, waterSavedMilliliters = 300, energySavedWh = 10)
        val combined = a + b
        assertEquals(300, combined.carbonSavedGrams)
        assertEquals(800, combined.waterSavedMilliliters)
        assertEquals(30, combined.energySavedWh)
    }

    @Test
    fun `ecoImpact rejects negative carbon saved`() {
        val exception = runCatching {
            EcoImpact(carbonSavedGrams = -1)
        }.exceptionOrNull()
        assertTrue("Expected IllegalArgumentException for negative carbon", exception is IllegalArgumentException)
    }

    // -----------------------------------------------------------------------
    // CarbonFootprint — TODO exercise
    // -----------------------------------------------------------------------

    @Test
    fun `carbonFootprint totalSavedKg converts grams correctly`() {
        val footprint = CarbonFootprint(
            userId = UserId(),
            periodStart = LocalDate.now().minusDays(7),
            periodEnd = LocalDate.now(),
            totalSavedGrams = 12_000
        )
        assertEquals(12.0, footprint.totalSavedKg, 0.001)
    }

    @Test
    fun `carbonFootprint equivalent returns meaningful car km comparison`() {
        // 12,000g saved / 120g per km = 100 km not driven
        val footprint = CarbonFootprint(
            userId = UserId(),
            periodStart = LocalDate.now().minusDays(7),
            periodEnd = LocalDate.now(),
            totalSavedGrams = 12_000
        )
        // TODO: implement CarbonFootprint.equivalent()
        val equivalent = footprint.equivalent()
        assertEquals(100.0, equivalent.kmNotDrivenByCar, 0.1)
    }

    // -----------------------------------------------------------------------
    // User — domain invariants
    // -----------------------------------------------------------------------

    @Test
    fun `user display name must not be blank`() {
        val exception = runCatching {
            User(displayName = "")
        }.exceptionOrNull()
        assertTrue(exception is IllegalArgumentException)
    }

    @Test
    fun `user display name must not exceed 50 characters`() {
        val exception = runCatching {
            User(displayName = "A".repeat(51))
        }.exceptionOrNull()
        assertTrue(exception is IllegalArgumentException)
    }

    @Test
    fun `habit complete marks today as done`() {
        val habit = buildHabit()
        assertFalse(habit.isCompletedToday())
        val completed = habit.complete()
        assertTrue(completed.isCompletedToday())
    }

    @Test
    fun `completing a habit is immutable - original is unchanged`() {
        val original = buildHabit()
        val completed = original.complete()
        assertFalse("Original habit should not be modified", original.isCompletedToday())
        assertTrue("New habit instance should be completed", completed.isCompletedToday())
    }
}
