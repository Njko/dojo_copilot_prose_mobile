package com.ecotrack.domain.usecase

import com.ecotrack.domain.model.EcoImpact
import com.ecotrack.domain.model.Habit
import com.ecotrack.domain.model.HabitCategory
import com.ecotrack.domain.model.HabitId
import com.ecotrack.domain.model.UserId
import com.ecotrack.domain.repository.HabitRepository
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.mockito.kotlin.any
import org.mockito.kotlin.argumentCaptor
import org.mockito.kotlin.mock
import org.mockito.kotlin.verify
import org.mockito.kotlin.whenever
import java.time.LocalDate

// ---------------------------------------------------------------------------
// TDD Starter: LogHabitCompletionUseCaseTest
// ---------------------------------------------------------------------------
// This use case does not exist yet — you must create it.
// Follow TDD: write the test, make it compile, make it pass.
//
// COPILOT WORKFLOW:
//   1. These tests define the contract. Read them carefully.
//   2. Ask Copilot: "Generate the LogHabitCompletionUseCase based on these tests"
//   3. Ask Copilot: "Generate the HabitRepository interface needed by this use case"
//   4. Run tests => RED => implement => GREEN
// ---------------------------------------------------------------------------

class LogHabitCompletionUseCaseTest {

    // Mocked dependencies — participants need to create the real interfaces
    private lateinit var habitRepository: HabitRepository
    private lateinit var useCase: LogHabitCompletionUseCase

    private val userId = UserId("user-42")
    private val habitId = HabitId("habit-bike-001")

    private val bikeHabit = Habit(
        id = habitId,
        name = "Ride a bike to work",
        description = "Bike commute instead of car",
        category = HabitCategory.TRANSPORT,
        frequencyPerWeek = 5,
        ecoImpact = EcoImpact(carbonSavedGrams = 2500)
    )

    @Before
    fun setUp() {
        habitRepository = mock()
        useCase = LogHabitCompletionUseCase(habitRepository) // TODO: create this class
    }

    @Test
    fun `logging completion saves updated habit to repository`() = runTest {
        whenever(habitRepository.findById(habitId)).thenReturn(bikeHabit)

        useCase.execute(LogHabitCompletionUseCase.Params(habitId = habitId, userId = userId))

        val captor = argumentCaptor<Habit>()
        verify(habitRepository).save(captor.capture())
        assertTrue("Saved habit should be completed today", captor.firstValue.isCompletedToday())
    }

    @Test
    fun `logging completion returns updated carbon footprint`() = runTest {
        whenever(habitRepository.findById(habitId)).thenReturn(bikeHabit)

        val result = useCase.execute(
            LogHabitCompletionUseCase.Params(habitId = habitId, userId = userId)
        )

        assertTrue(result.isSuccess)
        val footprint = result.getOrThrow()
        assertEquals(2500, footprint.carbonSavedGrams)
    }

    @Test
    fun `logging completion for non-existent habit returns failure`() = runTest {
        whenever(habitRepository.findById(any())).thenReturn(null)

        val result = useCase.execute(
            LogHabitCompletionUseCase.Params(habitId = HabitId("ghost"), userId = userId)
        )

        assertTrue("Expected failure for non-existent habit", result.isFailure)
        assertTrue(result.exceptionOrNull() is HabitNotFoundException)
    }

    @Test
    fun `logging completion twice on same day does not duplicate entry`() = runTest {
        val alreadyCompleted = bikeHabit.complete(on = LocalDate.now())
        whenever(habitRepository.findById(habitId)).thenReturn(alreadyCompleted)

        val result = useCase.execute(
            LogHabitCompletionUseCase.Params(habitId = habitId, userId = userId)
        )

        assertTrue("Should succeed (idempotent)", result.isSuccess)
        val captor = argumentCaptor<Habit>()
        verify(habitRepository).save(captor.capture())
        val completionsToday = captor.firstValue.completions.count { it.completedOn == LocalDate.now() }
        assertEquals("Should have exactly one completion today", 1, completionsToday)
    }

    @Test
    fun `optional note is stored with completion`() = runTest {
        whenever(habitRepository.findById(habitId)).thenReturn(bikeHabit)
        val note = "Rainy day but still did it!"

        useCase.execute(
            LogHabitCompletionUseCase.Params(habitId = habitId, userId = userId, note = note)
        )

        val captor = argumentCaptor<Habit>()
        verify(habitRepository).save(captor.capture())
        val todayCompletion = captor.firstValue.completions.first { it.completedOn == LocalDate.now() }
        assertEquals(note, todayCompletion.note)
    }
}

// ---------------------------------------------------------------------------
// Stubs — participants delete these once they create the real classes
// ---------------------------------------------------------------------------

// TODO: Replace with real class in domain/usecase/LogHabitCompletionUseCase.kt
class LogHabitCompletionUseCase(private val habitRepository: HabitRepository) {
    data class Params(val habitId: HabitId, val userId: UserId, val note: String? = null)
    data class CompletionResult(val carbonSavedGrams: Int)

    suspend fun execute(params: Params): Result<CompletionResult> = TODO("Implement use case")
}

// TODO: Replace with real exception in domain/model/
class HabitNotFoundException(habitId: HabitId) :
    Exception("Habit with id ${habitId.value} not found")
