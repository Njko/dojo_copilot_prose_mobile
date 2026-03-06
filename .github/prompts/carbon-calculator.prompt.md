---
mode: "chat"
description: "Generate TDD unit tests and implementation for the CarbonCalculator domain function"
---

# CarbonCalculator TDD Generator

## Context

Read the domain model and invariants from [ecotrack-domain.spec.md](../../ecotrack-domain.spec.md).
Apply domain rules from [domain.instructions.md](../instructions/domain.instructions.md).
Apply security rules from [security.instructions.md](../instructions/security.instructions.md).

**Input:** The BDD scenarios produced by [habit-bdd.prompt.md](habit-bdd.prompt.md)
for category `{{HABIT_CATEGORY}}`.

**Platform:** `{{PLATFORM}}` — either `android` (Kotlin/JUnit5) or `ios` (Swift/XCTest)

## Phase 1 — Generate Failing Tests (RED)

Generate a test class named:
- Android: `CarbonCalculatorTest` in `src/test/kotlin/domain/`
- iOS: `CarbonCalculatorTests` in `EcoTrackTests/Domain/`

### Requirements for the test class

1. **One test per BDD scenario** — use the scenario title as the test display name
2. **Tests must fail** — do not generate the implementation yet; reference types and functions that do not exist
3. **Naming convention:**
   - Android: `@Test @DisplayName("scenario title") fun \`snake_case description\`()`
   - iOS: `func test_camelCaseDescription()`
4. **Cover all invariants from the spec:**
   - CarbonDelta is never NaN or Infinite
   - Zero baseline does not cause division by zero
   - Zero delta is represented as `CarbonDelta(0.0)` not null
5. **Include the security test:**
   - Simulate a crash report builder
   - Assert that `habitName` and `userId` do not appear in the report string
6. **Emission factors from domain.instructions.md only** — no hardcoded magic numbers in tests; reference named constants

### Android output template

```kotlin
@DisplayName("Carbon Calculator — {{HABIT_CATEGORY}}")
class CarbonCalculatorTest {

    @Test
    @DisplayName("{{scenario_title}}")
    fun `{{snake_case_description}}`() {
        // Arrange
        val action = EcoAction(...)
        // Act
        val result = CarbonCalculator.calculate(action)
        // Assert
        assertThat(result.kgCO2e).isCloseTo(expected, within(0.001))
    }
}
```

### iOS output template

```swift
final class CarbonCalculatorTests: XCTestCase {

    func test_{{camelCaseDescription}}() {
        // Arrange
        let action = EcoAction(...)
        // Act
        let result = CarbonCalculator.calculate(action)
        // Assert
        XCTAssertEqual(result.kgCO2e, expected, accuracy: 0.001)
    }
}
```

## Phase 2 — Generate Implementation (GREEN)

**Only run Phase 2 after all Phase 1 tests compile and fail.**

Generate `CarbonCalculator` as a pure object/enum with no stored state:

1. Input: `EcoAction` (category, name, optional distance, optional duration)
2. Output: `CarbonDelta` (wrapping a finite Double)
3. Use emission factors from `domain.instructions.md` as named constants
4. Guard: if input produces NaN or Infinite, return `CarbonDelta(0.0)` and log a warning (no crash)
5. Guard: `FootprintCalculator.percentageOf(delta:baseline:)` must handle zero baseline — return `0.0` not divide
6. No network calls, no storage access, no DI dependencies — pure function only

## Phase 3 — Refactor Checklist

After tests go GREEN, verify:

- [ ] All constants are named (no magic numbers)
- [ ] KDoc / DocC on public functions
- [ ] No `import android.*` or `import UIKit` in domain files
- [ ] Security: no habit data in any thrown error message
- [ ] ECO: no network call anywhere in this file
