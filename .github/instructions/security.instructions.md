---
applyTo: "**/*.kt,**/*.swift"
---

# EcoTrack Security & Privacy Instructions

These guardrails apply to all Kotlin and Swift files.
Flag violations inline with `// SECURITY: <reason>` before the offending line.

## PII — Never Log or Expose

NEVER log PII data at any log level.
This applies to android.util.Log, Timber, or any logging framework.
Bad: Log.d(TAG, "User: $userId")
Bad: Timber.d("Habit name: ${habit.name}")
Good: Log.d(TAG, "Habit ID: ${habitId}")  // ID only, not user content

The following are PII and must never appear in:
- Log statements (`Log.d`, `Timber.d`, `print`, `NSLog`, `console.log`, Logcat, or any logging framework)
- Crash report payloads (Crashlytics, Sentry, Firebase)
- Analytics event properties
- Error messages surfaced to external services

**PII list for EcoTrack:**
- User ID or email
- Habit names and descriptions
- EcoAction details
- Location data (GPS coordinates, city names)
- Device identifiers beyond what the platform allows

**Required pattern — crash report scrubbing:**
```kotlin
// Android — before any crash report submission:
crashReport.customKeys {
    key("habit_count", habits.size) // OK: aggregate count only
    // DO NOT: key("last_habit", lastHabit.name) — PII
}
```

```swift
// iOS — before any Crashlytics/Sentry submission:
Crashlytics.crashlytics().setCustomValue(habits.count, forKey: "habit_count") // OK
// DO NOT: Crashlytics.crashlytics().setCustomValue(habit.name, forKey: "habit_name") — PII
```

## Credentials — Never Hardcode

- No API keys, tokens, or OAuth secrets in source files
- Use `local.properties` (Android) or `.xcconfig` excluded from git (iOS)
- Reference via `BuildConfig.CARBON_API_KEY` (Android) or `Bundle.main.infoDictionary` (iOS)

## Encryption at Rest

- Sensitive user data (profile, habits) must use:
  - Android: `EncryptedSharedPreferences` or `Room` with `SQLCipher`
  - iOS: `Keychain` for secrets; `FileProtection.complete` for documents
- Do not store `FootprintBaseline` or `UserProfile` in plain `SharedPreferences` or `UserDefaults`
- Authentication tokens (OAuth access tokens, refresh tokens, session tokens): store ONLY in Android Keystore-backed EncryptedSharedPreferences or iOS Keychain — NEVER in plain SharedPreferences, UserDefaults, or Room without SQLCipher

## Network Security

- All HTTP clients must use certificate pinning:
  - Android (OkHttp): reference `CertificatePinner` — flag any `OkHttpClient.Builder()` without it
  - iOS (URLSession): reference `URLSessionDelegate` with pinning — flag any direct use of `URLSession.shared` or `OkHttpClient()` without a custom configuration — always use a preconfigured client with certificate pinning policy
- All API calls must be HTTPS — flag any `http://` URL literal

## Offline Fallback

- Carbon factor lookups must work offline using bundled constants from `domain.instructions.md`
- All core features (log habit, view footprint) must remain fully functional offline
- Network calls are for sync only, never for primary computation
