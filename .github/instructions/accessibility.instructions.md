---
applyTo: "**/*.kt,**/*.swift,**/*.xml"
---

# EcoTrack Accessibility Instructions (WCAG 2.2 AA)

These rules apply to all UI files.
Flag violations with `// A11Y: <reason>` before the offending element.

## Semantic Labels — Required on All Interactive Elements

**Android (Compose):**
```kotlin
// Required:
Icon(
    imageVector = Icons.Default.Leaf,
    contentDescription = "Eco habit recorded" // never null for meaningful icons
)
Button(
    onClick = { logHabit() },
    modifier = Modifier.semantics { contentDescription = "Log cycling habit" }
)
// Forbidden:
Icon(imageVector = Icons.Default.Leaf, contentDescription = null) // A11Y: decorative only if purely decorative
```

**iOS (SwiftUI):**
```swift
// Required:
Image(systemName: "leaf.fill")
    .accessibilityLabel("Eco habit recorded")
Button("Log Habit") { logHabit() }
    .accessibilityHint("Double-tap to record your cycling habit")
// Forbidden:
Image(systemName: "leaf.fill") // A11Y: missing accessibilityLabel
```

## Touch Targets

- Minimum 44×44dp (Android) / 44×44pt (iOS) for all tappable elements
- Use `Modifier.minimumInteractiveComponentSize()` (Compose) or `.frame(minWidth: 44, minHeight: 44)` (SwiftUI)

## Color Must Not Be the Sole Indicator

CarbonDelta display rules:
- Saving (negative delta): green color + leaf icon + "Saving X kg" text label
- Neutral (zero delta): grey color + dash icon + "No change" text label
- Emitting (positive delta): red color + warning icon + "Emitting X kg" text label

Never use color alone — the icon and text label are mandatory.

## Dynamic Type / Scalable Fonts

**Android:** all text sizes in `sp`, never `dp` or `px` for fonts
```kotlin
Text(text = habitName, style = MaterialTheme.typography.bodyLarge) // OK
Text(text = habitName, fontSize = 16.dp) // A11Y: use sp not dp for font sizes
```

**iOS:** all text styles use Dynamic Type
```swift
Text(habitName).font(.body) // OK
Text(habitName).font(.system(size: 16)) // A11Y: hardcoded size ignores user preference
```

## Focus Order

- Focus order must match visual reading order (top-to-bottom, left-to-right for LTR)
- Custom `focusOrder` (Compose) or `accessibilitySortPriority` (iOS) must be documented with a comment explaining the deviation
- Modal sheets and dialogs must trap focus — no keyboard/switch navigation escape

## Screen Reader Announcements

- Habit completion must trigger a live region announcement
- CarbonDelta calculation result must be announced after update
- Loading states must announce "Loading habits" and "Habits loaded" to avoid silence

**Android:**
```kotlin
Modifier.semantics { liveRegion = LiveRegionMode.Polite }
```

**iOS:**
```swift
.accessibilityAddTraits(.updatesFrequently)
UIAccessibility.post(notification: .announcement, argument: "Carbon saving updated")
```
