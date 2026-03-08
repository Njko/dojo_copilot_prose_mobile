# EcoTrack Domain Spec — v1.0

> **Scope:** Habit entity, EcoAction value object, CarbonDelta calculation
> **Sprint:** 1 — Foundation Domain
> **Status:** Draft — ready for dojo implementation

---

## Overview

EcoTrack helps users reduce their carbon footprint by tracking eco-friendly habits.
This spec defines the core domain model: what a Habit is, what an EcoAction records,
and how CarbonDelta is calculated. UI, storage, networking, and notifications are
explicitly out of scope for this sprint.

---

## Domain Model

### Entities

#### `Habit`
An entity with a stable identity across time.

| Field | Type | Constraints |
|---|---|---|
| `id` | UUID | Immutable; system-generated |
| `name` | String | Non-blank; max 60 chars |
| `category` | HabitCategory | Sealed type; see below |
| `createdAt` | Instant | UTC; immutable |
| `isActive` | Boolean | Default `true` |

#### `UserProfile`
Aggregate root. Owns a collection of Habits and one FootprintBaseline.

| Field | Type | Constraints |
|---|---|---|
| `id` | UUID | Immutable |
| `habits` | List\<Habit\> | Max 50 active habits |
| `baseline` | FootprintBaseline | Default: 8.5 tCO2e/year |

---

### Value Objects

#### `EcoAction`
A single recorded occurrence of a Habit. Identified by its content, not by identity.

| Field | Type | Constraints |
|---|---|---|
| `habitId` | UUID | References a Habit |
| `category` | HabitCategory | Copied from Habit at recording time |
| `name` | String | Non-blank |
| `distanceKm` | Double? | Required for Transport category; null otherwise |
| `durationMinutes` | Int? | Optional for Energy category |
| `recordedAt` | Instant | UTC; immutable |

#### `CarbonDelta`
The CO2e change (in kg) produced by one EcoAction.

| Field | Type | Constraints |
|---|---|---|
| `kgCO2e` | Double | Always finite; negative = saving; never NaN |

#### `FootprintBaseline`
The user's annual CO2e before any habit changes.

| Field | Type | Constraints |
|---|---|---|
| `tCO2ePerYear` | Double | Always positive; never zero |

---

### Sealed Type: `HabitCategory`

> **Source de vérité :** `HabitCategory` est le terme canonique du domaine — utilisé dans le code Kotlin (`enum class HabitCategory`) et Swift (`.transport`, `.food`, etc.). Ne pas créer d'enum alternatif `ActionCategory`. Voir `domain.instructions.md` pour la définition complète.

```
HabitCategory
  ├── Transport   (cycling, walking, e-bike, bus, train, car, flight)
  ├── Food        (vegan, vegetarian, meat, fish)
  ├── Energy      (thermostat adjustment, renewable tariff, LED bulbs)
  ├── Consumption (reusable cup, secondhand purchase, repair instead of replace)
  └── Waste       (composting, recycling, plastic-free)
```

---

## Invariants

These rules must never be violated. Tests must assert each invariant.

1. `CarbonDelta.kgCO2e` is always a finite Double — no NaN, no Infinity
2. `CarbonDelta.kgCO2e` may be zero (some actions have no measurable delta)
3. Dividing by `FootprintBaseline.tCO2ePerYear` must be guarded — baseline is never zero by contract, but defensive code is required
4. `EcoAction.name` is never blank
5. `EcoAction.distanceKm` is required (non-null, positive) when `category == Transport`
6. `Habit.id` is never reused after a Habit is deactivated
7. `UserProfile.habits` contains at most 50 active habits

---

## Acceptance Criteria

These BDD scenarios define "done" for this spec.

```gherkin
Scenario: User logs a cycling commute
  Given the user has a FootprintBaseline of 8.5 tCO2e/year
  And the user has an active Habit named "Cycling to work" in Transport category
  When the user records an EcoAction with distanceKm = 12.0
  Then the CarbonDelta is -1.8 kgCO2e (within 0.001 tolerance)
  And the result is announced to screen readers as "Saving 1.8 kg CO2"

Scenario: Zero-delta action does not cause arithmetic error
  Given the user records an EcoAction for "Reusable Cup" in Consumption category
  When CarbonDelta is calculated
  Then CarbonDelta.kgCO2e equals 0.0
  And calling FootprintCalculator.percentageOf(delta, baseline) does not throw

Scenario: Long-haul flight avoided is calculated correctly
  Given an EcoAction for "Avoided flight" in Transport category
  And the distance is 5000 km (return short-haul equivalent)
  When CarbonDelta is calculated
  Then CarbonDelta.kgCO2e is -1275.0 (within 1.0 tolerance)
  And the value is displayed without truncation

Scenario: Crash report does not leak habit data
  Given a fatal error occurs during habit submission
  When the crash reporting service receives the error
  Then the crash payload does not contain the habit name
  And the crash payload does not contain the user ID
  And the crash payload does not contain EcoAction details

Scenario: Carbon calculation works offline
  Given the device has no network connectivity
  When the user records any EcoAction
  Then CarbonDelta is calculated using local emission factors
  And the result matches server-side calculation within 0.001 kgCO2e tolerance
```

---

## Out of Scope — Sprint 1

The following are explicitly deferred. Do not generate code for these.

- User authentication and registration
- Push notifications and habit reminders
- Leaderboards and social sharing
- Cloud sync and backend API
- UI layer (Composables, SwiftUI Views, ViewModels)
- Onboarding flow
- Carbon offset purchasing
- Habit streaks and gamification

---

## Success Metrics

This spec is complete when:

- [ ] All 5 acceptance criteria scenarios have passing automated tests
- [ ] `CarbonCalculator` is a pure function with 100% branch coverage
- [ ] All 7 domain invariants have dedicated test assertions
- [ ] No `import android.*` or `import UIKit` in domain source files
- [ ] KDoc / DocC comment on every public type and function
- [ ] Security: no PII in error messages or log output (verified by test)
- [ ] Eco: no network call in the domain layer (verified by architecture test)

---

## Dependencies and References

- Emission factors: `domain.instructions.md` — ADEME 2024 dataset
- Coding rules: `.github/copilot-instructions.md`
- BDD prompt: `.github/prompts/habit-bdd.prompt.md`
- TDD prompt: `.github/prompts/carbon-calculator.prompt.md`
