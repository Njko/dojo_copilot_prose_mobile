// Habit.swift
// EcoTrack - Domain Layer
// Swift 6 / iOS 18
//
// PROSE: Explicit Hierarchy - Domain entities are pure Swift value types.
// No UIKit/SwiftUI imports in this layer. No external dependencies.

import Foundation

// MARK: - Habit (Aggregate Root)

/// A trackable eco-friendly habit belonging to a user.
/// Habit is the aggregate root. All mutations go through its methods.
///
/// DDD rules:
///   - Invariant: `targetFrequency` must be > 0
///   - Invariant: `completions` dates must not be in the future
///   - Invariant: a Habit must belong to exactly one User (via `userID`)
public struct Habit: Identifiable, Hashable, Sendable {

    public let id: HabitID
    public let userID: UserID
    public private(set) var title: String
    public private(set) var category: HabitCategory
    public private(set) var targetFrequency: Frequency
    public private(set) var ecoImpact: EcoImpact
    public private(set) var completions: [HabitCompletion]
    public let createdAt: Date

    // MARK: Init

    public init(
        id: HabitID = HabitID(),
        userID: UserID,
        title: String,
        category: HabitCategory,
        targetFrequency: Frequency,
        ecoImpact: EcoImpact,
        completions: [HabitCompletion] = [],
        createdAt: Date = Date()
    ) throws {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw HabitError.emptyTitle
        }
        guard targetFrequency.timesPerPeriod > 0 else {
            throw HabitError.invalidFrequency
        }
        self.id = id
        self.userID = userID
        self.title = title
        self.category = category
        self.targetFrequency = targetFrequency
        self.ecoImpact = ecoImpact
        self.completions = completions
        self.createdAt = createdAt
    }

    // MARK: Domain Behaviour

    /// Records a completion for today. Idempotent for the same calendar day.
    /// - Returns: updated Habit with new completion appended.
    public func completing(on date: Date = Date(), note: String? = nil) throws -> Habit {
        guard date <= Date() else {
            throw HabitError.futureCompletion
        }
        // Idempotency guard: one completion per day
        if completions.contains(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
            throw HabitError.alreadyCompletedToday
        }
        let completion = HabitCompletion(date: date, note: note)
        var updated = self
        updated.completions.append(completion)
        return updated
    }

    /// Current streak in days (consecutive days with at least one completion).
    public var currentStreak: Int {
        guard !completions.isEmpty else { return 0 }
        let calendar = Calendar.current
        let sortedDates = completions.map(\.date).sorted(by: >)
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        for date in sortedDates {
            let completionDay = calendar.startOfDay(for: date)
            if completionDay == checkDate {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else if completionDay < checkDate {
                break
            }
        }
        return streak
    }

    /// Whether the habit has been completed today.
    public var isCompletedToday: Bool {
        completions.contains { Calendar.current.isDateInToday($0.date) }
    }

    /// Total CO₂ saved since habit creation (kg).
    public var totalCarbonSaved: CarbonFootprint {
        CarbonFootprint(kilograms: ecoImpact.co2SavedPerCompletion.kilograms * Double(completions.count))
    }
}

// MARK: - HabitCompletion (Value Object)

public struct HabitCompletion: Hashable, Sendable {
    public let date: Date
    public let note: String?

    public init(date: Date = Date(), note: String? = nil) {
        self.date = date
        self.note = note
    }
}

// MARK: - HabitCategory (Value Object)

public enum HabitCategory: String, CaseIterable, Codable, Sendable {
    case transport     = "Transport"
    case energy        = "Energy"
    case food          = "Food"
    case water         = "Water"
    case waste         = "Waste"
    case consumption   = "Consumption"

    public var systemImageName: String {
        switch self {
        case .transport:   return "bicycle"
        case .energy:      return "bolt.fill"
        case .food:        return "leaf.fill"
        case .water:       return "drop.fill"
        case .waste:       return "trash.fill"
        case .consumption: return "bag.fill"
        }
    }
}

// MARK: - Frequency (Value Object)

public struct Frequency: Hashable, Sendable {
    public enum Period: String, Codable, Sendable {
        case daily, weekly, monthly
    }

    public let timesPerPeriod: Int
    public let period: Period

    public init(timesPerPeriod: Int, period: Period) throws {
        guard timesPerPeriod > 0 else { throw HabitError.invalidFrequency }
        self.timesPerPeriod = timesPerPeriod
        self.period = period
    }

    public static let daily = try! Frequency(timesPerPeriod: 1, period: .daily)
    public static let weekly = try! Frequency(timesPerPeriod: 1, period: .weekly)
}

// MARK: - EcoImpact (Value Object)

public struct EcoImpact: Hashable, Sendable {
    public let co2SavedPerCompletion: CarbonFootprint
    public let description: String

    public init(co2SavedPerCompletion: CarbonFootprint, description: String) {
        self.co2SavedPerCompletion = co2SavedPerCompletion
        self.description = description
    }
}

// MARK: - CarbonFootprint (Value Object)

/// Immutable value object representing a CO₂ equivalent mass.
/// Always positive. Use `.zero` for no impact.
public struct CarbonFootprint: Hashable, Comparable, Sendable {

    /// CO₂ equivalent in kilograms.
    public let kilograms: Double

    public init(kilograms: Double) {
        precondition(kilograms >= 0, "CarbonFootprint cannot be negative")
        self.kilograms = kilograms
    }

    public static let zero = CarbonFootprint(kilograms: 0)

    public var grams: Double { kilograms * 1000 }

    public static func < (lhs: CarbonFootprint, rhs: CarbonFootprint) -> Bool {
        lhs.kilograms < rhs.kilograms
    }

    public static func + (lhs: CarbonFootprint, rhs: CarbonFootprint) -> CarbonFootprint {
        CarbonFootprint(kilograms: lhs.kilograms + rhs.kilograms)
    }
}

// MARK: - Typed IDs (Value Objects)

public struct HabitID: Hashable, Sendable, CustomStringConvertible {
    public let rawValue: UUID
    public init(_ rawValue: UUID = UUID()) { self.rawValue = rawValue }
    public var description: String { rawValue.uuidString }
}

public struct UserID: Hashable, Sendable, CustomStringConvertible {
    public let rawValue: UUID
    public init(_ rawValue: UUID = UUID()) { self.rawValue = rawValue }
    public var description: String { rawValue.uuidString }
}

// MARK: - Domain Errors

public enum HabitError: LocalizedError, Equatable {
    case emptyTitle
    case invalidFrequency
    case futureCompletion
    case alreadyCompletedToday
    case habitNotFound(HabitID)

    public var errorDescription: String? {
        switch self {
        case .emptyTitle:              return "Habit title cannot be empty."
        case .invalidFrequency:        return "Frequency must be at least once per period."
        case .futureCompletion:        return "Cannot record a completion in the future."
        case .alreadyCompletedToday:   return "Habit already completed today."
        case .habitNotFound(let id):   return "Habit \(id) not found."
        }
    }
}
