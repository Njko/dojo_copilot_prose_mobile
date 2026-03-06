// CompleteHabitUseCase.swift
// EcoTrack - Domain Layer (Use Case)
// Swift 6 / iOS 18
//
// PROSE: Orchestrated Composition - Use cases orchestrate domain entities
// and repository ports. No framework dependencies.

import Foundation
import OSLog

// MARK: - CompleteHabitUseCase

/// Records a habit completion for the current day.
///
/// Participants: implement `execute` by following the TDD red-green-refactor cycle.
/// The use case should:
///   1. Fetch the habit from the repository
///   2. Call `habit.completing(on:note:)`
///   3. Persist the updated habit
///   4. Return the updated habit
///
/// - Note: This is the **primary TDD exercise target** for the dojo.
public struct CompleteHabitUseCase: Sendable {

    private let habitRepository: any HabitRepository
    private let logger = Logger(subsystem: "com.ecotrack.app", category: "CompleteHabitUseCase")

    public init(habitRepository: any HabitRepository) {
        self.habitRepository = habitRepository
    }

    /// Executes the habit completion.
    /// - Parameters:
    ///   - habitID: The ID of the habit to complete.
    ///   - date: The completion date (defaults to today).
    ///   - note: Optional note for this completion.
    /// - Returns: The updated `Habit` with the new completion recorded.
    /// - Throws: `HabitError` for domain violations.
    public func execute(
        habitID: HabitID,
        on date: Date = Date(),
        note: String? = nil
    ) async throws -> Habit {
        // TODO (TDD): Implement this method.
        // Step 1: Fetch the habit - use habitRepository.fetchHabit(by:)
        // Step 2: Call habit.completing(on:note:)
        // Step 3: Save the updated habit - use habitRepository.save(_:)
        // Step 4: Log the event with OSLog (no PII, no habit content in logs)
        // Step 5: Return the updated habit

        // Log only IDs, never user content
        logger.info("Completing habit \(habitID, privacy: .public) on \(date, privacy: .private)")

        throw HabitError.habitNotFound(habitID) // Remove this line when implementing
    }
}

// MARK: - FetchHabitsUseCase

/// Fetches all habits for the authenticated user, sorted by streak descending.
public struct FetchHabitsUseCase: Sendable {

    private let habitRepository: any HabitRepository

    public init(habitRepository: any HabitRepository) {
        self.habitRepository = habitRepository
    }

    public func execute(for userID: UserID) async throws -> [Habit] {
        let habits = try await habitRepository.fetchHabits(for: userID)
        return habits.sorted { $0.currentStreak > $1.currentStreak }
    }
}

// MARK: - CreateHabitUseCase

/// Creates and persists a new habit.
public struct CreateHabitUseCase: Sendable {

    private let habitRepository: any HabitRepository

    public init(habitRepository: any HabitRepository) {
        self.habitRepository = habitRepository
    }

    public func execute(
        userID: UserID,
        title: String,
        category: HabitCategory,
        frequency: Frequency,
        ecoImpact: EcoImpact
    ) async throws -> Habit {
        let habit = try Habit(
            userID: userID,
            title: title,
            category: category,
            targetFrequency: frequency,
            ecoImpact: ecoImpact
        )
        try await habitRepository.save(habit)
        return habit
    }
}
