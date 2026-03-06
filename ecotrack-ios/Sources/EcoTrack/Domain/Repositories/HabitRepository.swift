// HabitRepository.swift
// EcoTrack - Domain Layer (Repository Interface)
// Swift 6 / iOS 18
//
// PROSE: Safety Boundaries - The domain only depends on this protocol.
// Infrastructure implementations are injected at the composition root.

import Foundation

// MARK: - HabitRepository Protocol

/// Port (in hexagonal architecture terms) for habit persistence.
/// Concrete adapters live in the Infrastructure layer.
///
/// All methods are async and throw for proper error propagation.
/// Implementations must be Sendable (Swift 6 concurrency safety).
public protocol HabitRepository: Sendable {

    /// Fetches all habits for a given user, ordered by creation date descending.
    func fetchHabits(for userID: UserID) async throws -> [Habit]

    /// Fetches a single habit by its ID.
    func fetchHabit(by id: HabitID) async throws -> Habit

    /// Persists a new or updated habit.
    func save(_ habit: Habit) async throws

    /// Removes a habit permanently.
    func delete(_ habitID: HabitID) async throws

    /// Total carbon footprint saved by all habits for a user.
    func totalCarbonSaved(for userID: UserID) async throws -> CarbonFootprint
}

// MARK: - EcoActionRepository Protocol

public protocol EcoActionRepository: Sendable {
    func fetchActions(for userID: UserID) async throws -> [EcoAction]
    func save(_ action: EcoAction) async throws
}

// MARK: - EcoAction (Entity)

/// A one-off eco-friendly action (distinct from a recurring Habit).
public struct EcoAction: Identifiable, Hashable, Sendable {
    public let id: EcoActionID
    public let userID: UserID
    public let title: String
    public let carbonSaved: CarbonFootprint
    public let performedAt: Date
    public let category: HabitCategory

    public init(
        id: EcoActionID = EcoActionID(),
        userID: UserID,
        title: String,
        carbonSaved: CarbonFootprint,
        performedAt: Date = Date(),
        category: HabitCategory
    ) {
        self.id = id
        self.userID = userID
        self.title = title
        self.carbonSaved = carbonSaved
        self.performedAt = performedAt
        self.category = category
    }
}

public struct EcoActionID: Hashable, Sendable, CustomStringConvertible {
    public let rawValue: UUID
    public init(_ rawValue: UUID = UUID()) { self.rawValue = rawValue }
    public var description: String { rawValue.uuidString }
}
