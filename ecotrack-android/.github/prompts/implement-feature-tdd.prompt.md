---
mode: agent
description: >
  Implement a new EcoTrack feature end-to-end using TDD.
  Copilot will generate the failing test first, then the implementation,
  following Clean Architecture and the PROSE methodology.
---

# Implement a Feature with TDD — EcoTrack Android

## How to use this prompt

1. Open GitHub Copilot Chat in Android Studio or VS Code
2. Type `/implement-feature-tdd` (or paste this prompt manually)
3. Fill in the placeholders below, then submit
4. Follow the step-by-step guidance Copilot provides

---

## Feature request

**Feature name:** [e.g. "Archive a habit"]

**User story:**
```
As a [type of user]
I want to [perform action]
So that [benefit / business value]
```

**Acceptance criteria (from the .feature file or product owner):**
```
Given [precondition]
When [action]
Then [expected outcome]
```

**Domain entities involved:** [e.g. Habit, User, EcoImpact]

**Layer affected:** [domain / data / presentation / all]

---

## Step 1 — Write the failing domain test (RED)

Generate a unit test file at:
`app/src/test/kotlin/com/ecotrack/domain/[usecase|model]/[FeatureName]Test.kt`

Requirements for the generated test:
- Use JUnit 4 with Robolectric if Android types are needed, pure JUnit otherwise
- Name the test class `[FeatureName]Test`
- Cover at minimum: happy path, edge case (empty/null/zero), invariant violation
- Test method names use backtick notation: `` `behaviour when condition` ``
- Use a `buildXxx()` fixture function for test data setup
- Assert using JUnit `assertEquals` / `assertTrue` — no AssertJ
- All tests must FAIL initially (call `TODO("implement me")` in the method under test)
- Include a comment at the top: `// RED phase: run these tests first — they should all fail`

---

## Step 2 — Define the use case contract

Generate the use case class skeleton at:
`app/src/main/kotlin/com/ecotrack/domain/usecase/[FeatureName]UseCase.kt`

Requirements:
- Class name: `[FeatureName]UseCase`
- Single `suspend fun execute(params: Params): Result<Output>` method
- Nested `data class Params(...)` with all inputs
- Nested `data class Output(...)` or reuse an existing domain type
- Constructor injection of required repository interfaces (no concrete implementations)
- Body: `TODO("implement")` — not yet implemented
- Include `@Throws` KDoc comment listing all `Result.failure` cases

---

## Step 3 — Generate the repository interface (if new)

If the feature needs a new data operation, generate the interface at:
`app/src/main/kotlin/com/ecotrack/domain/repository/[EntityName]Repository.kt`

Requirements:
- All methods are `suspend fun` (except streaming: `fun observe...(): Flow<T>`)
- Return types: domain model types only (no Room entities, no DTOs)
- No Android imports
- Add a KDoc comment for each method describing the contract

---

## Step 4 — Implement the use case (GREEN)

Now implement `[FeatureName]UseCase.execute()` to make all tests pass.

Requirements:
- Wrap the body in `Result.runCatching { }` or explicit `try/catch` returning `Result`
- Use named arguments when calling repository methods
- Include a `Timber.d(...)` log at entry and exit (no PII in log messages)
- Handle the "not found" case by returning `Result.failure(EntityNotFoundException(id))`
- Keep the method under 20 lines — extract private helpers if needed

---

## Step 5 — Generate the ViewModel method

In the appropriate ViewModel at:
`app/src/main/kotlin/com/ecotrack/presentation/[screen]/[Screen]ViewModel.kt`

Add a method `fun on[ActionName](params)` that:
- Launches in `viewModelScope`
- Calls the use case via `execute()`
- On success: updates `_uiState` with the new data
- On failure: emits to `_uiEvents` as `UiEvent.ShowError(message)`
- Never exposes `Result<T>` to the UI layer — unwrap it in the ViewModel

---

## Step 6 — Generate the Compose UI

Generate or update the Composable at:
`app/src/main/kotlin/com/ecotrack/presentation/[screen]/[Screen]Screen.kt`

Requirements:
- State is received as parameter (not read from ViewModel directly)
- Every interactive element has `contentDescription` in `Modifier.semantics {}`
- Buttons use `Modifier.minimumInteractiveComponentSize()` (48dp touch target)
- Add a `@Preview` with sample data
- No business logic in the Composable — only rendering and callbacks

---

## Step 7 — Generate the BDD instrumented test

Generate the Robot-pattern test at:
`app/src/androidTest/kotlin/com/ecotrack/bdd/[FeatureName]Feature.kt`

Requirements:
- One `@Test` method per Gherkin scenario from the `.feature` file
- Use the Robot DSL pattern: `onHabitCard("name") { tapCompleteButton() }`
- Assert via content descriptions (not raw text) where possible
- Include the TalkBack accessibility scenario

---

## Step 8 — Verify eco-conception

Before marking the feature done, check with Copilot:

```
Review the [FeatureName]UseCase and its repository implementation.
Identify any:
1. Unnecessary network calls (could be served from local cache)
2. Work that should be deferred to WorkManager
3. Missing database indices for the query pattern used
4. Bitmaps loaded without size constraints
5. Missing `onCompletion` / cancellation handling in coroutines
```

---

## Step 9 — Verify security

Ask Copilot:

```
Audit [FeatureName]UseCase for PII leaks:
1. Are any user-identifiable fields logged?
2. Is any sensitive data stored unencrypted?
3. Could the feature expose data belonging to another user?
4. Are input strings validated before persisting?
```

---

## Checklist before submitting a PR

- [ ] All unit tests pass: `./gradlew test`
- [ ] All instrumented tests pass: `./gradlew connectedAndroidTest`
- [ ] Code style passes: `./gradlew ktlintCheck`
- [ ] No Android imports in `domain/` package
- [ ] All new Composables have `@Preview`
- [ ] All interactive elements have `contentDescription`
- [ ] No PII in log statements
- [ ] Gherkin `.feature` file updated or created
- [ ] GitHub Actions CI is green
