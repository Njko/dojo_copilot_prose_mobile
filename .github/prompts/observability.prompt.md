---
mode: "chat"
description: "Generate OpenTelemetry instrumentation for the EcoTrack carbon calculation pipeline"
---

# Observability Instrumentation Generator

## Context

Apply domain rules from [domain.instructions.md](../instructions/domain.instructions.md).
Apply security rules from [security.instructions.md](../instructions/security.instructions.md).
Domain model reference: [ecotrack-domain.spec.md](../../ecotrack-domain.spec.md).

## Task

Generate OpenTelemetry span instrumentation for the EcoTrack habit logging pipeline.

### Pipeline to instrument

```
User taps "Log Habit"
  └─ span: habit.log.start
      └─ span: carbon.calculate
          └─ span: emission_factor.lookup (local)
      └─ span: habit.persist
      └─ span: footprint.update
  └─ span: habit.log.complete
```

## Span Attribute Rules

### Allowed span attributes (aggregates and categories only)

```
habit.category = "transport" | "food" | "energy" | "consumption" | "waste"
carbon.delta.kgco2e = <float>   # the calculated value — OK, not PII
calculation.source = "local" | "remote"
habit.count.total = <int>        # aggregate count — OK
platform = "android" | "ios"
app.version = <string>
```

### Forbidden span attributes — SECURITY: PII

```
# NEVER add these to any span:
habit.name          # PII: describes user behaviour
habit.description   # PII
user.id             # PII
user.email          # PII
device.location     # PII
eco_action.details  # PII
```

## Output Requirements

1. Generate a `HabitTracingService` / `HabitTracingService.swift` in `src/domain/observability/`
2. Use OpenTelemetry SDK for the target platform:
   - Android: `io.opentelemetry.android`
   - iOS: `opentelemetry-swift`
3. Each span must:
   - Have a meaningful name (verb.noun format)
   - Record duration
   - Set `ok` or `error` status
   - On error: include error type but NOT the habit data
4. The service is injected — do not create a singleton with global state
5. Include a test that asserts PII attributes are absent from generated spans

## Privacy Test Template

```kotlin
@Test
fun `spans must not contain PII attributes`() {
    val spans = capturedSpans()
    val forbiddenKeys = listOf("habit.name", "user.id", "user.email", "habit.description")
    spans.forEach { span ->
        forbiddenKeys.forEach { key ->
            assertThat(span.attributes.asMap()).doesNotContainKey(AttributeKey.stringKey(key))
        }
    }
}
```
