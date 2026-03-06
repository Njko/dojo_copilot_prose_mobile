package com.ecotrack.domain.repository

import com.ecotrack.domain.model.Habit
import com.ecotrack.domain.model.HabitId
import com.ecotrack.domain.model.UserId
import kotlinx.coroutines.flow.Flow

/**
 * Port (output): HabitRepository
 *
 * Defines the contract for habit persistence.
 * The domain layer depends on this interface — the data layer implements it.
 *
 * DDD note: this is an "anti-corruption layer" boundary.
 * Implementations must map between domain models and persistence models.
 *
 * DOJO EXERCISE: Ask Copilot to "generate the Room-based implementation
 * of HabitRepository using HabitEntity and HabitDao".
 */
interface HabitRepository {

    /**
     * Returns a habit by its ID, or null if not found.
     */
    suspend fun findById(id: HabitId): Habit?

    /**
     * Persists a habit (insert or update).
     * The habit's ID determines whether this is an insert or update.
     */
    suspend fun save(habit: Habit)

    /**
     * Returns a cold Flow that emits the full list of active (non-archived)
     * habits for the given user whenever the underlying data changes.
     */
    fun observeActiveHabits(userId: UserId): Flow<List<Habit>>

    /**
     * Soft-deletes a habit by setting isArchived = true.
     * Returns false if the habit was not found.
     */
    suspend fun archive(id: HabitId): Boolean

    /**
     * Returns all habits for a user, including archived ones.
     * Used by the carbon footprint calculator (historical data).
     */
    suspend fun findAllByUser(userId: UserId): List<Habit>
}
