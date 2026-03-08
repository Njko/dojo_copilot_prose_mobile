---
applyTo: "**/*.swift"
---

# Swift / iOS Coding Instructions — EcoTrack

These instructions apply to every `.swift` file in this project.
Copilot will use these as standing context when suggesting code.

---

## Swift 6 concurrency

All types crossing actor boundaries must be `Sendable`.
All mutation of shared state must go through an `actor`.
Never use `@unchecked Sendable` unless you can justify thread-safety manually.

```swift
// REQUIRED for repository fakes in tests
actor InMemoryHabitRepository: HabitRepository {
    private var store: [HabitID: Habit] = [:]
    // ...
}

// REQUIRED for view models
@MainActor
@Observable
final class HabitListViewModel {
    var habits: [Habit] = []
    // ...
}
```

---

## SwiftUI view structure

Every SwiftUI view file follows this structure:

```swift
// FeatureView.swift
// EcoTrack — Presentation/Feature

import SwiftUI

// MARK: - View

struct HabitListView: View {

    @State private var viewModel: HabitListViewModel

    var body: some View {
        content
            .task { await viewModel.loadHabits() }
            .accessibilityElement(children: .contain)
    }

    // MARK: Subviews (break up body into named computed properties)

    private var content: some View {
        // ...
    }
}

// MARK: - Preview

#Preview {
    HabitListView(viewModel: .preview)
}
```

Never put business logic in `body`. Extract to view model methods.

---

## @Observable view models

Use the `@Observable` macro (iOS 17+). Never use `ObservableObject`/`@Published`.

```swift
@MainActor
@Observable
final class HabitListViewModel {

    // MARK: State (auto-observed)
    var habits: [Habit] = []
    var isLoading = false
    var errorMessage: String?

    // MARK: Dependencies (injected)
    private let fetchHabitsUseCase: FetchHabitsUseCase
    private let completeHabitUseCase: CompleteHabitUseCase

    init(
        fetchHabitsUseCase: FetchHabitsUseCase,
        completeHabitUseCase: CompleteHabitUseCase
    ) {
        self.fetchHabitsUseCase = fetchHabitsUseCase
        self.completeHabitUseCase = completeHabitUseCase
    }

    func loadHabits() async {
        isLoading = true
        defer { isLoading = false }
        do {
            habits = try await fetchHabitsUseCase.execute(for: currentUserID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

---

## SwiftData persistence (Infrastructure layer only)

Map domain entities to `@Model` classes in the Infrastructure layer.
Domain entities must not import SwiftData.

```swift
// Infrastructure/Persistence/HabitRecord.swift
import SwiftData

@Model
final class HabitRecord {
    @Attribute(.unique) var id: UUID
    var userID: UUID
    var title: String
    var categoryRawValue: String
    var createdAt: Date

    // Convert TO domain
    func toDomain() throws -> Habit {
        try Habit(
            id: HabitID(id),
            userID: UserID(userID),
            title: title,
            category: HabitCategory(rawValue: categoryRawValue) ?? .consumption,
            targetFrequency: .daily,
            ecoImpact: .placeholder
        )
    }
}
```

---

## OSLog structured logging

```swift
import OSLog

// MARK: - Logger setup (one per type, at file scope)
private let logger = Logger(subsystem: "com.ecotrack.app", category: "HabitListViewModel")

// Usage
logger.info("Habits loaded: \(habits.count, privacy: .public) habits")
logger.error("Failed to load habits: \(error.localizedDescription, privacy: .public)")

// Performance measurement
let signposter = OSSignposter(subsystem: "com.ecotrack.app", category: .pointsOfInterest)
let state = signposter.beginInterval("LoadHabits")
defer { signposter.endInterval("LoadHabits", state) }
```

Privacy levels:
- `.public` — safe to show in Console.app and crash reports
- `.private` — masked as `<private>` in production (use for user content)
- `.sensitive` — masked and cannot be revealed even in development

---

## Keychain usage pattern

```swift
// Infrastructure/Security/KeychainService.swift
import Security

struct KeychainService {

    static func save(token: String, for account: String) throws {
        let data = Data(token.utf8)
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: account,
            kSecValueData:   data,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        SecItemDelete(query as CFDictionary) // remove old item first
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    static func retrieve(for account: String) throws -> String {
        let query: [CFString: Any] = [
            kSecClass:            kSecClassGenericPassword,
            kSecAttrAccount:      account,
            kSecReturnData:       true,
            kSecMatchLimit:       kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            throw KeychainError.retrieveFailed(status)
        }
        return token
    }
}
```

---

## Accessibility checklist

For every interactive view element, verify:

- [ ] `accessibilityLabel` — describes the element ("Complete cycling habit")
- [ ] `accessibilityHint` — describes the action ("Double-tap to record today")
- [ ] `accessibilityValue` — conveys current state ("Streak: 7 days")
- [ ] `accessibilityTraits` — correct trait (`.button`, `.header`, `.isSelected`)
- [ ] Dynamic Type — uses semantic font styles (`.body`, `.headline`, `.caption`)
- [ ] Colour contrast — minimum 4.5:1 for normal text, 3:1 for large text
- [ ] Tap target — minimum 44×44 pt

```swift
HabitRowView(habit: habit)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(habit.title), \(habit.category.rawValue) category")
    .accessibilityValue("Streak: \(habit.currentStreak) days. \(habit.isCompletedToday ? "Completed today" : "Not yet completed today")")
    .accessibilityAddTraits(habit.isCompletedToday ? .isSelected : [])
```

---

## XCTest patterns

### Unit test file template

```swift
final class <TypeName>Tests: XCTestCase {

    // MARK: Properties
    private var sut: <TypeUnderTest>!      // sut = System Under Test
    private var mockRepository: Mock<Repository>!

    // MARK: Lifecycle
    override func setUp() async throws {
        try await super.setUp()
        mockRepository = Mock<Repository>()
        sut = <TypeUnderTest>(repository: mockRepository)
    }

    override func tearDown() async throws {
        sut = nil
        mockRepository = nil
        try await super.tearDown()
    }

    // MARK: Tests
    func test_<method>_<condition>_<expectedResult>() async throws { }
}
```

### XCUITest pattern

```swift
final class HabitCompletionUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-data"]
        app.launch()
    }

    func test_completingHabit_showsCheckmarkAndUpdatesStreak() {
        // Given
        let habitRow = app.cells["habit-cycling-to-work"]
        XCTAssertTrue(habitRow.waitForExistence(timeout: 5))

        // When
        habitRow.buttons["complete-habit-button"].tap()

        // Then
        XCTAssertTrue(app.staticTexts["streak-label-1"].waitForExistence(timeout: 2))
    }
}
```

---

## Eco-conception quick reference

| Pattern | Avoid | Prefer |
|---|---|---|
| Lists | `VStack + ForEach` | `LazyVStack + ForEach` |
| Images | Pre-fetching all | `AsyncImage` on-demand |
| Background work | `Timer.scheduledTimer` | `BGAppRefreshTask` |
| Main thread | `DispatchQueue.main.async` | `@MainActor` / `MainActor.run` |
| Logging | `print()` | `Logger` (OSLog) |
| State | `@Published` | `@Observable` |
| Persistence | `UserDefaults` for credentials | `Keychain` |

---

## Naming quick reference

| Thing | Convention | Example |
|---|---|---|
| Protocol | Noun / adjective | `HabitRepository`, `Completable` |
| Use Case struct | `<Verb><Noun>UseCase` | `CompleteHabitUseCase` |
| View Model | `<Feature>ViewModel` | `HabitListViewModel` |
| SwiftUI View | `<Feature>View` | `HabitDetailView` |
| Test double | `Fake<Protocol>` / `InMemory<Protocol>` / `Mock<Protocol>` | `FakeHabitRepository` / `InMemoryHabitRepository` |
| Test file | `<TypeUnderTest>Tests` | `CompleteHabitUseCaseTests` |
| BDD test method | `test_given<Context>_when<Action>_then<Outcome>` | `test_givenFreshHabit_whenCompletedToday_thenStreakIsOne` |

---

## VS Code + Swift — Prérequis session

### Extension requise
- `sswg.swift-lang` (Swift Language Support) — `Cmd+Shift+P` → "Extensions" → "sswg.swift-lang"
- Vérifier : ouvrir un `.swift`, les types affichent du type inference inline

### Lancer les tests
```bash
# Depuis la racine du package iOS
cd ecotrack-ios
swift test                                     # tous les tests
swift test --filter CompleteHabitUseCaseTests  # un seul fichier
```

### SPM — ce qu'il faut savoir
- Les fichiers dans `Sources/EcoTrack/Domain/` sont inclus **automatiquement** — pas de config
- `Package.swift` exclut `Presentation/` — c'est intentionnel (hors périmètre dojo)
- Si `swift test` échoue avec "no such module", vérifier que `swift` est dans le PATH : `which swift`
