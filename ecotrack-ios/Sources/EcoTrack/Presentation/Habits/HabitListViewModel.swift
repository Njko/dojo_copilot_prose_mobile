// HabitListViewModel.swift
// EcoTrack — Presentation/Habits
// Swift 6 / iOS 18
//
// PROSE: Orchestrated Composition
// View model owns no business logic — it delegates to use cases.
// PROSE: Safety Boundaries — imports SwiftUI only for @Observable / @MainActor.

import SwiftUI
import OSLog

private let logger = Logger(subsystem: "com.ecotrack.app", category: "HabitListViewModel")

// MARK: - HabitListViewModel

@MainActor
@Observable
final class HabitListViewModel {

    // MARK: Published State

    var habits: [Habit] = []
    var totalCarbonSaved: CarbonFootprint = .zero
    var isLoading = false
    var errorMessage: String?
    var showingAddHabit = false

    // MARK: Dependencies (injected — no singletons)

    private let fetchHabitsUseCase: FetchHabitsUseCase
    private let completeHabitUseCase: CompleteHabitUseCase
    private let userID: UserID

    // MARK: Init

    init(
        userID: UserID,
        fetchHabitsUseCase: FetchHabitsUseCase,
        completeHabitUseCase: CompleteHabitUseCase
    ) {
        self.userID = userID
        self.fetchHabitsUseCase = fetchHabitsUseCase
        self.completeHabitUseCase = completeHabitUseCase
    }

    // MARK: Intent Handlers

    func loadHabits() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            habits = try await fetchHabitsUseCase.execute(for: userID)
            logger.info("Loaded \(self.habits.count, privacy: .public) habits")
        } catch {
            errorMessage = error.localizedDescription
            logger.error("Failed to load habits: \(error.localizedDescription, privacy: .public)")
        }
    }

    func completeHabit(_ habit: Habit) async {
        do {
            let updated = try await completeHabitUseCase.execute(habitID: habit.id)
            // Replace the habit in the local array (immutable value type)
            if let index = habits.firstIndex(where: { $0.id == updated.id }) {
                habits[index] = updated
            }
            logger.info("Habit \(habit.id, privacy: .public) completed")
        } catch HabitError.alreadyCompletedToday {
            errorMessage = HabitError.alreadyCompletedToday.errorDescription
        } catch {
            errorMessage = error.localizedDescription
            logger.error("Failed to complete habit \(habit.id, privacy: .public): \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: Computed helpers for the view

    var completedTodayCount: Int {
        habits.filter(\.isCompletedToday).count
    }

    var totalHabitsCount: Int {
        habits.count
    }

    var progressFraction: Double {
        guard totalHabitsCount > 0 else { return 0 }
        return Double(completedTodayCount) / Double(totalHabitsCount)
    }
}

// MARK: - Preview helper

extension HabitListViewModel {
    @MainActor
    static var preview: HabitListViewModel {
        // Returns a view model pre-loaded with sample data for SwiftUI previews.
        // This uses a fake in-memory repository — no real persistence.
        let userID = UserID()
        let repo = PreviewHabitRepository(userID: userID)
        return HabitListViewModel(
            userID: userID,
            fetchHabitsUseCase: FetchHabitsUseCase(habitRepository: repo),
            completeHabitUseCase: CompleteHabitUseCase(habitRepository: repo)
        )
    }
}

// MARK: - Preview Repository (Development only)

private actor PreviewHabitRepository: HabitRepository {

    private var habits: [Habit]

    init(userID: UserID) {
        let impact = EcoImpact(
            co2SavedPerCompletion: CarbonFootprint(kilograms: 2.5),
            description: "Replaces car journey"
        )
        self.habits = [
            try! Habit(userID: userID, title: "Cycle to work", category: .transport,
                       targetFrequency: .daily, ecoImpact: impact),
            try! Habit(userID: userID, title: "Meatless Monday", category: .food,
                       targetFrequency: try! Frequency(timesPerPeriod: 1, period: .weekly),
                       ecoImpact: EcoImpact(co2SavedPerCompletion: CarbonFootprint(kilograms: 1.8),
                                            description: "Plant-based meal")),
            try! Habit(userID: userID, title: "Short shower", category: .water,
                       targetFrequency: .daily,
                       ecoImpact: EcoImpact(co2SavedPerCompletion: CarbonFootprint(kilograms: 0.1),
                                            description: "Under 5 minutes"))
        ]
    }

    func fetchHabits(for userID: UserID) async throws -> [Habit] { habits }
    func fetchHabit(by id: HabitID) async throws -> Habit {
        guard let h = habits.first(where: { $0.id == id }) else { throw HabitError.habitNotFound(id) }
        return h
    }
    func save(_ habit: Habit) async throws {
        if let idx = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[idx] = habit
        } else {
            habits.append(habit)
        }
    }
    func delete(_ habitID: HabitID) async throws {
        habits.removeAll { $0.id == habitID }
    }
    func totalCarbonSaved(for userID: UserID) async throws -> CarbonFootprint {
        habits.reduce(.zero) { $0 + $1.totalCarbonSaved }
    }
}
