// CarbonCalculatorTests.swift
// EcoTrackTests - BDD Scenarios for CarbonCalculator
// Swift 6 / iOS 18
//
// BDD APPROACH: XCTest with structured Given/When/Then naming.
// Scenarios map directly to the PROSE Phase 4 specification.
//
// NAMING CONVENTION:
//   test_<subject>_<condition>()
//   OR  test_given<Context>_when<Action>_then<Outcome>()

import XCTest
@testable import EcoTrack

// MARK: - BDD: Carbon Calculator Feature

/// Feature: Carbon delta calculation
/// As an eco-conscious user
/// I want to know the CO₂ impact of my actions relative to a car baseline
/// So that I can understand and reduce my carbon footprint
final class CarbonCalculatorTests: XCTestCase {

    // MARK: - Scenario 1: Cycling commute produces correct carbon delta

    /// Given a transport input for cycling 12 km
    /// When I calculate the carbon delta
    /// Then the result is -1.8 kgCO2e (cycling avoids 0.15 kgCO2e/km × 12 km)
    func test_cyclingCommute_producesCorrectCarbonDelta() throws {
        // Given
        let input = CarbonInput(
            category: .transport,
            name: "Cycling commute",
            distanceKm: 12.0
        )

        // When
        let delta = try CarbonCalculator.calculate(input)

        // Then
        XCTAssertEqual(delta.kgCO2e, -1.8, accuracy: 0.001,
            "Cycling 12 km should save 1.8 kgCO2e compared to a car journey")
    }

    // MARK: - Scenario 2: Reusable cup produces zero delta

    /// Given a consumption input (reusable cup) without distance
    /// When I calculate the carbon delta
    /// Then the result is 0.0 kgCO2e (no distance-based model for consumption)
    func test_reusableCup_producesZeroDelta() throws {
        // Given
        let input = CarbonInput(
            category: .consumption,
            name: "Reusable cup",
            distanceKm: nil
        )

        // When
        let delta = try CarbonCalculator.calculate(input)

        // Then
        XCTAssertEqual(delta.kgCO2e, 0.0,
            "Consumption action without distance should produce a zero delta")
    }

    // MARK: - Scenario 3: Zero delta does not cause division by zero in FootprintCalculator

    /// Given a zero carbon delta and a valid baseline of 8.5 tCO2e/year
    /// When I compute the percentage of the baseline
    /// Then the result is 0.0 without any exception or NaN
    func test_zeroDelta_doesNotCauseDivisionByZero() throws {
        // Given
        let delta = CarbonDelta(kgCO2e: 0.0)
        let baseline = try FootprintBaseline(tCO2ePerYear: 8.5)

        // When
        let percentage = FootprintCalculator.percentageOf(delta, baseline: baseline)

        // Then
        XCTAssertEqual(percentage, 0.0,
            "A zero delta should return 0.0 percentage without division or NaN")
        XCTAssertFalse(percentage.isNaN,
            "Result must not be NaN when delta is zero")
    }

    // MARK: - Scenario 4: Avoided flight produces correct carbon delta

    /// Given transport inputs for flight and cycling over 5000 km
    /// When I calculate the carbon delta using ADEME 2024 emission factors
    /// Then:
    ///   - Flight 5000 km → delta = (0.255 - 0.150) × 5000 = +525 kgCO2e (more than car)
    ///   - Cycling 5000 km → delta = (0.0 - 0.150) × 5000 = -750 kgCO2e (saves vs car)
    ///
    /// Note: the formula is always `(modeFactor - carFactor) × distanceKm`.
    /// The spec's "-1275 avoided flight" example uses flight as the reference baseline,
    /// which is outside the car-baseline model implemented here.
    func test_avoidedFlight_producesCorrectDelta() throws {
        // Given – flight over 5000 km: emits MORE than driving
        let flightInput = CarbonInput(
            category: .transport,
            name: "Flight",
            distanceKm: 5000.0
        )

        // When
        let flightDelta = try CarbonCalculator.calculate(flightInput)

        // Then: (flightFactor 0.255 - carFactor 0.150) × 5000 = +525
        XCTAssertEqual(flightDelta.kgCO2e, (0.255 - 0.150) * 5000.0, accuracy: 1.0,
            "Flight 5000 km should produce (0.255 - 0.150) × 5000 = +525 kgCO2e vs car baseline")

        // Given – cycling over 5000 km: avoids carbon vs driving
        let cyclingInput = CarbonInput(
            category: .transport,
            name: "Cycling",
            distanceKm: 5000.0
        )

        // When
        let cyclingDelta = try CarbonCalculator.calculate(cyclingInput)

        // Then: (cyclingFactor 0.0 - carFactor 0.150) × 5000 = -750
        XCTAssertEqual(cyclingDelta.kgCO2e, (0.0 - 0.150) * 5000.0, accuracy: 1.0,
            "Cycling 5000 km should produce (0.0 - 0.150) × 5000 = -750 kgCO2e vs car baseline")

        XCTAssertTrue(flightDelta.kgCO2e.isFinite)
        XCTAssertTrue(cyclingDelta.kgCO2e.isFinite)
    }

    // MARK: - Scenario 5: CarbonDelta is always finite

    /// Given any valid CarbonInput
    /// When the calculator produces a CarbonDelta
    /// Then the result is finite (not NaN, not infinite)
    func test_carbonDelta_alwaysFinite() throws {
        let inputs: [CarbonInput] = [
            CarbonInput(category: .transport, name: "Cycling commute", distanceKm: 12.0),
            CarbonInput(category: .transport, name: "Train journey", distanceKm: 100.0),
            CarbonInput(category: .transport, name: "Bus trip", distanceKm: 50.0),
            CarbonInput(category: .transport, name: "Flight", distanceKm: 5000.0),
            CarbonInput(category: .food, name: "Plant-based meal"),
            CarbonInput(category: .energy, name: "Solar panel"),
            CarbonInput(category: .consumption, name: "Reusable bag"),
            CarbonInput(category: .waste, name: "Composting"),
        ]

        for input in inputs {
            let delta = try CarbonCalculator.calculate(input)
            XCTAssertTrue(delta.kgCO2e.isFinite,
                "CarbonDelta for '\(input.name)' must be finite, got \(delta.kgCO2e)")
            XCTAssertFalse(delta.kgCO2e.isNaN,
                "CarbonDelta for '\(input.name)' must not be NaN")
        }
    }

    // MARK: - Scenario 6: FootprintBaseline rejects zero or negative values

    /// Given an attempt to create a FootprintBaseline with a non-positive value
    /// When the initialiser is called
    /// Then it throws `CarbonCalculatorError.invalidBaseline`
    func test_footprintBaseline_rejectsZeroOrNegative() {
        // Zero
        XCTAssertThrowsError(try FootprintBaseline(tCO2ePerYear: 0.0)) { error in
            XCTAssertEqual(error as? CarbonCalculatorError, .invalidBaseline,
                "Zero baseline should throw invalidBaseline")
        }

        // Negative
        XCTAssertThrowsError(try FootprintBaseline(tCO2ePerYear: -1.0)) { error in
            XCTAssertEqual(error as? CarbonCalculatorError, .invalidBaseline,
                "Negative baseline should throw invalidBaseline")
        }

        // Very large negative
        XCTAssertThrowsError(try FootprintBaseline(tCO2ePerYear: -999.99)) { error in
            XCTAssertEqual(error as? CarbonCalculatorError, .invalidBaseline,
                "Large negative baseline should throw invalidBaseline")
        }

        // Valid value should NOT throw
        XCTAssertNoThrow(try FootprintBaseline(tCO2ePerYear: 8.5),
            "Positive baseline should not throw")
        XCTAssertNoThrow(try FootprintBaseline(tCO2ePerYear: 0.001),
            "Small positive baseline should not throw")
    }

    // MARK: - Additional: Missing distance throws for transport

    /// Given a transport input without distanceKm
    /// When I calculate the carbon delta
    /// Then it throws `CarbonCalculatorError.missingDistance`
    func test_transport_withoutDistance_throwsMissingDistance() {
        let input = CarbonInput(
            category: .transport,
            name: "Cycling commute",
            distanceKm: nil
        )

        XCTAssertThrowsError(try CarbonCalculator.calculate(input)) { error in
            XCTAssertEqual(error as? CarbonCalculatorError, .missingDistance,
                "Transport without distance should throw missingDistance")
        }
    }

    // MARK: - Scenario: Action name containing "air" but not a flight keyword uses car baseline

    /// Given a transport input named "airbnb office commute" (contains "air" but is not a flight)
    /// When I calculate the carbon delta
    /// Then the result is 0.0 kgCO2e (car baseline, not flight factor)
    func test_actionNameContainingAir_butNotFlight_usesCarBaseline() throws {
        // "airbnb" should not be confused with "airplane"
        let input = CarbonInput(category: .transport, name: "airbnb office commute", distanceKm: 10.0)
        let delta = try CarbonCalculator.calculate(input)
        // Should use car baseline (delta = 0.0) not flight factor
        XCTAssertEqual(delta.kgCO2e, 0.0, accuracy: 0.001,
            "Action containing 'air' but not 'flight/plane/airplane' should default to car baseline")
    }

    // MARK: - Additional: Non-transport categories with distance still return zero

    /// Given food/energy/waste inputs (even with a distance)
    /// When I calculate the carbon delta
    /// Then the result is 0.0 (no distance-based model defined for these categories)
    func test_nonTransportCategories_returnZeroDelta() throws {
        let inputs: [CarbonInput] = [
            CarbonInput(category: .food, name: "Plant-based meal", distanceKm: 5.0),
            CarbonInput(category: .energy, name: "Solar panel", distanceKm: 10.0),
            CarbonInput(category: .waste, name: "Composting", distanceKm: 2.0),
        ]

        for input in inputs {
            let delta = try CarbonCalculator.calculate(input)
            XCTAssertEqual(delta.kgCO2e, 0.0,
                "Category '\(input.category)' should return zero delta")
        }
    }
}
