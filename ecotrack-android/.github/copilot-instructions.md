# GitHub Copilot Instructions — EcoTrack Android

> These instructions are loaded automatically by GitHub Copilot in VS Code and
> Android Studio (via the Copilot plugin). They establish the project context,
> coding standards, and constraints Copilot must respect in every suggestion.

## Project overview

EcoTrack is an Android app (Kotlin, Jetpack Compose, MVVM + Clean Architecture)
that helps users build eco-friendly habits and track their carbon footprint.
This is a **dojo project** — code quality, testability, and accessibility are
the primary concerns, not feature completeness.

## Architecture

```
app/src/main/kotlin/com/ecotrack/
├── domain/          # Pure Kotlin — NO Android imports allowed here
│   ├── model/       # Entities, value objects, aggregates (DDD)
│   ├── repository/  # Repository interfaces (ports)
│   └── usecase/     # Application use cases (one class per use case)
├── data/            # Repository implementations, Room, DataStore
│   ├── local/       # Room DAOs, encrypted DataStore
│   └── repository/  # Implements domain/repository interfaces
├── presentation/    # ViewModels + Compose UI (one package per screen)
│   ├── dashboard/
│   ├── habit/
│   └── settings/
├── di/              # Hilt modules only
└── ui/theme/        # Design tokens, typography, colour scheme
```

**Layer rules Copilot must enforce:**
- `domain/` has zero Android framework dependencies (`android.*`, `androidx.*`)
- Use cases return `Result<T>` — never throw exceptions to the presentation layer
- ViewModels expose `StateFlow<UiState>` and `SharedFlow<UiEvent>` only
- Compose functions are pure: no business logic, only UI rendering + callbacks

## Domain-Driven Design conventions

- **Aggregate Roots**: `Habit`, `User` — mutations only through their own methods
- **Value Objects**: `HabitId`, `UserId`, `EcoImpact`, `CarbonFootprint` — immutable, validated in `init {}`
- **Entities**: `HabitCompletion`, `EcoAction` — have identity, belong to an aggregate
- All domain model classes live in `domain/model/DomainModels.kt`
- IDs are `@JvmInline value class` wrappers around `String` (UUID)

## TDD rules

- Write the test **before** the implementation
- Test method names follow: `` `behaviour when condition` `` (backtick-quoted, snake_case with spaces)
- Unit tests: `src/test/` — pure JVM, no Android emulator needed
- Integration/BDD tests: `src/androidTest/` — use Compose Test + Robot pattern
- Every new use case must have a corresponding `*Test.kt` in `domain/usecase/`
- Aim for 80%+ line coverage on `domain/` package

## BDD conventions

- Gherkin scenarios live in `docs/features/*.feature`
- Android instrumented tests implement the scenarios using the **Robot pattern**
- Robot classes end in `Robot` (e.g., `HabitCardRobot`, `DashboardRobot`)
- Scenarios must cover: happy path, edge cases, accessibility, offline behaviour

## Eco-conception constraints

Copilot must suggest eco-efficient implementations:

- **Network**: batch API calls, never poll — use WorkManager with `NetworkType.CONNECTED`
- **Battery**: no `WakeLock` in application code; prefer `Constraints` in WorkManager
- **Rendering**: avoid unnecessary recompositions — use `remember`, `derivedStateOf`, `key()`
- **Storage**: prefer Room over raw SharedPreferences; index frequently queried columns
- **Images**: use vector drawables or WebP; never load full-res bitmaps without sampling
- **Background work**: all background tasks via WorkManager, never bare `Thread` or `Timer`

## Accessibility (TalkBack) requirements

Every interactive Compose element must have:

```kotlin
Modifier.semantics {
    contentDescription = "Human-readable description for TalkBack"
    // For buttons that change state:
    stateDescription = if (isCompleted) "Completed" else "Not completed"
}
```

- Content descriptions must be meaningful in isolation (no "button" or "icon" alone)
- Dynamic content (streaks, CO₂ savings) must update `contentDescription` reactively
- Touch targets must be at least 48dp × 48dp (use `Modifier.minimumInteractiveComponentSize()`)
- Colour is never the only way to convey information — add icons or text labels

## Security requirements

Copilot must never suggest:

- Storing auth tokens, emails, or real names in `SharedPreferences` (unencrypted)
- Logging PII: no `Log.d("user email: $email")` — log anonymised IDs only
- Hardcoded API keys or secrets in source code
- Disabling certificate validation (no `TrustAllCerts`)
- Sending device identifiers (IMEI, MAC) to analytics

Use instead:

- `EncryptedSharedPreferences` or `androidx.datastore` with encryption for sensitive data
- `Timber` for logging — with a `ProductionTree` that strips PII in release builds
- Secrets via `local.properties` (git-ignored) or GitHub Actions secrets
- `OkHttp` with the system certificate store — no custom `SSLSocketFactory`

## Observability conventions

```kotlin
// Logging: always use Timber, never android.util.Log
Timber.d("Habit completed: id=%s", habitId.value)  // OK — no PII
Timber.e(exception, "Failed to save habit")         // OK

// Crashlytics custom keys (non-PII only)
FirebaseCrashlytics.getInstance().setCustomKey("habit_category", category.name)

// Performance tracing
val trace = Firebase.performance.newTrace("log_habit_completion")
trace.start()
// ... operation ...
trace.stop()
```

## Code style

- Kotlin idioms: use `data class`, `sealed class`, `when` expressions, extension functions
- No `null` in domain layer — use `sealed class Result` or `kotlin.Result`
- Coroutines: `viewModelScope` in ViewModel, `Dispatchers.IO` in Repository implementations
- Dependency injection: Hilt only — no manual `Singleton` objects
- Format with `ktlint` — run `./gradlew ktlintCheck` before committing

## What Copilot should always do

1. Suggest `@Preview` annotations for every new Compose function
2. Suggest `contentDescription` for every image, icon, and interactive element
3. Suggest unit tests when generating new domain logic
4. Use `Result<T>` for all operations that can fail
5. Prefer `StateFlow` over `LiveData`
6. Add `@VisibleForTesting` when making something internal public for tests

## What Copilot must never do

1. Import `android.*` in `domain/` package files
2. Suggest `Thread.sleep()` — use coroutines `delay()`
3. Suggest `AsyncTask` — it is deprecated
4. Store sensitive data unencrypted
5. Skip `contentDescription` on interactive elements
6. Generate code that bypasses the repository pattern (no direct DB access in ViewModel)
