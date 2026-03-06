package com.ecotrack.domain.model

import java.time.LocalDate
import java.time.LocalDateTime
import java.util.UUID

// ---------------------------------------------------------------------------
// EcoTrack - Domain Models (DDD)
// ---------------------------------------------------------------------------
// DOJO EXERCISE: These are your bounded-context entities.
// The domain is intentionally minimal — participants extend it during the dojo.
//
// COPILOT HINT: Ask Copilot to "add a streak calculation method to Habit"
// or "implement CarbonFootprint.equivalent()" to see context-aware generation.
// ---------------------------------------------------------------------------

/**
 * Aggregate Root: Habit
 *
 * Represents a single eco-friendly habit tracked by the user.
 * A Habit contains the invariant: frequency must be positive.
 *
 * DDD note: Habit is an Aggregate Root — all mutations go through it.
 */
data class Habit(
    val id: HabitId = HabitId(),
    val name: String,
    val description: String,
    val category: HabitCategory,
    val frequencyPerWeek: Int,              // invariant: must be in 1..7
    val ecoImpact: EcoImpact,
    val completions: List<HabitCompletion> = emptyList(),
    val isArchived: Boolean = false,
    val createdAt: LocalDateTime = LocalDateTime.now()
) {
    init {
        require(name.isNotBlank()) { "Habit name must not be blank" }
        require(frequencyPerWeek in 1..7) { "Frequency must be between 1 and 7 days per week" }
    }

    // TODO (TDD exercise): implement currentStreak() — see HabitTest.kt
    fun currentStreak(): Int = TODO("Implement streak calculation")

    // TODO (TDD exercise): implement completionRateForWeek()
    fun completionRateForWeek(weekStart: LocalDate): Double = TODO("Implement completion rate")

    fun complete(on: LocalDate = LocalDate.now(), note: String? = null): Habit =
        copy(completions = completions + HabitCompletion(habitId = id, completedOn = on, note = note))

    fun isCompletedToday(): Boolean =
        completions.any { it.completedOn == LocalDate.now() }
}

/**
 * Value Object: HabitId
 * Wraps a UUID to make IDs type-safe across the domain.
 */
@JvmInline
value class HabitId(val value: String = UUID.randomUUID().toString())

/**
 * Value Object: HabitCompletion
 * Records a single instance of a habit being completed.
 */
data class HabitCompletion(
    val habitId: HabitId,
    val completedOn: LocalDate,
    val note: String? = null,
    val recordedAt: LocalDateTime = LocalDateTime.now()
)

/**
 * Value Object: EcoImpact
 *
 * Quantifies the environmental benefit of completing the habit once.
 * All values are positive — a negative impact means the habit is harmful (not tracked).
 */
data class EcoImpact(
    val carbonSavedGrams: Int,             // CO₂ equivalent saved per completion
    val waterSavedMilliliters: Int = 0,
    val energySavedWh: Int = 0
) {
    init {
        require(carbonSavedGrams >= 0) { "Carbon saved must be non-negative" }
    }

    operator fun plus(other: EcoImpact) = EcoImpact(
        carbonSavedGrams = this.carbonSavedGrams + other.carbonSavedGrams,
        waterSavedMilliliters = this.waterSavedMilliliters + other.waterSavedMilliliters,
        energySavedWh = this.energySavedWh + other.energySavedWh
    )

    companion object {
        val ZERO = EcoImpact(carbonSavedGrams = 0)
    }
}

/**
 * Entity: EcoAction
 *
 * A one-time or ad-hoc eco-friendly action (not a recurring habit).
 * Example: "Repaired a bike instead of buying a new one".
 */
data class EcoAction(
    val id: EcoActionId = EcoActionId(),
    val title: String,
    val ecoImpact: EcoImpact,
    val actionCategory: HabitCategory,
    val performedAt: LocalDateTime = LocalDateTime.now(),
    val userId: UserId
) {
    init {
        require(title.isNotBlank()) { "EcoAction title must not be blank" }
    }
}

@JvmInline
value class EcoActionId(val value: String = UUID.randomUUID().toString())

/**
 * Value Object: CarbonFootprint
 *
 * Aggregated carbon footprint snapshot for a given period.
 * Used in the dashboard to show progress over time.
 *
 * DDD note: This is a read-model / projection, not a write-side entity.
 */
data class CarbonFootprint(
    val userId: UserId,
    val periodStart: LocalDate,
    val periodEnd: LocalDate,
    val totalSavedGrams: Int,
    val breakdown: Map<HabitCategory, Int> = emptyMap()  // category -> grams saved
) {
    // TODO (TDD exercise): implement equivalent() — returns a human-readable comparison
    // e.g. "equivalent to driving 12 km less"
    fun equivalent(): CarbonEquivalent = TODO("Implement carbon equivalent calculation")

    val totalSavedKg: Double get() = totalSavedGrams / 1000.0

    companion object {
        // Average CO₂ per km driven (passenger car, EU average)
        const val GRAMS_CO2_PER_KM_CAR = 120
    }
}

/**
 * Value Object: CarbonEquivalent
 * A human-readable expression of an abstract carbon saving.
 */
data class CarbonEquivalent(
    val kmNotDrivenByCar: Double,
    val treeDaysAbsorbed: Double,           // days a mature tree absorbs equivalent CO₂
    val smartphoneCharges: Int              // number of smartphone full charges equivalent
)

/**
 * Aggregate Root: User
 *
 * Minimal user profile — no PII beyond a display name.
 * Security note: email and auth tokens are NEVER stored in this domain model.
 * They live in the encrypted DataStore, managed by the auth layer only.
 */
data class User(
    val id: UserId = UserId(),
    val displayName: String,
    val joinedAt: LocalDate = LocalDate.now(),
    val preferences: UserPreferences = UserPreferences()
) {
    init {
        require(displayName.isNotBlank()) { "Display name must not be blank" }
        require(displayName.length <= 50) { "Display name must not exceed 50 characters" }
    }
}

@JvmInline
value class UserId(val value: String = UUID.randomUUID().toString())

/**
 * Value Object: UserPreferences
 * User-configurable settings. No PII.
 */
data class UserPreferences(
    val reminderEnabled: Boolean = true,
    val reminderHour: Int = 20,            // 0..23
    val theme: AppTheme = AppTheme.SYSTEM,
    val accessibilityLargeText: Boolean = false
) {
    init {
        require(reminderHour in 0..23) { "Reminder hour must be in 0..23" }
    }
}

/**
 * Enum: HabitCategory
 * Bounded set of eco categories — drives filtering and CO₂ breakdown.
 */
enum class HabitCategory(val displayLabel: String, val contentDescription: String) {
    TRANSPORT("Transport", "Transport and mobility habits"),
    FOOD("Food", "Food and diet habits"),
    ENERGY("Energy", "Home energy habits"),
    WATER("Water", "Water consumption habits"),
    WASTE("Waste", "Waste reduction and recycling habits"),
    SHOPPING("Shopping", "Conscious consumption habits")
}

/**
 * Enum: AppTheme
 */
enum class AppTheme { LIGHT, DARK, SYSTEM }
