package com.ecotrack.presentation.dashboard

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.ecotrack.domain.model.HabitCategory
import com.ecotrack.domain.model.HabitId
import com.ecotrack.domain.model.UserId
import com.ecotrack.domain.repository.HabitRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.launch
import timber.log.Timber
import javax.inject.Inject

// ---------------------------------------------------------------------------
// HabitDashboardViewModel
//
// PROSE — Explicit Hierarchy:
//   This ViewModel sits at the boundary between domain and presentation.
//   It knows about domain use cases but only exposes UI-friendly state.
//
// DOJO EXERCISE:
//   The onHabitComplete() method is a stub. Implement it using
//   LogHabitCompletionUseCase once participants create that class.
//   Ask Copilot: "Implement onHabitComplete using LogHabitCompletionUseCase"
// ---------------------------------------------------------------------------

@HiltViewModel
class HabitDashboardViewModel @Inject constructor(
    private val habitRepository: HabitRepository,
    // TODO (dojo exercise): inject LogHabitCompletionUseCase when created
) : ViewModel() {

    private val _uiState = MutableStateFlow<HabitListUiState>(HabitListUiState.Loading)
    val uiState: StateFlow<HabitListUiState> = _uiState.asStateFlow()

    private val _uiEvents = MutableSharedFlow<DashboardUiEvent>()
    val uiEvents: SharedFlow<DashboardUiEvent> = _uiEvents.asSharedFlow()

    // Hard-coded for dojo — replace with auth session in real app
    private val currentUserId = UserId("dojo-user-001")

    init {
        observeHabits()
    }

    private fun observeHabits() {
        viewModelScope.launch {
            habitRepository.observeActiveHabits(currentUserId)
                .map { habits ->
                    if (habits.isEmpty()) {
                        HabitListUiState.Empty
                    } else {
                        HabitListUiState.Success(
                            habits = habits.map { it.toUiModel() },
                            totalCarbonSavedTodayGrams = habits
                                .filter { it.isCompletedToday() }
                                .sumOf { it.ecoImpact.carbonSavedGrams }
                        )
                    }
                }
                .catch { error ->
                    Timber.e(error, "Failed to observe habits")
                    emit(HabitListUiState.Error("Could not load habits"))
                }
                .collect { state -> _uiState.value = state }
        }
    }

    /**
     * Called when the user taps the complete button for a habit.
     *
     * TODO (dojo exercise): replace this stub with the real use case call.
     * Steps:
     *   1. Create LogHabitCompletionUseCase in domain/usecase/
     *   2. Inject it above
     *   3. Call useCase.execute(Params(habitId, currentUserId))
     *   4. On success: emit DashboardUiEvent.ShowCarbonSaved
     *   5. On failure: emit DashboardUiEvent.ShowError
     */
    fun onHabitComplete(habitId: HabitId) {
        Timber.d("Completing habit: id=%s", habitId.value)
        viewModelScope.launch {
            // TODO: implement using LogHabitCompletionUseCase
            _uiEvents.emit(DashboardUiEvent.ShowError("Not implemented yet — see dojo exercise"))
        }
    }
}

// ---------------------------------------------------------------------------
// UI State — sealed hierarchy (PROSE: Explicit Hierarchy)
// ---------------------------------------------------------------------------

sealed interface HabitListUiState {
    data object Loading : HabitListUiState
    data object Empty : HabitListUiState
    data class Success(
        val habits: List<HabitUiModel>,
        val totalCarbonSavedTodayGrams: Int
    ) : HabitListUiState
    data class Error(val message: String) : HabitListUiState
}

// ---------------------------------------------------------------------------
// UI Events — one-shot side effects
// ---------------------------------------------------------------------------

sealed interface DashboardUiEvent {
    data class ShowCarbonSaved(val grams: Int) : DashboardUiEvent
    data class ShowError(val message: String) : DashboardUiEvent
}

// ---------------------------------------------------------------------------
// UI Model — presentation-layer representation of a Habit
// No domain types exposed to Compose UI.
// ---------------------------------------------------------------------------

data class HabitUiModel(
    val id: HabitId,
    val name: String,
    val categoryLabel: String,
    val categoryContentDescription: String,
    val streakDays: Int,
    val streakLabel: String,
    val isCompletedToday: Boolean,
    val completionRateThisWeek: Float,      // 0.0 to 1.0
    val carbonSavedGrams: Int,
    val completeButtonContentDescription: String,
    val cardContentDescription: String
) {
    companion object {
        /** Sample data for @Preview composables */
        fun preview() = HabitUiModel(
            id = HabitId("preview-id"),
            name = "Ride a bike to work",
            categoryLabel = "Transport",
            categoryContentDescription = "Transport and mobility habits",
            streakDays = 3,
            streakLabel = "3 days",
            isCompletedToday = false,
            completionRateThisWeek = 0.6f,
            carbonSavedGrams = 2500,
            completeButtonContentDescription = "Mark Ride a bike to work as complete for today",
            cardContentDescription = "Habit: Ride a bike to work. Category: Transport. Streak: 3 days. Not completed today."
        )
    }
}

// ---------------------------------------------------------------------------
// Mapper — domain Habit -> HabitUiModel
// Keep mapping logic here, not in domain model.
// ---------------------------------------------------------------------------

private fun com.ecotrack.domain.model.Habit.toUiModel(): HabitUiModel {
    val streak = try { currentStreak() } catch (_: NotImplementedError) { 0 }
    val streakLabel = when (streak) {
        0 -> "No streak"
        1 -> "1 day"
        else -> "$streak days"
    }
    val completedToday = isCompletedToday()
    return HabitUiModel(
        id = id,
        name = name,
        categoryLabel = category.displayLabel,
        categoryContentDescription = category.contentDescription,
        streakDays = streak,
        streakLabel = streakLabel,
        isCompletedToday = completedToday,
        completionRateThisWeek = 0f,  // TODO: wire up completionRateForWeek()
        carbonSavedGrams = ecoImpact.carbonSavedGrams,
        completeButtonContentDescription = if (completedToday) {
            "$name completed. Streak: $streakLabel"
        } else {
            "Mark $name as complete for today"
        },
        cardContentDescription = buildString {
            append("Habit: $name. ")
            append("Category: ${category.displayLabel}. ")
            append("Streak: $streakLabel. ")
            append(if (completedToday) "Completed today." else "Not completed today.")
        }
    )
}
