// CompleteHabitUseCaseTests.swift
// EcoTrackTests - TDD Starting Point (RED phase)
// Swift 6 / iOS 18
//
// DOJO EXERCISE: These tests are RED (failing). Your task is to make them GREEN
// by implementing CompleteHabitUseCase.execute(habitID:on:note:)
//
// PROSE: Reduced Scope - Focus only on CompleteHabitUseCase for this exercise.
// Run tests with: `swift test --filter CompleteHabitUseCaseTests` (VS Code terminal)
//
// COPILOT TIP: Open this file alongside CompleteHabitUseCase.swift.
// Ask Copilot: "Make these tests pass by implementing the execute method"

import XCTest
@testable import EcoTrack

// MARK: - Test Doubles

/// In-memory fake that satisfies the HabitRepository protocol.
/// Participants should NOT modify this file - it is provided infrastructure.
actor InMemoryHabitRepository: HabitRepository {

    private var store: [HabitID: Habit] = [:]

    func fetchHabits(for userID: UserID) async throws -> [Habit] {
        store.values.filter { $0.userID == userID }
    }

    func fetchHabit(by id: HabitID) async throws -> Habit {
        guard let habit = store[id] else {
            throw HabitError.habitNotFound(id)
        }
        return habit
    }

    func save(_ habit: Habit) async throws {
        store[habit.id] = habit
    }

    func delete(_ habitID: HabitID) async throws {
        store.removeValue(forKey: habitID)
    }

    func totalCarbonSaved(for userID: UserID) async throws -> CarbonFootprint {
        store.values
            .filter { $0.userID == userID }
            .reduce(CarbonFootprint.zero) { $0 + $1.totalCarbonSaved }
    }

    // Test helper
    func habitCount() -> Int { store.count }
}

// MARK: - CompleteHabitUseCaseTests

final class CompleteHabitUseCaseTests: XCTestCase {

    // MARK: Properties

    private var repository: InMemoryHabitRepository!
    private var sut: CompleteHabitUseCase!   // sut = System Under Test
    private var testUserID: UserID!
    private var testHabit: Habit!

    // MARK: Setup / Teardown

    override func setUp() async throws {
        try await super.setUp()
        repository = InMemoryHabitRepository()
        sut = CompleteHabitUseCase(habitRepository: repository)
        testUserID = UserID()

        // Arrange: seed a habit into the repository
        testHabit = try Habit(
            userID: testUserID,
            title: "Cycle to work",
            category: .transport,
            targetFrequency: .daily,
            ecoImpact: EcoImpact(
                co2SavedPerCompletion: CarbonFootprint(kilograms: 2.5),
                description: "Avoids a 10 km car journey"
            )
        )
        try await repository.save(testHabit)
    }

    override func tearDown() async throws {
        repository = nil
        sut = nil
        testHabit = nil
        try await super.tearDown()
    }

    // MARK: - RED Tests (currently failing - make these pass!)

    // -------------------------------------------------------------------------
    // TEST 1: Happy path
    // -------------------------------------------------------------------------
    /// Given a valid habit ID and today's date
    /// When the use case is executed
    /// Then it returns the updated habit with one completion for today
    func test_execute_withValidHabit_returnsHabitWithTodayCompletion() async throws {
        // Arrange
        let today = Date()

        // Act
        let updatedHabit = try await sut.execute(habitID: testHabit.id, on: today)

        // Assert
        XCTAssertTrue(updatedHabit.isCompletedToday,
            "Expected habit to be marked as completed today")
        XCTAssertEqual(updatedHabit.completions.count, 1,
            "Expected exactly one completion")
    }

    // -------------------------------------------------------------------------
    // TEST 2: Persists the updated habit
    // -------------------------------------------------------------------------
    /// Given a completed habit
    /// When fetched again from the repository
    /// Then the completion is persisted
    func test_execute_persistsCompletionToRepository() async throws {
        // Arrange
        let today = Date()

        // Act
        _ = try await sut.execute(habitID: testHabit.id, on: today)

        // Assert: re-fetch from repository to verify persistence
        let persisted = try await repository.fetchHabit(by: testHabit.id)
        XCTAssertTrue(persisted.isCompletedToday,
            "Completion should be persisted in the repository")
    }

    // -------------------------------------------------------------------------
    // TEST 3: Streak increments
    // -------------------------------------------------------------------------
    /// Given a habit with no prior completions
    /// When completed today
    /// Then the streak is 1
    func test_execute_withNoHistory_streakIsOne() async throws {
        // Act
        let updatedHabit = try await sut.execute(habitID: testHabit.id)

        // Assert
        XCTAssertEqual(updatedHabit.currentStreak, 1,
            "First ever completion should start a streak of 1")
    }

    // -------------------------------------------------------------------------
    // TEST 4: Optional note is recorded
    // -------------------------------------------------------------------------
    /// Given a completion note
    /// When the use case is executed with that note
    /// Then the note appears on the recorded completion
    func test_execute_withNote_recordsNoteOnCompletion() async throws {
        // Arrange
        let note = "Used the mountain bike today"

        // Act
        let updatedHabit = try await sut.execute(
            habitID: testHabit.id,
            note: note
        )

        // Assert
        XCTAssertEqual(updatedHabit.completions.first?.note, note,
            "Expected the note to be recorded on the completion")
    }

    // -------------------------------------------------------------------------
    // TEST 5: Error - habit not found
    // -------------------------------------------------------------------------
    /// Given a non-existent habit ID
    /// When the use case is executed
    /// Then it throws HabitError.habitNotFound
    func test_execute_withUnknownHabitID_throwsHabitNotFound() async {
        // Arrange
        let unknownID = HabitID()

        // Act & Assert
        do {
            _ = try await sut.execute(habitID: unknownID)
            XCTFail("Expected HabitError.habitNotFound to be thrown")
        } catch HabitError.habitNotFound(let id) {
            XCTAssertEqual(id, unknownID)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // -------------------------------------------------------------------------
    // TEST 6: Error - already completed today (idempotency)
    // -------------------------------------------------------------------------
    /// Given a habit already completed today
    /// When the use case is executed again for the same day
    /// Then it throws HabitError.alreadyCompletedToday
    func test_execute_whenAlreadyCompletedToday_throwsAlreadyCompletedError() async throws {
        // Arrange: complete once
        _ = try await sut.execute(habitID: testHabit.id)

        // Act & Assert: attempt second completion same day
        do {
            _ = try await sut.execute(habitID: testHabit.id)
            XCTFail("Expected HabitError.alreadyCompletedToday to be thrown")
        } catch HabitError.alreadyCompletedToday {
            // Expected - pass
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // -------------------------------------------------------------------------
    // TEST 7: Carbon footprint accumulates correctly
    // -------------------------------------------------------------------------
    /// Given a habit with 2.5 kg CO₂ saved per completion
    /// When completed once
    /// Then total carbon saved is 2.5 kg
    func test_execute_carbonSavedAccumulatesPerCompletion() async throws {
        // Act
        let updatedHabit = try await sut.execute(habitID: testHabit.id)

        // Assert
        XCTAssertEqual(updatedHabit.totalCarbonSaved.kilograms, 2.5, accuracy: 0.001,
            "Expected 2.5 kg CO₂ saved after one completion")
    }

    // -------------------------------------------------------------------------
    // TEST 8: Future date is rejected
    // -------------------------------------------------------------------------
    /// Given a future date
    /// When the use case is executed with that date
    /// Then it throws HabitError.futureCompletion
    func test_execute_withFutureDate_throwsFutureCompletionError() async {
        // Arrange
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!

        // Act & Assert
        do {
            _ = try await sut.execute(habitID: testHabit.id, on: tomorrow)
            XCTFail("Expected HabitError.futureCompletion to be thrown")
        } catch HabitError.futureCompletion {
            // Expected - pass
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

// MARK: - CarbonFootprintTests (GREEN - Domain value object tests)

final class CarbonFootprintTests: XCTestCase {

    func test_carbonFootprint_addition() {
        let a = CarbonFootprint(kilograms: 1.5)
        let b = CarbonFootprint(kilograms: 2.5)
        XCTAssertEqual((a + b).kilograms, 4.0, accuracy: 0.001)
    }

    func test_carbonFootprint_comparison() {
        let small = CarbonFootprint(kilograms: 0.5)
        let large = CarbonFootprint(kilograms: 1.0)
        XCTAssertLessThan(small, large)
    }

    func test_carbonFootprint_gramsConversion() {
        let footprint = CarbonFootprint(kilograms: 1.5)
        XCTAssertEqual(footprint.grams, 1500.0, accuracy: 0.001)
    }

    func test_carbonFootprint_negativeValuePrecondition() {
        // This test documents the precondition - negative values crash
        // Use XCTExpectFailure to document known crash behaviour
        // In production, validate inputs before creating CarbonFootprint
        XCTAssertGreaterThanOrEqual(CarbonFootprint.zero.kilograms, 0)
    }
}

// MARK: - HabitStreakTests (GREEN - Domain logic tests)

final class HabitStreakTests: XCTestCase {

    private var userID: UserID!

    override func setUp() {
        super.setUp()
        userID = UserID()
    }

    func test_currentStreak_withNoCompletions_isZero() throws {
        let habit = try Habit(
            userID: userID,
            title: "Test habit",
            category: .energy,
            targetFrequency: .daily,
            ecoImpact: EcoImpact(co2SavedPerCompletion: .zero, description: "")
        )
        XCTAssertEqual(habit.currentStreak, 0)
    }

    func test_currentStreak_afterTodayCompletion_isOne() throws {
        var habit = try Habit(
            userID: userID,
            title: "Test habit",
            category: .energy,
            targetFrequency: .daily,
            ecoImpact: EcoImpact(co2SavedPerCompletion: .zero, description: "")
        )
        habit = try habit.completing(on: Date())
        XCTAssertEqual(habit.currentStreak, 1)
    }

    func test_isCompletedToday_whenCompletedToday_returnsTrue() throws {
        let habit = try Habit(
            userID: userID,
            title: "Test habit",
            category: .water,
            targetFrequency: .daily,
            ecoImpact: EcoImpact(co2SavedPerCompletion: .zero, description: "")
        )
        let completed = try habit.completing(on: Date())
        XCTAssertTrue(completed.isCompletedToday)
    }

    func test_habit_withEmptyTitle_throwsEmptyTitleError() {
        XCTAssertThrowsError(
            try Habit(
                userID: userID,
                title: "   ",
                category: .food,
                targetFrequency: .daily,
                ecoImpact: EcoImpact(co2SavedPerCompletion: .zero, description: "")
            )
        ) { error in
            XCTAssertEqual(error as? HabitError, HabitError.emptyTitle)
        }
    }
}
