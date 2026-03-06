// HabitListView.swift
// EcoTrack — Presentation/Habits
// Swift 6 / iOS 18
//
// Demonstrates:
// - @Observable + @State (no ObservableObject/@Published)
// - LazyVStack for eco-efficient rendering
// - Full accessibility annotations
// - Dynamic Type support
// - @MainActor view model

import SwiftUI

// MARK: - HabitListView

struct HabitListView: View {

    @State private var viewModel: HabitListViewModel

    init(viewModel: HabitListViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("My Eco Habits")
                .navigationBarTitleDisplayMode(.large)
                .toolbar { toolbarContent }
                .task { await viewModel.loadHabits() }
                .refreshable { await viewModel.loadHabits() }
                .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                    Button("OK") { viewModel.errorMessage = nil }
                } message: {
                    Text(viewModel.errorMessage ?? "")
                }
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: Subviews

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.habits.isEmpty {
            loadingView
        } else if viewModel.habits.isEmpty {
            emptyStateView
        } else {
            habitsList
        }
    }

    private var loadingView: some View {
        ProgressView("Loading habits…")
            .accessibilityLabel("Loading your eco habits")
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "leaf.circle")
                .font(.system(size: 64))
                .foregroundStyle(.green)
                .accessibilityHidden(true)
            Text("No habits yet")
                .font(.title2.weight(.semibold))
            Text("Add your first eco-friendly habit to start tracking your environmental impact.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Add First Habit") {
                viewModel.showingAddHabit = true
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .accessibilityLabel("Add your first eco habit")
        }
        .padding()
        .accessibilityElement(children: .combine)
    }

    private var habitsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                progressHeader
                    .padding(.horizontal)

                ForEach(viewModel.habits) { habit in
                    HabitRowView(
                        habit: habit,
                        onComplete: { await viewModel.completeHabit(habit) }
                    )
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Today's Progress")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.completedTodayCount)/\(viewModel.totalHabitsCount)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: viewModel.progressFraction)
                .tint(.green)
                .accessibilityLabel("Daily progress")
                .accessibilityValue(
                    "\(viewModel.completedTodayCount) of \(viewModel.totalHabitsCount) habits completed today"
                )
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                viewModel.showingAddHabit = true
            } label: {
                Image(systemName: "plus")
            }
            .accessibilityLabel("Add new eco habit")
            .accessibilityHint("Opens the form to create a new habit")
        }
    }
}

// MARK: - HabitRowView

struct HabitRowView: View {

    let habit: Habit
    let onComplete: () async -> Void

    var body: some View {
        HStack(spacing: 12) {
            categoryIcon
            habitInfo
            Spacer()
            completeButton
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        // Accessibility: combine all child elements into one readable unit
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue)
        .accessibilityAddTraits(habit.isCompletedToday ? .isSelected : [])
    }

    // MARK: Subviews

    private var categoryIcon: some View {
        Image(systemName: habit.category.systemImageName)
            .font(.title2)
            .foregroundStyle(.green)
            .frame(width: 40, height: 40)
            .background(.green.opacity(0.1), in: Circle())
            .accessibilityHidden(true)
    }

    private var habitInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(habit.title)
                .font(.body.weight(.medium))
                .lineLimit(1)
            HStack(spacing: 6) {
                Label("\(habit.currentStreak) day streak", systemImage: "flame.fill")
                    .font(.caption)
                    .foregroundStyle(habit.currentStreak > 0 ? .orange : .secondary)
                    .accessibilityHidden(true) // covered by accessibilityValue

                Text("·")
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)

                Text(habit.ecoImpact.co2SavedPerCompletion.formatted(.number.precision(.fractionLength(1))) + " kg CO₂")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
        }
    }

    private var completeButton: some View {
        Button {
            Task { await onComplete() }
        } label: {
            Image(systemName: habit.isCompletedToday ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundStyle(habit.isCompletedToday ? .green : .secondary)
                .animation(.spring(duration: 0.3), value: habit.isCompletedToday)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(habit.isCompletedToday ? "Completed" : "Mark \(habit.title) as complete")
        .accessibilityHint(habit.isCompletedToday ? "" : "Double-tap to record today's completion")
        .disabled(habit.isCompletedToday)
        // Minimum tap target 44×44 pt (accessibility requirement)
        .frame(minWidth: 44, minHeight: 44)
    }

    // MARK: Accessibility strings

    private var accessibilityLabel: String {
        "\(habit.title), \(habit.category.rawValue)"
    }

    private var accessibilityValue: String {
        let streakText = habit.currentStreak == 1
            ? "1 day streak"
            : "\(habit.currentStreak) day streak"
        let completionText = habit.isCompletedToday ? "Completed today" : "Not yet completed today"
        let carbonText = "\(habit.ecoImpact.co2SavedPerCompletion.kilograms, specifier: "%.1f") kilograms CO₂ saved per completion"
        return "\(streakText). \(completionText). \(carbonText)"
    }
}

// MARK: - Preview

#Preview("Habit List") {
    HabitListView(viewModel: .preview)
}

#Preview("Empty State") {
    HabitListView(viewModel: {
        let userID = UserID()
        let repo = EmptyPreviewRepository()
        return HabitListViewModel(
            userID: userID,
            fetchHabitsUseCase: FetchHabitsUseCase(habitRepository: repo),
            completeHabitUseCase: CompleteHabitUseCase(habitRepository: repo)
        )
    }())
}

// MARK: - Empty Preview Repository

private actor EmptyPreviewRepository: HabitRepository {
    func fetchHabits(for userID: UserID) async throws -> [Habit] { [] }
    func fetchHabit(by id: HabitID) async throws -> Habit { throw HabitError.habitNotFound(id) }
    func save(_ habit: Habit) async throws {}
    func delete(_ habitID: HabitID) async throws {}
    func totalCarbonSaved(for userID: UserID) async throws -> CarbonFootprint { .zero }
}
