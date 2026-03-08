---
mode: "chat"
description: "Generate Gherkin BDD scenarios for a given EcoTrack habit category"
---

> **Checklist avant d'exécuter ce prompt — 30 secondes :**
> - [ ] J'ai remplacé `{{HABIT_CATEGORY}}` ci-dessous par une valeur concrète (`transport`, `food`, `energy`, `consumption` ou `waste`)
> - [ ] J'ai sauvegardé le fichier (`Ctrl+S` / `Cmd+S`)
> - [ ] Le fichier `domain.instructions.md` est bien dans `.github/instructions/`
> - [ ] Le bloc `---mode: "chat"---` est présent en première ligne de ce fichier
>
> ⚠️ Copilot ne substitue PAS `{{variables}}` automatiquement. Si oublié, le Gherkin contiendra `{{HABIT_CATEGORY}}` tel quel — inutilisable.

# Habit BDD Scenario Generator

## Context (just-in-time — do not duplicate this elsewhere)

Read the domain model from [ecotrack-domain.spec.md](../../ecotrack-domain.spec.md).
Apply domain language rules from [domain.instructions.md](../instructions/domain.instructions.md).
Apply security rules from [security.instructions.md](../instructions/security.instructions.md).
Apply accessibility rules from [accessibility.instructions.md](../instructions/accessibility.instructions.md).

## Task

Generate a complete Gherkin feature file for the **{{HABIT_CATEGORY}}** category of habits.

The feature file must include:

### 1. Happy Path Scenario
- User selects an EcoAction in the `{{HABIT_CATEGORY}}` category
- Provides required input (e.g., distance in km for Transport, meal type for Food)
- Records the habit
- CarbonDelta is calculated and displayed correctly
- Screen reader announces the result

### 2. Edge Case — Zero or Negligible Delta
- An action that produces a CarbonDelta of exactly 0.0
- The app handles the zero value without division-by-zero in percentage calculations
- Display still shows icon + text (not color-only)

### 3. Edge Case — Maximum Realistic Value
- An action with an unusually large delta (e.g., long-haul flight avoided)
- Value is displayed correctly without overflow or truncation

### 4. Accessibility Scenario
- User navigates the habit logging flow using a screen reader (TalkBack / VoiceOver)
- Every interactive step has an announced label
- Completion is announced via live region

### 5. Security Scenario
- A crash occurs during habit submission
- The generated crash report payload must not contain:
  - The habit name or description
  - The user's ID or email
  - Any EcoAction details

### 6. Eco-Conception Scenario
- The carbon calculation completes without a network call
- The result is identical to the server-side calculation (within 0.001 kgCO2e tolerance)

## Output Format

```gherkin
Feature: {{HABIT_CATEGORY}} Habit Tracking

  Background:
    Given the user has a FootprintBaseline of <value> tCO2e/year
    And the device is offline  # eco-conception: local calc works offline

  Scenario: <title>
    Given ...
    When ...
    Then ...
    And ...  # accessibility: screen reader announces result
```

## Constraints

- Use only domain terms from `ecotrack-domain.spec.md`
- All `Then` steps that involve display must have a paired accessibility step
- The security scenario's `Then` step must be a negative assertion ("must not contain")
- Do not generate implementation code — Gherkin only
- Maximum 6 scenarios (Reduced Scope: one file, one category, one sprint)
