// User.swift
// EcoTrack - Domain Layer
// Swift 6 / iOS 18

import Foundation

// MARK: - User (Aggregate Root)

/// Represents the authenticated app user.
/// PII (email, name) is handled only in memory and never written to logs.
///
/// Security note: `email` is a sensitive field.
/// - Never log User objects directly.
/// - Store credentials in Keychain, not UserDefaults.
public struct User: Identifiable, Hashable, Sendable {

    public let id: UserID
    /// Display name shown in the UI. Not considered PII for analytics.
    public private(set) var displayName: String
    /// Sensitive PII - never log.
    public let email: String
    public private(set) var preferences: UserPreferences
    public let joinedAt: Date

    public init(
        id: UserID = UserID(),
        displayName: String,
        email: String,
        preferences: UserPreferences = .default,
        joinedAt: Date = Date()
    ) throws {
        guard !displayName.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw UserError.emptyDisplayName
        }
        guard email.contains("@") else {
            throw UserError.invalidEmail
        }
        self.id = id
        self.displayName = displayName
        self.email = email
        self.preferences = preferences
        self.joinedAt = joinedAt
    }

    public func updatingPreferences(_ preferences: UserPreferences) -> User {
        var updated = self
        updated.preferences = preferences
        return updated
    }
}

// MARK: - UserPreferences (Value Object)

public struct UserPreferences: Hashable, Sendable {
    public var notificationsEnabled: Bool
    public var dailyReminderTime: DateComponents?
    public var preferredCarbonUnit: CarbonUnit
    public var accessibilityLargeText: Bool

    public static let `default` = UserPreferences(
        notificationsEnabled: true,
        dailyReminderTime: DateComponents(hour: 8, minute: 0),
        preferredCarbonUnit: .kilograms,
        accessibilityLargeText: false
    )
}

// MARK: - CarbonUnit (Value Object)

public enum CarbonUnit: String, Codable, Sendable {
    case grams = "g CO₂"
    case kilograms = "kg CO₂"

    public func formatted(_ footprint: CarbonFootprint) -> String {
        switch self {
        case .grams:
            return String(format: "%.0f g CO₂", footprint.grams)
        case .kilograms:
            return String(format: "%.2f kg CO₂", footprint.kilograms)
        }
    }
}

// MARK: - Domain Errors

public enum UserError: LocalizedError, Equatable {
    case emptyDisplayName
    case invalidEmail

    public var errorDescription: String? {
        switch self {
        case .emptyDisplayName: return "Display name cannot be empty."
        case .invalidEmail:     return "Invalid email address."
        }
    }
}
