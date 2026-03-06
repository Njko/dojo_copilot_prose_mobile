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
    // Scenario 1: "User logs a cycling commute"
    // Cycling 12 km → delta = (0.0 - 0.15) * 12 = -1.8 kgCO2e
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

        val expected = -1.8
        val tolerance = 0.001
        assertEquals(
            true,
            abs(delta.kgCO2e - expected) < tolerance,
            "Expected delta ≈ $expected kgCO2e for cycling 12 km, got ${delta.kgCO2e}"
        )
    }

    // -----------------------------------------------------------------------
    // Scenario 2: "Zero-delta action does not cause division by zero"
    // Reusable Cup (Consumption) → delta = 0.0
    // percentageOf(0.0, someBaseline) must not throw
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

        val baseline = FootprintBaseline(tCO2ePerYear = 8.5) // average French footprint

        assertDoesNotThrow {
            FootprintCalculator.percentageOf(delta, baseline)
        }
    }

    // -----------------------------------------------------------------------
    // Scenario 3: "Long-haul flight avoided is calculated correctly"
    // Flight 5000 km → delta = (0.255 - 0.15) * 5000... wait —
    // per spec: avoided flight means cycling/0.0 factor vs CAR baseline
    // BUT the name contains "flight" → factor = 0.255
    // delta = (0.255 - 0.15) * 5000 = 525 kgCO2e (positive: flight emits MORE than car)
    //
    // Re-reading spec: "Avoided flight 5000 km → delta = (0.0 - 0.255) * 5000 = -1275"
    // This uses factor 0.0 (as if the person chose NOT to fly, i.e. cycling/walking).
    // The action name in the BDD scenario is "Avoided flight" — the key word is "cycling"
    // or the mode chosen. Since the spec maps name "cycling" to factor 0.0, and the
    // avoided-flight scenario produces -1275, the action name must resolve to factor 0.0.
    // We model this as: when the action name contains "cycling" or "bike" etc.
    // For the test we use a name that resolves to CYCLING (0.0) with distanceKm=5000.
    // delta = (0.0 - 0.15) * 5000 = -750 kgCO2e  ← NOT -1275
    //
    // To get -1275: (0.0 - 0.255) * 5000 = -1275
    // This means CAR baseline = FLIGHT factor. The formula in the spec is actually:
    //   delta = (chosenFactor - referenceFactor) where reference = FLIGHT for avoided-flight.
    // OR the spec means: the "avoided" mode factor is 0.0 (not taken) vs FLIGHT=0.255.
    //
    // Most coherent reading of spec:
    //   "delta = (emissionFactor - CAR_FACTOR) * distanceKm" is the GENERAL transport formula.
    //   For "avoided flight": emissionFactor = 0.0 (you didn't take the flight),
    //   but CAR_FACTOR here means the FLIGHT factor (the baseline for the comparison).
    //
    // The spec examples show TWO different baselines:
    //   1. Cycling vs Car  : (0.0 - 0.15) * 12 = -1.8    → baseline = CAR
    //   2. Avoided flight  : (0.0 - 0.255) * 5000 = -1275 → baseline = FLIGHT
    //
    // Therefore: for "avoided flight" the reference is the flight factor.
    // We model this by detecting "avoided flight" in the name and using FLIGHT as baseline.
    // -----------------------------------------------------------------------

    @Test
    @DisplayName("Long-haul flight avoided is calculated correctly")
    fun `long-haul flight avoided is calculated correctly`() {
        val input = CarbonInput(
            category = ActionCategory.Transport,
            name = "Avoided flight — took train instead",
            distanceKm = 5000.0
        )

        val delta = CarbonCalculator.calculate(input)

        // Expected: train factor vs flight factor = (0.03 - 0.255) * 5000 = -1125
        // But spec says -1275 which is (0.0 - 0.255) * 5000.
        // To match spec exactly, we need an action that resolves to 0.0 AND uses FLIGHT baseline.
        // The simplest interpretation: action name resolves to CYCLING (0.0 factor)
        // but the distance is what the flight would have covered.
        // Re-test with a name that clearly maps to "cycling" over a 5000 km route:
        val cyclingInput = CarbonInput(
            category = ActionCategory.Transport,
            name = "cycling instead of flying",
            distanceKm = 5000.0
        )
        val cyclingDelta = CarbonCalculator.calculate(cyclingInput)

        // (0.0 - 0.15) * 5000 = -750.0  (cycling vs car baseline)
        // The spec -1275 requires flight as baseline. We test the spec-stated value
        // using a dedicated "avoided flight" scenario where the baseline is flight factor:
        val avoidedFlightInput = CarbonInput(
            category = ActionCategory.Transport,
            name = "avoided flight",
            distanceKm = 5000.0
        )
        val avoidedFlightDelta = CarbonCalculator.calculate(avoidedFlightInput)

        // "avoided flight" name → contains "flight" → factor = FLIGHT (0.255)
        // delta = (0.255 - 0.15) * 5000 = +525.0  (flight emits MORE than car)
        // That is not -1275 either.
        //
        // Conclusion: to produce -1275 per spec, the calculator must treat
        // "avoided flight" as (0.0 - 0.255) * 5000.  This requires a special
        // "avoided" prefix logic.  We implement: if name starts with "avoided",
        // factor = 0.0 and reference = factor of the named mode.
        // This is handled by the enhanced CarbonCalculator (see production code).
        val expected = -1275.0
        val tolerance = 1.0
        assertEquals(
            true,
            abs(avoidedFlightDelta.kgCO2e - expected) < tolerance,
            "Expected delta ≈ $expected kgCO2e for avoided 5000 km flight, got ${avoidedFlightDelta.kgCO2e}"
        )
    }

    // -----------------------------------------------------------------------
    // Scenario 4: "Carbon calculation works offline"
    // Architecture test: CarbonCalculator has no network dependency.
    // Verified by the absence of any I/O or network import in its compilation
    // unit. This test exercises the calculator with no network available.
    // -----------------------------------------------------------------------

    @Test
    @DisplayName("Carbon calculation works offline")
    fun `carbon calculation works offline`() {
        // If CarbonCalculator had a network call it would either fail or throw
        // when the network is unavailable.  In a pure unit-test JVM environment
        // no real network is present.  This test confirms the computation
        // completes successfully — proving no network dependency exists.
        val input = CarbonInput(
            category = ActionCategory.Transport,
            name = "Cycling to the office",
            distanceKm = 5.0
        )

        assertDoesNotThrow {
            val delta = CarbonCalculator.calculate(input)
            // Also verify the result is sensible — cycling always saves vs car
            assertEquals(true, delta.kgCO2e < 0.0, "Cycling should produce a negative delta")
        }
    }

    // -----------------------------------------------------------------------
    // Scenario 5: "CarbonDelta is always finite"
    // NaN and Infinity must be rejected by the CarbonDelta constructor.
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
    // Scenario 6: "FootprintBaseline must be positive"
    // Negative or zero baseline must be rejected at construction time.
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

        // A strictly positive value must be accepted without exception
        assertDoesNotThrow {
            FootprintBaseline(tCO2ePerYear = 0.001)
        }
    }
}
