package com.ecotrack.domain

// ---------------------------------------------------------------------------
// EcoTrack - Carbon Calculator (Domain Layer)
// ---------------------------------------------------------------------------
// PROSE methodology:
//   P - Progressive: sealed hierarchy models all action categories
//   R - Reduced Scope: pure domain logic, no Android/IO dependencies
//   O - Orchestrated: single entry-point objects with explicit contracts
//   S - Safety: value objects enforce invariants at construction time
//   E - Explicit: KDoc on every public type and function
// ---------------------------------------------------------------------------

import kotlin.math.abs

// ---------------------------------------------------------------------------
// Action category hierarchy
// ---------------------------------------------------------------------------

/**
 * Sealed hierarchy representing the category of an eco-friendly action.
 *
 * Each sub-type maps to an ADEME 2024 emission-factor domain.
 * Using a sealed class (rather than an enum) keeps the door open for
 * category-specific data fields in future iterations without breaking
 * existing call sites.
 */
sealed class ActionCategory {

    /** Human-powered mobility — bicycle, walking, etc. */
    object Transport : ActionCategory()

    /** Food and dietary choices. */
    object Food : ActionCategory()

    /** Home or office energy consumption. */
    object Energy : ActionCategory()

    /** Purchasing and consumption choices. */
    object Consumption : ActionCategory()

    /** Waste reduction, reuse, and recycling actions. */
    object Waste : ActionCategory()
}

// ---------------------------------------------------------------------------
// Value objects
// ---------------------------------------------------------------------------

/**
 * Value object representing a carbon footprint delta in kg CO₂ equivalent.
 *
 * A **negative** value means CO₂ was avoided (the action is beneficial).
 * A **positive** value means CO₂ was emitted.
 *
 * Invariant: [kgCO2e] must be finite and not NaN.
 *
 * @property kgCO2e The signed delta expressed in kilograms of CO₂ equivalent.
 * @throws IllegalArgumentException if [kgCO2e] is NaN or infinite.
 */
@JvmInline
value class CarbonDelta(val kgCO2e: Double) {
    init {
        require(kgCO2e.isFinite()) {
            "CarbonDelta must be finite and not NaN, got: $kgCO2e"
        }
    }
}

/**
 * Value object representing a user's annual carbon footprint baseline.
 *
 * Used as a reference to express a [CarbonDelta] as a percentage of the
 * user's total yearly emissions.
 *
 * Invariant: [tCO2ePerYear] must be strictly positive and finite.
 *
 * @property tCO2ePerYear Baseline expressed in **tonnes** of CO₂ equivalent per year.
 * @throws IllegalArgumentException if [tCO2ePerYear] is not strictly positive or not finite.
 */
@JvmInline
value class FootprintBaseline(val tCO2ePerYear: Double) {
    init {
        require(tCO2ePerYear.isFinite() && tCO2ePerYear > 0.0) {
            "FootprintBaseline must be strictly positive, got: $tCO2ePerYear"
        }
    }
}

// ---------------------------------------------------------------------------
// Input data class
// ---------------------------------------------------------------------------

/**
 * Input data required to calculate a [CarbonDelta] for a single eco-action.
 *
 * @property category   The [ActionCategory] that determines the calculation strategy.
 * @property name       A human-readable label for the action (e.g. "Cycling to work").
 * @property distanceKm Optional distance in kilometres, required for [ActionCategory.Transport]
 *                      calculations. Ignored for other categories.
 */
data class CarbonInput(
    val category: ActionCategory,
    val name: String,
    val distanceKm: Double? = null
)

// ---------------------------------------------------------------------------
// Emission factors (ADEME 2024, kgCO₂e/km)
// ---------------------------------------------------------------------------

/**
 * ADEME 2024 emission factors in kgCO₂e per kilometre for transport modes.
 *
 * These constants are package-private to avoid leaking implementation details
 * while remaining accessible for testing within the same package.
 */
internal object EmissionFactors {
    /** Human-powered transport — zero direct emissions. */
    const val CYCLING: Double = 0.0

    /**
     * Average passenger car (EU mix, petrol/diesel).
     * Used as the **baseline** reference for transport delta calculations.
     */
    const val CAR: Double = 0.15

    /** Urban/regional bus (average occupancy, EU mix). */
    const val BUS: Double = 0.04

    /** Rail (long-distance, EU average electricity mix). */
    const val TRAIN: Double = 0.03

    /** Commercial aviation (economy class, per passenger-km). */
    const val FLIGHT: Double = 0.255
}

// ---------------------------------------------------------------------------
// CarbonCalculator
// ---------------------------------------------------------------------------

/**
 * Pure-function calculator that converts a [CarbonInput] into a [CarbonDelta].
 *
 * **Transport logic** — the delta is the avoided emission compared to driving
 * the same distance by car:
 * ```
 * delta = (modeFactor - CAR_FACTOR) * distanceKm
 * ```
 * A negative result means CO₂ was avoided.
 *
 * **Other categories** — for Food, Consumption, Waste, and Energy the delta
 * defaults to 0.0 unless a specialised sub-calculator is added. This is an
 * intentional YAGNI decision: the model is ready to extend without breaking
 * existing behaviour.
 *
 * No side effects. No I/O. No Android dependency.
 */
object CarbonCalculator {

    /**
     * Calculates the carbon delta for the given [input].
     *
     * @param input A fully-formed [CarbonInput] describing the action.
     * @return A [CarbonDelta] representing the CO₂ impact relative to a
     *         car-travel baseline (for transport) or zero (for other categories).
     */
    fun calculate(input: CarbonInput): CarbonDelta {
        return when (input.category) {
            is ActionCategory.Transport -> calculateTransport(input)
            is ActionCategory.Energy    -> CarbonDelta(0.0)
            is ActionCategory.Food      -> CarbonDelta(0.0)
            is ActionCategory.Consumption -> CarbonDelta(0.0)
            is ActionCategory.Waste     -> CarbonDelta(0.0)
        }
    }

    /**
     * Derives the emission factor for a transport action from its [CarbonInput.name].
     *
     * The name is matched case-insensitively against known transport mode keywords.
     * Unrecognised names fall back to the car factor (delta = 0.0).
     *
     * Supported keywords: `cycling`, `bike`, `bicycle`, `walking`, `walk`,
     * `bus`, `train`, `rail`, `flight`, `plane`, `airplane`.
     */
    private fun emissionFactorForTransport(name: String): Double {
        val lower = name.lowercase()
        return when {
            lower.contains("cycling") || lower.contains("bike") ||
            lower.contains("bicycle") || lower.contains("walking") ||
            lower.contains("walk")    -> EmissionFactors.CYCLING

            lower.contains("bus")     -> EmissionFactors.BUS

            lower.contains("train") || lower.contains("rail") -> EmissionFactors.TRAIN

            lower.contains("flight") || lower.contains("plane") ||
            lower.contains("airplane") -> EmissionFactors.FLIGHT

            else                       -> EmissionFactors.CAR
        }
    }

    private fun calculateTransport(input: CarbonInput): CarbonDelta {
        val distance = input.distanceKm ?: 0.0
        val factor = emissionFactorForTransport(input.name)
        val deltaKg = (factor - EmissionFactors.CAR) * distance
        return CarbonDelta(deltaKg)
    }
}

// ---------------------------------------------------------------------------
// FootprintCalculator
// ---------------------------------------------------------------------------

/**
 * Pure-function calculator that expresses a [CarbonDelta] as a percentage of
 * a user's annual carbon [FootprintBaseline].
 *
 * No side effects. No I/O. No Android dependency.
 */
object FootprintCalculator {

    /**
     * Returns the fraction of the annual [baseline] represented by [delta].
     *
     * The result is signed: a negative percentage means the action reduced
     * the footprint; positive means it increased it.
     *
     * Division-by-zero is structurally prevented because [FootprintBaseline]
     * enforces a strictly-positive value at construction time.  This guard
     * is kept explicitly for clarity and to satisfy static analysis tools.
     *
     * @param delta    The carbon delta to express as a fraction of [baseline].
     * @param baseline The annual footprint reference (must be strictly positive).
     * @return A signed ratio in the range (-∞, +∞), where -0.01 means
     *         "1% of the annual footprint was avoided".
     */
    fun percentageOf(delta: CarbonDelta, baseline: FootprintBaseline): Double {
        // Guard is redundant (FootprintBaseline invariant covers it) but kept
        // for defensive programming and readability.
        val baselineKg = baseline.tCO2ePerYear * 1_000.0 // convert tonnes → kg
        if (baselineKg == 0.0) return 0.0
        return delta.kgCO2e / baselineKg
    }
}
