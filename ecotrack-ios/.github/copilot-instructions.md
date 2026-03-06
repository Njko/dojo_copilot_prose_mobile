# GitHub Copilot Instructions — EcoTrack iOS

> **Dojo context:** This is a 1-hour GitHub Copilot dojo project.
> The goal is to practice TDD, BDD, DDD, eco-conception, accessibility, security,
> automation, and observability using Copilot as an AI pair programmer.

---

## Project overview

**EcoTrack** is an iOS 18 app (Swift 6) that helps users track eco-friendly habits
and visualise their cumulative carbon footprint reduction.

Architecture: **Clean Architecture + MVVM**
- `Domain` — Pure Swift entities, value objects, use-case protocols. Zero framework imports.
- `Infrastructure` — Concrete adapters (SwiftData persistence, URLSession networking, Keychain).
- `Presentation` — SwiftUI views + `@Observable` view models.
- `App` — Composition root, dependency injection, app entry point.

---

## PROSE methodology

When generating code, always respect these boundaries:

| Principle | Rule |
|---|---|
| **P**rogressive Disclosure | Start with the simplest implementation. Add complexity only when a test demands it. |
| **R**educed Scope | One use case per file. One responsibility per type. |
| **O**rchestrated Composition | Use cases depend on repository **protocols**, never concrete classes. Inject everything. |
| **S**afety Boundaries | Domain layer has **no** UIKit, SwiftUI, or network imports. |
| **E**xplicit Hierarchy | Domain → Infrastructure → Presentation. Never import upward. |

---

## Language & framework

- **Swift 6** with strict concurrency (`Sendable`, `actor`, `async/await`).
- **SwiftUI** for all UI (no UIKit unless wrapping a system component).
- **SwiftData** for local persistence (not CoreData).
- **XCTest** for unit and integration tests. **XCUITest** for UI tests.
- **OSLog** for structured logging (never `print()` in production code).
- Minimum deployment target: **iOS 18.0**.
- No third-party dependencies unless explicitly approved by the facilitator.

---

## TDD rules (enforce strictly)

1. Write a **failing test first** (`XCTFail` or unimplemented stub that compiles but throws).
2. Write the **minimum code** to make it pass — no gold-plating.
3. **Refactor** once green, keeping tests green.
4. Every public method on a domain type **must** have at least one unit test.
5. Use `async throws` tests with `await` — never use `XCTestExpectation` for async/await code.

```swift
// GOOD — async test
func test_execute_savesHabit() async throws {
    let result = try await sut.execute(habitID: id)
    XCTAssertTrue(result.isCompletedToday)
}

// BAD — XCTestExpectation is not needed for async/await
func test_execute_savesHabit() {
    let exp = expectation(description: "...")
    Task { ... exp.fulfill() }
    wait(for: [exp])
}
```

---

## BDD conventions

Structure tests with Given/When/Then **either** as comments or as helper method names:

```swift
// Given a habit with no completions
// When completed today
// Then streak is 1
func test_givenFreshHabit_whenCompletedToday_thenStreakIsOne() throws { ... }
```

Test class names must match the **Feature** being specified:
`HabitCompletionBDDTests`, `HabitCreationBDDTests`, `CarbonFootprintBDDTests`.

---

## DDD rules

- **Entities** have identity (`id: HabitID`). Use typed ID wrappers — never raw `UUID` or `String`.
- **Value Objects** are immutable structs with no identity (`CarbonFootprint`, `Frequency`, `EcoImpact`).
- **Aggregate roots** (`Habit`, `User`) own their child objects and enforce invariants via `throws`.
- **Repositories** are protocols in the Domain layer. Implementations live in Infrastructure.
- **Use Cases** orchestrate one domain operation. They do not contain UI logic.
- **Domain Errors** are typed enums conforming to `LocalizedError`.

```swift
// GOOD — typed ID, domain error
struct HabitID: Hashable, Sendable { let rawValue: UUID }
throw HabitError.alreadyCompletedToday

// BAD — stringly typed, generic error
throw NSError(domain: "Habit", code: 1)
```

---

## Eco-conception (energy & battery efficiency)

- **No polling.** Use `AsyncStream` or Combine publishers driven by data changes.
- **Batch network requests.** Never fire one request per list item.
- **Lazy load images.** Use `AsyncImage` with a placeholder, never pre-fetch all images.
- **Avoid `Timer` in background.** Use `BackgroundTasks` framework with appropriate intervals.
- **Dark mode support.** OLED screens use less power with dark backgrounds — always support both.
- **Avoid forced layout recalculations.** Prefer `LazyVStack`/`LazyHStack` for long lists.
- **No `print()`.** Use OSLog. Log at `.debug` level for verbose output, `.info` for user actions.

```swift
// GOOD — energy-efficient list
LazyVStack {
    ForEach(habits) { habit in HabitRowView(habit: habit) }
}

// BAD — eager rendering
VStack {
    ForEach(habits) { habit in HabitRowView(habit: habit) }
}
```

---

## Accessibility

Every interactive SwiftUI element **must** have:
- `.accessibilityLabel()` with a meaningful, localised string.
- `.accessibilityHint()` for non-obvious actions.
- `.accessibilityValue()` for elements that convey state (streaks, progress).
- Support for **Dynamic Type** — use `.font(.body)` semantic styles, never fixed sizes.
- VoiceOver grouping with `.accessibilityElement(children: .combine)` for composite views.

```swift
// GOOD
Button(action: completeHabit) {
    Label("Complete", systemImage: "checkmark.circle")
}
.accessibilityLabel(Text("Mark \(habit.title) as complete"))
.accessibilityHint(Text("Double-tap to record today's completion"))
.accessibilityValue(Text(habit.isCompletedToday ? "Already completed" : "Not yet completed"))

// BAD — no accessibility metadata
Button(action: completeHabit) {
    Image(systemName: "checkmark.circle")
}
```

---

## Security

- **Keychain only** for auth tokens, session IDs, and any credential. Never `UserDefaults`.
- **No PII in logs.** Use `OSLogPrivacy`:
  ```swift
  logger.info("Habit completed: \(habitID, privacy: .public)")      // OK — ID not PII
  logger.debug("User email: \(email, privacy: .private)")           // Masked in production
  // NEVER:
  logger.error("User: \(user.email)")                               // PII in logs!
  ```
- **Certificate pinning** for all production API calls. Use `URLSession` with a custom
  `URLSessionDelegate` implementing `urlSession(_:didReceive:completionHandler:)`.
- **No hardcoded secrets** in source code. Use `.xcconfig` + environment variables in CI.
- **Enable App Transport Security** — no HTTP in production.
- Input validation at the domain boundary (use-case layer), not only in the UI.

---

## Observability

- Use **OSLog** with subsystem `com.ecotrack.app` and meaningful categories:
  ```swift
  private let logger = Logger(subsystem: "com.ecotrack.app", category: "HabitRepository")
  ```
- Log **user actions** at `.info`, **debug details** at `.debug`, **errors** at `.error`.
- Instrument **performance-sensitive paths** with `OSSignpost`:
  ```swift
  let signpost = OSSignposter(subsystem: "com.ecotrack.app", category: "Network")
  let state = signpost.beginInterval("FetchHabits")
  defer { signpost.endInterval("FetchHabits", state) }
  ```
- Use **MetricKit** to collect on-device performance metrics (battery impact, hang rate).
- Crash reporting: integrate a crash reporter (e.g., Firebase Crashlytics) at the App layer only.

---

## Code style

- `camelCase` for variables and functions.
- `PascalCase` for types, protocols, enums.
- Protocol names end in `-able`, `-ing`, `-Repository`, or `-UseCase`. Never suffix with `-Protocol`.
- Extensions grouped by `// MARK: -` comments.
- Maximum line length: **120 characters**.
- No `force unwrap` (`!`) except in test setup and `static let` constants with known-safe values.
- Prefer `guard let` over nested `if let`.
- All `async` functions **throw** or return a `Result` — no silent failures.

---

## What Copilot should NOT do

- Do not import `UIKit` in the Domain or Presentation layers unless bridging a UIKit component.
- Do not use `@StateObject` — prefer `@State` with `@Observable` (Swift 5.9+).
- Do not use `DispatchQueue.main.async` — use `@MainActor` or `MainActor.run`.
- Do not use `Codable` in domain entities — mapping to/from JSON belongs in Infrastructure.
- Do not generate singleton `shared` instances — use dependency injection.
- Do not write `// TODO:` comments — convert them to failing tests instead.

---

## Suggested Copilot prompt patterns for this dojo

See `.github/instructions/swift-ios.instructions.md` for full prompt catalogue.

Quick reference:
- `"Implement [MethodName] following TDD red-green-refactor. Start with the minimum code to pass the failing tests in [TestFile]."`
- `"Add accessibility modifiers to this SwiftUI view following WCAG 2.1 AA guidelines."`
- `"Refactor this to use OSLog instead of print statements. No PII in log messages."`
- `"Write BDD Given/When/Then tests for the [Feature] feature using XCTest."`
- `"Generate a SwiftData model that persists this domain entity without leaking domain types."`
