---
mode: "agent"
description: "Implement an EcoTrack feature using TDD red-green-refactor with DDD and Clean Architecture."
---

# Prompt: Implement Feature with TDD

Use this prompt template when you want Copilot to implement a new feature.
Fill in the `[ ]` placeholders, then submit to Copilot Chat or Copilot Edits.

---

## Instructions for participants

1. Open the relevant failing test file alongside this prompt.
2. Fill in all `[PLACEHOLDER]` values below.
3. Submit to **Copilot Chat** (sidebar) or **Copilot Edits** (multi-file mode).
4. Review every suggestion before accepting — Copilot is your pair, not your autopilot.
5. Run tests after each acceptance: `Cmd+U`.

---

## The Prompt (copy and customise)

```
I am working on the EcoTrack iOS app (Swift 6, iOS 18, Clean Architecture + MVVM).

## Feature to implement
[DESCRIBE THE FEATURE IN ONE SENTENCE — e.g., "Record a habit completion for today"]

## Use case / method to implement
File: [e.g., Sources/EcoTrack/Domain/UseCases/CompleteHabitUseCase.swift]
Method: [e.g., CompleteHabitUseCase.execute(habitID:on:note:)]

## Failing tests I need to make pass
File: [e.g., Tests/EcoTrackTests/Domain/CompleteHabitUseCaseTests.swift]
Tests:
- [e.g., test_execute_withValidHabit_returnsHabitWithTodayCompletion]
- [e.g., test_execute_persistsCompletionToRepository]
- [e.g., test_execute_withUnknownHabitID_throwsHabitNotFound]

## TDD rules (follow strictly)
1. Implement ONLY what is needed to make the listed failing tests pass.
2. Do NOT add functionality not covered by a test.
3. Follow red-green-refactor: show me the minimum passing implementation first,
   then suggest a refactoring step if appropriate.

## Architecture constraints
- This is the DOMAIN layer. Zero UIKit/SwiftUI/SwiftData imports.
- The method is async throws. Use the injected `habitRepository` (a protocol).
- Log with OSLog: log habit IDs (.public) never user content (.private).
- Handle these domain errors from HabitError: habitNotFound, alreadyCompletedToday, futureCompletion.

## What I expect from you
1. Show me the implementation of the method body only (not the full file).
2. Explain WHY each step satisfies a specific test case.
3. Point out any edge case the tests do not cover yet (so I can add a test).
4. Do NOT use force unwrap (!). Do NOT use print(). Do NOT use singletons.
```

---

## Example: completed prompt for CompleteHabitUseCase

```
I am working on the EcoTrack iOS app (Swift 6, iOS 18, Clean Architecture + MVVM).

## Feature to implement
Record a habit completion for a given date and persist it to the repository.

## Use case / method to implement
File: Sources/EcoTrack/Domain/UseCases/CompleteHabitUseCase.swift
Method: CompleteHabitUseCase.execute(habitID:on:note:)

## Failing tests I need to make pass
File: Tests/EcoTrackTests/Domain/CompleteHabitUseCaseTests.swift
Tests:
- test_execute_withValidHabit_returnsHabitWithTodayCompletion
- test_execute_persistsCompletionToRepository
- test_execute_withNoHistory_streakIsOne
- test_execute_withNote_recordsNoteOnCompletion
- test_execute_withUnknownHabitID_throwsHabitNotFound
- test_execute_whenAlreadyCompletedToday_throwsAlreadyCompletedError
- test_execute_carbonSavedAccumulatesPerCompletion
- test_execute_withFutureDate_throwsFutureCompletionError

## TDD rules (follow strictly)
1. Implement ONLY what is needed to make the listed failing tests pass.
2. Do NOT add functionality not covered by a test.
3. Follow red-green-refactor.

## Architecture constraints
- Domain layer. No UIKit/SwiftUI/SwiftData imports.
- The method is async throws. Use the injected habitRepository protocol.
- Log with OSLog: habitID is .public, dates are .private.
- Handle: HabitError.habitNotFound, .alreadyCompletedToday, .futureCompletion.

## What I expect from you
1. Implementation of execute(habitID:on:note:) method body only.
2. Explain which test each step satisfies.
3. Identify any missing edge cases I should test.
4. No force unwrap. No print. No singletons.
```

---

## Follow-up prompts (use after the first implementation)

### Add accessibility to a SwiftUI view
```
This SwiftUI view displays a HabitRowView. Add complete VoiceOver support:
- accessibilityLabel combining title and category
- accessibilityValue with streak and completion state
- accessibilityHint for the complete button
- accessibilityTrait .isSelected when completed today
- Support Dynamic Type (no hardcoded font sizes)
Follow WCAG 2.1 AA guidelines. Show me the modified view code only.
```

### Add OSLog to an existing class
```
Replace all print() statements in this file with structured OSLog calls.
- Use Logger(subsystem: "com.ecotrack.app", category: "<ClassName>")
- User IDs and habit IDs → .public
- Habit titles, notes, user names → .private
- Dates → .private
- Error messages → .public (already localised, no PII)
Show me only the changed lines with before/after.
```

### Write a BDD test for a new scenario
```
Write an XCTest BDD scenario for this user story:

"As a user, when I view my habit list,
I want habits sorted by streak length (highest first),
so that I can see my most consistent habits at the top."

Use Given/When/Then naming: test_given<Context>_when<Action>_then<Outcome>
Use the InMemoryHabitRepository fake already defined in the test file.
No Quick/Nimble dependencies.
```

### Generate a SwiftData persistence adapter
```
Create a SwiftData implementation of HabitRepository for the Infrastructure layer.

Requirements:
- File: Sources/EcoTrack/Infrastructure/Persistence/SwiftDataHabitRepository.swift
- Conform to: HabitRepository protocol (defined in Domain layer)
- Use @Model class HabitRecord as the persistence type (separate from Habit domain entity)
- Map between HabitRecord and Habit using toDomain() / fromDomain() methods
- The repository must be an actor (Swift 6 Sendable)
- Use ModelContext injected via init (not a shared container)
- Log operations with OSLog, no PII
- Handle SwiftData errors and map them to domain errors where appropriate
```

### Write a GitHub Actions step
```
Add a new job to the existing .github/workflows/ci.yml that:
- Runs only when files in Tests/ change (path filter)
- Executes XCUITest on iPhone 16 simulator (iOS 18)
- Uploads the xcresult bundle as a GitHub Actions artifact
- Fails the workflow if any UI test fails
- Times out after 20 minutes
Show me the YAML job definition only.
```

---

## Copilot keyboard shortcuts reminder

| Action | Shortcut (Xcode) |
|---|---|
| Open Copilot Chat | `Cmd+Shift+\` |
| Accept inline suggestion | `Tab` |
| Dismiss inline suggestion | `Esc` |
| Next suggestion | `Option+]` |
| Previous suggestion | `Option+[` |
| Explain selected code | Right-click → Copilot → Explain |
| Fix with Copilot | Right-click → Copilot → Fix |
| Generate tests | Right-click → Copilot → Generate Tests |
