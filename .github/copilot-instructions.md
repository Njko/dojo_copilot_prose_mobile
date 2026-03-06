# EcoTrack — GitHub Copilot Global Instructions

These instructions apply to every Copilot interaction in this repository.
They are the foundation layer of the PROSE Explicit Hierarchy.

## Domain Language

Use the following terms consistently. Do not invent synonyms.

- **Habit** — a recurring eco-friendly action logged by a user
- **EcoAction** — a single instance of a Habit being performed (value object)
- **CarbonDelta** — the CO2e change (kg) produced by one EcoAction; negative = saving
- **FootprintBaseline** — the user's annual CO2e emissions before any habits (tCO2e/year)
- **UserProfile** — aggregate root; owns habits and baseline; never exposed raw to UI

## Code Quality

- **TDD-first**: write a failing test before writing implementation
- **No logic in UI layer**: ViewModels and Composables/SwiftUI Views contain zero business logic
- **Immutable domain models**: domain entities and value objects are immutable data classes / structs
- **Pure functions for calculations**: CarbonCalculator functions have no side effects

## Platform Rules

- Android: Kotlin, Jetpack Compose, JUnit 5, Hilt for DI
- iOS: Swift, SwiftUI, XCTest, Swift Concurrency (async/await)
- Shared domain logic: described in `.spec.md` files; implemented per-platform, not in KMP unless explicitly specified

## Accessibility (WCAG 2.2 AA minimum)

- Every interactive element must have a semantic label (contentDescription / accessibilityLabel)
- Minimum touch target: 44×44dp (Android) / 44×44pt (iOS)
- Never use color as the sole means of conveying information
- All font sizes use scalable units: `sp` (Android) or Dynamic Type styles (iOS)

## Security & Privacy

- **No PII in logs**: habit names, user IDs, and location data must never appear in log output
- **No hardcoded secrets**: API keys, OAuth credentials, and lookup URLs go in environment config
- **Encryption at rest**: use Android Keystore / iOS Keychain for sensitive data
- **Crash reports**: scrub EcoAction descriptions and habit names before submission to any crash service

## Eco-Conception

The app must model the values it promotes:

- No background polling under 15-minute intervals
- Batch network calls — no single-item fetches inside loops
- Prefer local computation over server round-trips for carbon calculation
- Support offline mode for all core features
- Dark mode required (OLED energy saving)
