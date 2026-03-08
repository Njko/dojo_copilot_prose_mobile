---
applyTo: "**/*.kt,**/*.swift"
---

# EcoTrack Eco-Conception Instructions

The app must model the values it promotes. These rules ensure EcoTrack
itself has a minimal digital carbon footprint.
Flag violations with `// ECO: <reason>` before the offending line.

## No Aggressive Background Work

- Background polling minimum interval: 15 minutes
- Use platform-native scheduling: `WorkManager` (Android) / `BGAppRefreshTask` (iOS)
- Prefer push notifications over pull polling for server-driven updates

```kotlin
// OK:
PeriodicWorkRequestBuilder<SyncWorker>(15, TimeUnit.MINUTES).build()
// ECO: polling too frequent, wastes battery and data
PeriodicWorkRequestBuilder<SyncWorker>(1, TimeUnit.MINUTES).build()
```

## Batch Network Calls

- Never fetch a single item in a loop — always batch
- Accumulate changes locally and sync in one request

```swift
// OK:
habitRepository.syncAll(habits) // one call, many habits
// ECO: N+1 network calls — batch these
for habit in habits { habitRepository.sync(habit) }
```

## Image Handling

- All user-facing images must use WebP format (not PNG/JPEG where avoidable)
- Use lazy loading — do not preload images off-screen
- Provide 1x, 2x, 3x assets — do not upscale 1x assets at runtime

## Local Computation First

- Carbon calculations run locally using bundled emission factors
- Server is used for sync and leaderboards only — not for core calculations
- If a network call returns a carbon factor that differs from local, log a warning; do not silently replace the local value

```kotlin
// OK:
val delta = CarbonCalculator.calculate(action) // local, always available
// ECO: unnecessary round-trip for data we already have locally
val delta = apiService.calculateCarbon(action).await()
```

## Dark Mode — Required

- Dark mode is mandatory (OLED screens consume significantly less power in dark mode)
- Do not use pure black `#000000` on OLED — use `#121212` (Material You dark surface)
- Test both light and dark in every UI review

## No Autoplay Media

- No videos, animations, or audio may autoplay
- Motion animations must respect `prefers-reduced-motion` / `UIAccessibility.isReduceMotionEnabled`

```swift
// OK:
if !UIAccessibility.isReduceMotionEnabled {
    startCelebrationAnimation()
}
// ECO + A11Y: autoplay animation ignores user preference
startCelebrationAnimation()
```

## Bundle Size Hygiene

- Do not add a dependency that is available in the platform SDK
- Review dependency size impact before adding to `build.gradle` / `Package.swift`
- Remove unused assets and translations before each release
