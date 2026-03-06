package com.ecotrack.domain

// ---------------------------------------------------------------------------
// EcoTrack - CarbonCalculator BDD Tests (Phase 4 — PROSE Dojo)
// ---------------------------------------------------------------------------
// PROSE methodology applied here:
//   P - Progressive: scenarios ordered from basic to edge-case
//   R - Reduced Scope: pure unit tests — no Android framework, no network
//   O - Orchestrated: each test creates its own minimal input fixture
//   S - Safety: deterministic, no I/O, runs offline without side effects
//   E - Explicit: @DisplayName mirrors the BDD scenario names from DOJO.md
// ---------------------------------------------------------------------------

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertDoesNotThrow
import org.junit.jupiter.api.Assertions.assertThrows
import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.Test
import kotlin.math.abs

@DisplayName("CarbonCalculator — BDD scenarios")
class CarbonCalculatorTest {

    // -----------------------------------------------------------------------
    // Scenario 1 — "User logs a cycling commute"
    //
    // Given a Transport action named "Cycling commute" over 12 km
    // When CarbonCalculator.calculate() is called
    // Then the delta is (0.0 − 0.15) × 12 = −1.8 kgCO₂e  (tolerance 0.001)
    // -----------------------------------------------------------------------

    @Test
    @DisplayName("User logs a cycling commute")
    fun `user logs a cycling commute`() {
        val input = CarbonInput(
            category = ActionCategory.Transport,
            name = "Cycling commute",
            distanceKm = 12.0
        )

        val delta = CarbonCalculator.calculate(input)

        assertEquals(
            true,
            abs(delta.kgCO2e - (-1.8)) < 0.001,
            "Expected −1.8 kgCO₂e for cycling 12 km, got ${delta.kgCO2e}"
        )
    }

    // -----------------------------------------------------------------------
    // Scenario 2 — "Zero-delta action does not cause division by zero"
    //
    // Given a Consumption action (Reusable Cup) with no distance
    // When calculate() is called, the delta must be 0.0
    // And when percentageOf() is called with that delta, no exception is thrown
    // -----------------------------------------------------------------------

    @Test
    @DisplayName("Zero-delta action does not cause division by zero")
    fun `zero-delta action does not cause division by zero`() {
        val input = CarbonInput(
            category = ActionCategory.Consumption,
            name = "Reusable Cup"
        )

        val delta = CarbonCalculator.calculate(input)

        assertEquals(0.0, delta.kgCO2e, 0.001)

        val baseline = FootprintBaseline(tCO2ePerYear = 8.5)

        assertDoesNotThrow {
            FootprintCalculator.percentageOf(delta, baseline)
        }
    }

    // -----------------------------------------------------------------------
    // Scenario 3 — "Long-haul flight avoided is calculated correctly"
    //
    // Given a Transport action "Avoided flight" over 5000 km
    // When calculate() is called
    // Then the delta is (0.0 − 0.255) × 5000 = −1275 kgCO₂e  (tolerance 1.0)
    //
    // Rationale: "Avoided X" means the user did NOT take mode X.
    // Chosen emission factor = 0.0 (no travel);  reference = X's factor (0.255).
    // Source: ADEME 2024, flight = 0.255 kgCO₂e/km.
    // -----------------------------------------------------------------------

    @Test
    @DisplayName("Long-haul flight avoided is calculated correctly")
    fun `long-haul flight avoided is calculated correctly`() {
        val input = CarbonInput(
            category = ActionCategory.Transport,
            name = "Avoided flight",
            distanceKm = 5000.0
        )

        val delta = CarbonCalculator.calculate(input)

        assertEquals(
            true,
            abs(delta.kgCO2e - (-1275.0)) < 1.0,
            "Expected −1275 kgCO₂e for avoided 5000 km flight, got ${delta.kgCO2e}"
        )
    }

    // -----------------------------------------------------------------------
    // Scenario 4 — "Carbon calculation works offline"
    //
    // CarbonCalculator is a pure-function object with no I/O or network calls.
    // In a JVM unit-test environment with no real network, the calculation
    // must complete successfully — confirming no network dependency exists.
    // -----------------------------------------------------------------------

    @Test
    @DisplayName("Carbon calculation works offline")
    fun `carbon calculation works offline`() {
        val input = CarbonInput(
            category = ActionCategory.Transport,
            name = "Cycling to the office",
            distanceKm = 5.0
        )

        assertDoesNotThrow {
            val delta = CarbonCalculator.calculate(input)
            // Cycling always saves vs the car baseline → result must be negative
            assertEquals(true, delta.kgCO2e < 0.0, "Cycling delta must be negative")
        }
    }

    // -----------------------------------------------------------------------
    // Scenario 5 — "CarbonDelta is always finite"
    //
    // NaN and ±Infinity must be rejected by the CarbonDelta value-object
    // constructor with an IllegalArgumentException.
    // -----------------------------------------------------------------------

    @Test
    @DisplayName("CarbonDelta is always finite")
    fun `CarbonDelta is always finite`() {
        assertThrows(IllegalArgumentException::class.java) {
            CarbonDelta(Double.NaN)
        }

        assertThrows(IllegalArgumentException::class.java) {
            CarbonDelta(Double.POSITIVE_INFINITY)
        }

        assertThrows(IllegalArgumentException::class.java) {
            CarbonDelta(Double.NEGATIVE_INFINITY)
        }
    }

    // -----------------------------------------------------------------------
    // Scenario 6 — "FootprintBaseline must be positive"
    //
    // Zero, negative, and NaN baselines must be rejected at construction time
    // with an IllegalArgumentException.
    // A strictly positive value must be accepted without exception.
    // -----------------------------------------------------------------------

    @Test
    @DisplayName("FootprintBaseline must be positive")
    fun `FootprintBaseline must be positive`() {
        assertThrows(IllegalArgumentException::class.java) {
            FootprintBaseline(tCO2ePerYear = 0.0)
        }

        assertThrows(IllegalArgumentException::class.java) {
            FootprintBaseline(tCO2ePerYear = -1.0)
        }

        assertThrows(IllegalArgumentException::class.java) {
            FootprintBaseline(tCO2ePerYear = Double.NaN)
        }

        assertDoesNotThrow {
            FootprintBaseline(tCO2ePerYear = 0.001)
        }
    }
}
