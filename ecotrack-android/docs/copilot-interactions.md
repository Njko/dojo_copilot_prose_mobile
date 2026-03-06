# Key Copilot Interactions — EcoTrack Android Dojo

This document lists the exact prompts participants use during the 1-hour session,
grouped by practice area. Each prompt is designed to demonstrate a specific
Copilot capability while reinforcing the PROSE methodology.

---

## TDD (Test Driven Development)

### RED phase — making the test fail for the right reason

```
I have a failing test `streak is zero when no completions` in HabitTest.kt.
The method Habit.currentStreak() currently throws NotImplementedError.
Without looking at the test implementation details, what is the minimal
signature this method needs to satisfy the contract?
```

```
Look at HabitTest.kt. The test `streak resets when a day is missed` defines
the expected behaviour for streak calculation when there is a gap.
Implement Habit.currentStreak() in DomainModels.kt to make all streak tests pass.
Use only the `completions` list and LocalDate arithmetic. No external libraries.
```

```
The test `completion rate is capped at 100 percent even with extra completions`
is failing. Implement Habit.completionRateForWeek(weekStart: LocalDate): Double.
Constraints:
- Count only completions within the 7-day window starting at weekStart
- Result is in range [0.0, 1.0]
- frequencyPerWeek is the target denominator
```

### GREEN to REFACTOR phase

```
currentStreak() now passes all tests but the implementation has a nested loop.
Suggest a refactored version using Kotlin sequences or functional operators
that maintains the same observable behaviour. Keep it under 10 lines.
```

---

## BDD (Behaviour Driven Development)

### Gherkin to test code

```
Read the Gherkin scenario "User marks a habit as completed for today" in
docs/features/track_habit_completion.feature.
Generate the Compose instrumented test that implements this scenario using
the Robot pattern. The Robot classes should be in TrackHabitCompletionFeature.kt.
Use content descriptions for all assertions (not raw text) to ensure
TalkBack compatibility.
```

```
Add a new Gherkin scenario to track_habit_completion.feature for:
"User views their weekly carbon footprint summary after completing 3 habits".
Include the accessibility scenario variant for TalkBack users.
```

### Robot pattern generation

```
Generate a DashboardRobot class for Compose tests that wraps the following
interactions: navigating to a habit, verifying total CO₂ saved, and opening
the weekly summary sheet. Use hasContentDescription() for all selectors.
```

---

## DDD (Domain-Driven Design)

### Aggregate and value object design

```
In EcoTrack, a User can have many Habits. Should User aggregate Habits,
or should they be separate aggregates with a UserId reference?
Explain using DDD principles and show the Kotlin code for both approaches.
Recommend the one that better supports the use case: logging a habit completion
without loading the full User object.
```

```
CarbonFootprint in DomainModels.kt is currently a data class.
Should it be an entity (with its own identity) or a value object?
It represents a pre-calculated read-model for a time period.
Justify your answer and refactor if needed.
```

### Use case generation from domain contract

```
Based on the HabitRepository interface (which you need to create) and the
domain models in DomainModels.kt, generate the ArchiveHabitUseCase.
Rules:
- A habit cannot be archived if it has completions in the last 7 days
- Archiving is soft-delete (set isArchived = true)
- Return Result<Unit> — failure if habit not found or has recent completions
- Include the corresponding unit test file (RED phase — tests fail initially)
```

---

## Eco-conception

### Battery and network optimization

```
The HabitSyncWorker needs to upload pending completions to the backend.
Review this WorkManager implementation and identify:
1. Missing network constraint (will run on mobile data)
2. Missing battery constraint (will run when battery is low)
3. The exponential backoff policy is missing
4. The work tag is not set (cannot be cancelled by feature)
Fix all 4 issues.

[paste your WorkManager code here]
```

```
The DashboardViewModel is calling the repository every time the screen
recompositions triggers. Identify the issue and fix it so the repository
is only called once, with updates flowing through StateFlow.
```

```
Review HabitCard.kt. The streak badge recomposes every time the parent
recomposes, even when the streak hasn't changed.
Fix this using remember and derivedStateOf.
```

### Lazy loading and image efficiency

```
The habit category icons are loaded as PNG drawables.
Suggest a migration to vector drawables (VectorPainter) and show the
res/drawable XML for the TRANSPORT category icon (a bicycle).
```

---

## Accessibility (TalkBack)

### Content description generation

```
Add complete TalkBack support to HabitCard composable.
Requirements:
1. The card itself should announce: "Habit: [name]. Category: [category].
   Streak: [n] days. [Completed today / Not completed today]."
2. The complete button should announce: "Mark [name] as complete for today"
   when not completed, or "[name] completed. Streak: [n] day(s)" when done.
3. The streak badge should not be separately announced (merge with card).
4. Touch target for the complete button must be at least 48dp.
Show the full modified HabitCard composable.
```

```
Write a Compose test that verifies TalkBack can navigate to and activate
the complete button for "Ride a bike to work" using only content descriptions.
The test must NOT use onNodeWithText() — only hasContentDescription().
```

### Colour contrast audit

```
EcoTrack uses green (#2E7D32) text on white (#FFFFFF) background for
completed habits. Calculate the WCAG contrast ratio and determine if it
passes AA (4.5:1) and AAA (7:1) standards. If not, suggest an alternative
green that passes AA while staying in the Material Design green palette.
```

---

## Security

### Encrypted storage

```
The UserPreferences need to persist the reminder time across app restarts.
Generate a PreferencesRepository using androidx.datastore with encryption
via EncryptedSharedPreferences as a fallback for API < 23.
Ensure:
- No email or user ID is stored in this DataStore
- The file is excluded from auto-backup (android:allowBackup="false" in manifest)
- A unit test verifies stored values survive process death (use Robolectric)
```

### PII audit

```
Audit the following log statements for PII leaks and fix any that expose
user-identifiable information. Replace real values with anonymised IDs or
remove the log if it provides no observability value.

[paste suspicious log statements here]
```

```
Generate a Timber ProductionTree that:
1. Strips all DEBUG and VERBOSE logs in release builds
2. Sends ERROR and WARNING to Firebase Crashlytics (non-fatal)
3. Redacts any string matching an email pattern before logging
4. Never logs the userId.value — only a hashed version
```

---

## Observability

### Structured logging

```
Add structured logging to LogHabitCompletionUseCase following these rules:
- Entry log: habit ID (anonymised), category — no name
- Exit log (success): carbon saved, completion count for today
- Exit log (failure): error type, habit ID — no stack trace for expected errors
- Use Timber.tag("HabitCompletion") for all logs in this use case
```

### Performance tracing

```
Add Firebase Performance traces to LogHabitCompletionUseCase.
Measure:
1. Total use case execution time ("log_habit_completion")
2. Repository save time ("habit_repository_save")
Add custom attributes: habit_category (NOT habit_name — that would be PII).
```

---

## CI/CD Automation

### Workflow understanding

```
Explain the android-ci.yml workflow step by step. Specifically:
1. Why do instrumented tests only run on PRs to main?
2. What does the `concurrency` block do and why is it eco-friendly?
3. How would you add a step to post a Slack notification when the build fails?
4. How would you conditionally skip the security scan for documentation-only PRs?
```

### Coverage enforcement

```
Add a Kover coverage verification task to build.gradle.kts that:
- Fails the build if domain/ package coverage drops below 80%
- Generates an HTML report in build/reports/kover/
- Excludes generated Hilt classes and DI modules from coverage calculation
```

---

## PROSE methodology exercises

### P — Progressive Disclosure

```
I'm starting the EcoTrack dojo. I only know basic Android.
Show me the simplest possible version of Habit.currentStreak() that
makes the first 2 tests pass (zero streak, streak of one).
Don't implement the full solution yet.
```

### R — Reduced Scope

```
For the 1-hour dojo session, which 3 features of EcoTrack should we
implement first to demonstrate TDD, BDD, and accessibility together?
Keep scope tight — we cannot implement everything.
```

### O — Orchestrated Composition

```
Show me how LogHabitCompletionUseCase, HabitRepository, and
HabitDashboardViewModel are composed together via Hilt dependency injection.
Draw the dependency graph as an ASCII diagram, then generate the Hilt module.
```

### S — Safety Boundaries

```
What are the 3 most likely places in EcoTrack where a developer could
accidentally introduce a data race or crash due to improper coroutine usage?
For each, show the unsafe code and the safe alternative.
```

### E — Explicit Hierarchy

```
Explain the Clean Architecture layers in EcoTrack as if I'm a junior developer.
For each layer (domain, data, presentation), show one concrete example class
from this project and explain why it belongs there and not in another layer.
```
