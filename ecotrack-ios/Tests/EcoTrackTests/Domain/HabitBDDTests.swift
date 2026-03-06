// HabitBDDTests.swift
// EcoTrackTests - BDD Scenarios (Given / When / Then)
// Swift 6 / iOS 18
//
// BDD APPROACH: We use plain XCTest with structured Given/When/Then naming
// and helper methods to express behaviour in human-readable terms.
//
// WHY NOT Quick/Nimble? For a 1-hour dojo, zero extra dependencies keeps
// onboarding fast. The same patterns apply if participants prefer Quick/Nimble.
//
// NAMING CONVENTION:
//   test_<subject>_<condition>_<expectedBehaviour>
//   OR  test_given<Context>_when<Action>_then<Outcome>
//
// COPILOT TIP: Select a Given/When/Then comment block and ask:
// "Generate XCTest assertions for this BDD scenario"

import XCTest
@testable import EcoTrack

// MARK: - BDD: Habit Completion Feature

/// Feature: Eco-habit completion tracking
/// As an eco-conscious user
/// I want to record when I complete an eco-friendly habit
/// So that I can track my environmental impact over time
final class HabitCompletionBDDTests: XCTestCase {

    // MARK: Setup

    private var userID: UserID!

    override func setUp() {
        super.setUp()
        userID = UserID()
    }

    // -------------------------------------------------------------------------
    // Scenario 1: First-time habit completion
    // -------------------------------------------------------------------------
    // Given I have a cycling habit with no prior completions
    // When I mark it as complete today
    // Then my streak becomes 1
    // And the habit shows as completed today
    // And 2.5 kg CO₂ is recorded as saved
    func test_givenFreshHabit_whenCompletedToday_thenStreakIsOneAndCarbonAccumulates() throws {
        // Given
        let habit = try givenACyclingHabitWithNoCompletions()

        // When
        let completedHabit = try whenCompletingHabit(habit, on: Date())

        // Then
        thenStreakEquals(1, for: completedHabit)
        thenHabitIsCompletedToday(completedHabit)
        thenCarbonSavedEquals(kilograms: 2.5, for: completedHabit)
    }

    // -------------------------------------------------------------------------
    // Scenario 2: Duplicate completion on the same day
    // -------------------------------------------------------------------------
    // Given I have already completed my cycling habit today
    // When I try to mark it as complete again today
    // Then I receive an "already completed today" error
    // And the completion count remains 1
    func test_givenAlreadyCompletedToday_whenCompletingAgain_thenAlreadyCompletedError() throws {
        // Given
        let habit = try givenACyclingHabitWithNoCompletions()
        let alreadyCompleted = try whenCompletingHabit(habit, on: Date())

        // When / Then
        thenCompletingAgainTodayThrows(.alreadyCompletedToday, for: alreadyCompleted)
        XCTAssertEqual(alreadyCompleted.completions.count, 1,
            "Completion count must remain 1 after rejected duplicate")
    }

    // -------------------------------------------------------------------------
    // Scenario 3: Multi-day streak building
    // -------------------------------------------------------------------------
    // Given I have completed my habit for the past 2 days
    // When I complete it again today
    // Then my streak is 3
    func test_givenTwoDayHistory_whenCompletedToday_thenStreakIsThree() throws {
        // Given
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let dayBefore = Calendar.current.date(byAdding: .day, value: -2, to: today)!

        var habit = try givenACyclingHabitWithNoCompletions()
        habit = try habit.completing(on: dayBefore)
        habit = try habit.completing(on: yesterday)

        // When
        let completedHabit = try whenCompletingHabit(habit, on: today)

        // Then
        thenStreakEquals(3, for: completedHabit)
    }

    // -------------------------------------------------------------------------
    // Scenario 4: Streak broken by a missed day
    // -------------------------------------------------------------------------
    // Given I completed my habit 3 days ago but missed yesterday and the day before
    // When I complete it today
    // Then my streak is 1 (restarted)
    func test_givenBrokenStreak_whenCompletedToday_thenStreakRestartsAtOne() throws {
        // Given
        let today = Date()
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: today)!

        var habit = try givenACyclingHabitWithNoCompletions()
        habit = try habit.completing(on: threeDaysAgo)

        // When
        let completedHabit = try whenCompletingHabit(habit, on: today)

        // Then
        thenStreakEquals(1, for: completedHabit,
            message: "Streak should restart at 1 after a missed day")
    }

    // -------------------------------------------------------------------------
    // Scenario 5: Future completion is rejected
    // -------------------------------------------------------------------------
    // Given I have a cycling habit
    // When I try to mark it complete for tomorrow's date
    // Then I receive a "future completion" error
    func test_givenValidHabit_whenCompletingWithFutureDate_thenFutureCompletionError() throws {
        // Given
        let habit = try givenACyclingHabitWithNoCompletions()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!

        // When / Then
        XCTAssertThrowsError(
            try habit.completing(on: tomorrow),
            "Expected futureCompletion error"
        ) { error in
            XCTAssertEqual(error as? HabitError, .futureCompletion,
                "Expected HabitError.futureCompletion, got \(error)")
        }
    }

    // -------------------------------------------------------------------------
    // Scenario 6: Completion with a personal note
    // -------------------------------------------------------------------------
    // Given I have a cycling habit
    // When I complete it today with the note "Used the new bike path"
    // Then the note is stored on the completion
    func test_givenValidHabit_whenCompletedWithNote_thenNoteIsRecorded() throws {
        // Given
        let habit = try givenACyclingHabitWithNoCompletions()
        let note = "Used the new bike path along the river"

        // When
        let completed = try habit.completing(on: Date(), note: note)

        // Then
        XCTAssertEqual(completed.completions.first?.note, note,
            "Note should be attached to the completion record")
    }
}

// MARK: - BDD: Habit Creation Feature

/// Feature: Creating a new eco habit
/// As a new user
/// I want to create an eco-friendly habit with a category and frequency
/// So that I can start tracking my environmental contributions
final class HabitCreationBDDTests: XCTestCase {

    private var userID: UserID!

    override func setUp() {
        super.setUp()
        userID = UserID()
    }

    // -------------------------------------------------------------------------
    // Scenario 1: Successfully creating a valid habit
    // -------------------------------------------------------------------------
    // Given I provide a valid title, category, and frequency
    // When I create the habit
    // Then the habit exists with zero completions and zero streak
    func test_givenValidParameters_whenCreatingHabit_thenHabitIsInitialised() throws {
        // Given
        let title = "Take shorter showers"
        let category = HabitCategory.water
        let frequency = Frequency.daily
        let impact = EcoImpact(
            co2SavedPerCompletion: CarbonFootprint(kilograms: 0.1),
            description: "Saves 10L of hot water"
        )

        // When
        let habit = try Habit(
            userID: userID,
            title: title,
            category: category,
            targetFrequency: frequency,
            ecoImpact: impact
        )

        // Then
        XCTAssertEqual(habit.title, title)
        XCTAssertEqual(habit.category, category)
        XCTAssertEqual(habit.completions.count, 0, "New habit should have no completions")
        XCTAssertEqual(habit.currentStreak, 0, "New habit should have zero streak")
        XCTAssertFalse(habit.isCompletedToday, "New habit should not be completed today")
    }

    // -------------------------------------------------------------------------
    // Scenario 2: Empty title is rejected
    // -------------------------------------------------------------------------
    // Given I provide a blank title
    // When I try to create the habit
    // Then I receive an "empty title" validation error
    func test_givenBlankTitle_whenCreatingHabit_thenValidationErrorIsThrown() {
        // Given
        let blankTitles = ["", "   ", "\t\n"]

        // When / Then
        for title in blankTitles {
            XCTAssertThrowsError(
                try Habit(
                    userID: userID,
                    title: title,
                    category: .food,
                    targetFrequency: .daily,
                    ecoImpact: EcoImpact(co2SavedPerCompletion: .zero, description: "")
                ),
                "Expected emptyTitle error for title: '\(title)'"
            ) { error in
                XCTAssertEqual(error as? HabitError, .emptyTitle)
            }
        }
    }

    // -------------------------------------------------------------------------
    // Scenario 3: Invalid frequency is rejected
    // -------------------------------------------------------------------------
    // Given I provide a frequency of zero times per period
    // When I try to create the habit
    // Then I receive an "invalid frequency" error
    func test_givenZeroFrequency_whenCreatingHabit_thenInvalidFrequencyError() {
        XCTAssertThrowsError(
            try Frequency(timesPerPeriod: 0, period: .daily)
        ) { error in
            XCTAssertEqual(error as? HabitError, .invalidFrequency)
        }
    }
}

// MARK: - BDD: Carbon Footprint Calculation Feature

/// Feature: Carbon footprint accumulation
/// As an eco-conscious user
/// I want to see my total CO₂ savings across all completions
/// So that I understand my real-world environmental impact
final class CarbonFootprintBDDTests: XCTestCase {

    private var userID: UserID!

    override func setUp() {
        super.setUp()
        userID = UserID()
    }

    // -------------------------------------------------------------------------
    // Scenario: Accumulated savings over multiple completions
    // -------------------------------------------------------------------------
    // Given a habit saves 2.5 kg CO₂ per completion
    // When the habit is completed 4 times
    // Then the total carbon saved is 10 kg CO₂
    func test_givenHabitWith2_5kgImpact_whenCompletedFourTimes_thenTotalIs10kg() throws {
        // Given
        let impactPerCompletion = CarbonFootprint(kilograms: 2.5)
        var habit = try Habit(
            userID: userID,
            title: "Cycle to work",
            category: .transport,
            targetFrequency: .daily,
            ecoImpact: EcoImpact(
                co2SavedPerCompletion: impactPerCompletion,
                description: "Replaces a car journey"
            )
        )

        // When: complete on 4 different days
        let calendar = Calendar.current
        let today = Date()
        for daysAgo in (0..<4).reversed() {
            // Skip today on iterations > 0 to avoid duplicate
            if daysAgo == 0 && habit.completions.count > 0 { continue }
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            habit = try habit.completing(on: date)
        }

        // Then
        XCTAssertEqual(habit.totalCarbonSaved.kilograms, 10.0, accuracy: 0.001,
            "4 completions × 2.5 kg = 10 kg CO₂ saved")
    }
}

// MARK: - BDD DSL Helpers (readability layer)
// These private helpers make the test body read like a specification.

private extension HabitCompletionBDDTests {

    func givenACyclingHabitWithNoCompletions() throws -> Habit {
        try Habit(
            userID: userID,
            title: "Cycle to work",
            category: .transport,
            targetFrequency: .daily,
            ecoImpact: EcoImpact(
                co2SavedPerCompletion: CarbonFootprint(kilograms: 2.5),
                description: "Avoids a 10 km car journey"
            )
        )
    }

    func whenCompletingHabit(_ habit: Habit, on date: Date) throws -> Habit {
        try habit.completing(on: date)
    }

    func thenStreakEquals(_ expected: Int, for habit: Habit, message: String = "") {
        XCTAssertEqual(habit.currentStreak, expected,
            message.isEmpty ? "Streak should be \(expected)" : message)
    }

    func thenHabitIsCompletedToday(_ habit: Habit) {
        XCTAssertTrue(habit.isCompletedToday, "Habit should be marked as completed today")
    }

    func thenCarbonSavedEquals(kilograms: Double, for habit: Habit) {
        XCTAssertEqual(habit.totalCarbonSaved.kilograms, kilograms, accuracy: 0.001,
            "Expected \(kilograms) kg CO₂ saved")
    }

    func thenCompletingAgainTodayThrows(_ expectedError: HabitError, for habit: Habit) {
        XCTAssertThrowsError(
            try habit.completing(on: Date()),
            "Expected \(expectedError) to be thrown"
        ) { error in
            XCTAssertEqual(error as? HabitError, expectedError)
        }
    }
}
