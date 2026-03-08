// CarbonCalculator.swift
// EcoTrack - Domain Layer
// Swift 6 / iOS 18
//
// PROSE: Pure function — no side effects, no UIKit/Foundation imports.
// All types are Sendable and Swift 6 compatible.
//
// Emission factors source: ADEME 2024 (kgCO2e/km)

// MARK: - ActionCategory

/// Categories of eco-friendly actions tracked by EcoTrack.
///
/// Used by `CarbonInput` to route the calculation logic in `CarbonCalculator`.
public enum ActionCategory: String, CaseIterable, Sendable {
    /// Transport mode actions (cycling, car, bus, train, flight, etc.)
    case transport
    /// Food-related actions (plant-based meals, reduced meat, etc.)
    case food
    /// Energy-related actions (renewable energy, reducing consumption, etc.)
    case energy
    /// Consumption-related actions (reusable items, second-hand goods, etc.)
    case consumption
    /// Waste-related actions (recycling, composting, etc.)
    case waste
}

// MARK: - CarbonDelta

/// Immutable value object representing the CO₂ equivalent delta produced by an action.
///
/// Negative values indicate CO₂ avoided (the action is beneficial). Positive values indicate CO₂ emitted.
/// Example: cycling instead of driving over 12 km produces −1.8 kgCO2e (a saving).
///
/// **Invariants:**
/// - `kgCO2e` is always finite (never `NaN`, never infinite).
public struct CarbonDelta: Hashable, Comparable, Sendable {

    /// CO₂ equivalent delta in kilograms.
    public let kgCO2e: Double

    /// Creates a `CarbonDelta`.
    /// - Parameter kgCO2e: CO₂ equivalent in kg. Must be finite and not NaN.
    /// - Precondition: `kgCO2e.isFinite` — crashes in debug if violated.
    public init(kgCO2e: Double) {
        precondition(kgCO2e.isFinite, "CarbonDelta.kgCO2e must be finite and never NaN")
        self.kgCO2e = kgCO2e
    }

    /// A delta of zero — no carbon saved or emitted.
    public static let zero = CarbonDelta(kgCO2e: 0.0)

    public static func < (lhs: CarbonDelta, rhs: CarbonDelta) -> Bool {
        lhs.kgCO2e < rhs.kgCO2e
    }
}

// MARK: - FootprintBaseline

/// Immutable value object representing a user's annual carbon footprint baseline.
///
/// Used by `FootprintCalculator` to express a `CarbonDelta` as a percentage of
/// the user's yearly footprint.
///
/// **Invariants:**
/// - `tCO2ePerYear` is strictly positive (> 0, never zero, never negative).
public struct FootprintBaseline: Hashable, Sendable {

    /// Annual carbon footprint in tonnes CO₂ equivalent.
    public let tCO2ePerYear: Double

    /// Creates a `FootprintBaseline`.
    /// - Parameter tCO2ePerYear: Annual footprint in tCO2e. Must be > 0.
    /// - Throws: `CarbonCalculatorError.invalidCategory` if the value is ≤ 0 or not finite.
    public init(tCO2ePerYear: Double) throws {
        guard tCO2ePerYear.isFinite, tCO2ePerYear > 0 else {
            throw CarbonCalculatorError.invalidBaseline
        }
        self.tCO2ePerYear = tCO2ePerYear
    }
}

// MARK: - CarbonInput

/// Value object carrying all the data needed to compute a `CarbonDelta`.
///
/// - `category`: Determines the calculation branch.
/// - `name`: Human-readable label for the action.
/// - `distanceKm`: Required for transport actions; optional for other categories.
public struct CarbonInput: Hashable, Sendable {

    /// The category of the eco action.
    public let category: ActionCategory

    /// Human-readable name for the action (e.g. "Cycling commute").
    public let name: String

    /// Distance in kilometres, required for transport actions.
    public let distanceKm: Double?

    /// Creates a `CarbonInput`.
    /// - Parameters:
    ///   - category: The action category.
    ///   - name: The action name.
    ///   - distanceKm: Distance in km (required for `.transport`).
    public init(category: ActionCategory, name: String, distanceKm: Double? = nil) {
        self.category = category
        self.name = name
        self.distanceKm = distanceKm
    }
}

// MARK: - CarbonCalculator

/// Pure namespace for carbon delta calculation.
///
/// `CarbonCalculator` is a caseless enum used as a namespace — it cannot be
/// instantiated. All logic lives in its static functions.
///
/// ## Transport calculation
///
/// The delta is the difference between the chosen mode and a baseline car journey:
///
/// ```
/// delta = (emissionFactor - carFactor) * distanceKm
/// ```
///
/// Using ADEME 2024 emission factors (kgCO2e/km):
///
/// | Mode    | Factor   |
/// |---------|----------|
/// | Cycling | 0.000    |
/// | Car     | 0.150    |
/// | Bus     | 0.040    |
/// | Train   | 0.030    |
/// | Flight  | 0.255    |
///
/// ## Non-transport categories
///
/// Food, energy, consumption, and waste actions without a distance return a
/// delta of `0.0 kgCO2e` (no distance-based calculation defined yet).
public enum CarbonCalculator {

    // MARK: Emission factors (ADEME 2024, kgCO2e/km)

    private static let cyclingFactor: Double = 0.000
    private static let carFactor:     Double = 0.150   // reference baseline
    private static let busFactor:     Double = 0.040
    private static let trainFactor:   Double = 0.030
    private static let flightFactor:  Double = 0.255

    // MARK: Public API

    /// Computes the CO₂ delta for the given input compared to a car baseline.
    ///
    /// For transport actions the formula is:
    /// ```
    /// delta = (emissionFactor − carFactor) × distanceKm
    /// ```
    /// A negative result means CO₂ was avoided.
    ///
    /// Non-transport categories without a distance return `.zero`.
    ///
    /// - Parameter input: The action description.
    /// - Returns: A `CarbonDelta` (always finite).
    /// - Throws: `CarbonCalculatorError.missingDistance` when `input.category == .transport`
    ///   and `input.distanceKm` is `nil`.
    public static func calculate(_ input: CarbonInput) throws -> CarbonDelta {
        switch input.category {
        case .transport:
            return try calculateTransport(input)
        case .food, .energy, .consumption, .waste:
            // No distance-based model yet; delta defaults to zero.
            return .zero
        }
    }

    // MARK: Private helpers

    private static func calculateTransport(_ input: CarbonInput) throws -> CarbonDelta {
        guard let distanceKm = input.distanceKm else {
            throw CarbonCalculatorError.missingDistance
        }

        let factor = emissionFactor(for: input.name)
        let deltaValue = (factor - carFactor) * distanceKm
        return CarbonDelta(kgCO2e: deltaValue)
    }

    /// Maps a transport action name to its ADEME 2024 emission factor.
    ///
    /// The lookup is case-insensitive and falls back to the car factor (zero delta)
    /// when the name is unrecognised — making the function total.
    private static func emissionFactor(for name: String) -> Double {
        let lowercased = name.lowercased()
        if lowercased.contains("cycl") || lowercased.contains("bike") || lowercased.contains("bicycle") || lowercased.contains("walk") {
            return cyclingFactor
        } else if lowercased.contains("bus") || lowercased.contains("coach") {
            return busFactor
        } else if lowercased.contains("train") || lowercased.contains("rail") || lowercased.contains("metro") || lowercased.contains("subway") || lowercased.contains("tram") {
            return trainFactor
        } else if lowercased.contains("flight") || lowercased.contains("fly") || lowercased.contains("plane") || lowercased.contains("airplane") {
            return flightFactor
        } else {
            // Default: car (delta = 0)
            return carFactor
        }
    }
}

// MARK: - FootprintCalculator

/// Pure namespace for expressing a `CarbonDelta` as a fraction of an annual baseline.
///
/// Like `CarbonCalculator`, this is a caseless enum used as a namespace.
public enum FootprintCalculator {

    /// Returns the percentage of the annual baseline represented by the delta.
    ///
    /// The baseline is in tonnes CO₂e/year; the delta is in kg CO₂e.
    /// The conversion factor is 1 tonne = 1 000 kg.
    ///
    /// ```
    /// percentage = (delta.kgCO2e / (baseline.tCO2ePerYear × 1000)) × 100
    /// ```
    ///
    /// A zero delta always returns `0.0` without dividing.
    ///
    /// - Parameters:
    ///   - delta: The CO₂ delta to express as a percentage.
    ///   - baseline: The user's annual footprint baseline.
    /// - Returns: Percentage (can be negative if the action avoids carbon).
    public static func percentageOf(_ delta: CarbonDelta, baseline: FootprintBaseline) -> Double {
        guard delta.kgCO2e != 0.0 else { return 0.0 }
        let baselineKg = baseline.tCO2ePerYear * 1_000.0
        return (delta.kgCO2e / baselineKg) * 100.0
    }
}

// MARK: - CarbonCalculatorError

/// Errors thrown by `CarbonCalculator` and related types.
public enum CarbonCalculatorError: Error, Equatable {

    /// A transport calculation was attempted without a `distanceKm` value.
    case missingDistance

    /// The action category does not support the requested calculation.
    case invalidCategory

    /// A `FootprintBaseline` was initialised with a non-positive value.
    case invalidBaseline
}
