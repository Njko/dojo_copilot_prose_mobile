---
applyTo: "src/**/domain/**,**/domain/**,**/*Domain*.kt,**/*Calculator*.kt,**/*Calculator*.swift,**/Sources/EcoTrack/Domain/**/*.swift,**/Tests/EcoTrackTests/Domain/**/*.swift"
---

# EcoTrack Domain Layer Instructions

These rules apply when Copilot is working inside the domain layer.
They refine and extend the global instructions in `copilot-instructions.md`.

## Ubiquitous Language (enforce strictly)

| Term | Type | Definition |
|---|---|---|
| `Habit` | Entity | A user-defined recurring eco behaviour; has an ID and category |
| `EcoAction` | Value Object | One occurrence of a Habit; immutable; identified by content, not identity |
| `HabitCategory` | Sealed type (Android) / enum (iOS) | Android : `TRANSPORT`, `FOOD`, `ENERGY`, `WATER`, `WASTE`, `SHOPPING` — iOS : `.transport`, `.food`, `.energy`, `.water`, `.waste`, `.consumption` |
| `CarbonDelta` | Value Object | Wraps a `Double` (kgCO2e); negative means saving; never null |
| `FootprintBaseline` | Value Object | Annual CO2e in tCO2e; always positive; default 8.5 for EU average |
| `UserProfile` | Aggregate Root | Owns a list of Habits and one FootprintBaseline |

### Types de valeur CO₂ — distinction critique

| Type | Sémantique | Plage | Exemple |
|------|-----------|-------|---------|
| `CarbonDelta` | Variation relative (économie ou émission) | (−∞, +∞) | Cyclisme = −1.8 kg |
| `CarbonFootprint` | Accumulation absolue (total économisé) | [0, +∞) | Habitude a économisé 27 kg |

**Règle :** `CarbonDelta` peut être négatif (saving). `CarbonFootprint` est toujours ≥ 0.
Ne pas intervertir ces types — ils ne sont pas substituables.

> **Note :** `HabitCategory` est la source de vérité pour la catégorie d'un habit ou d'une action sur les deux plateformes.
> Ne pas créer d'enum alternatif. Ne pas utiliser de chaînes brutes.

## Domain Invariants (never violate)

1. `CarbonDelta` is always finite — no `NaN`, no `Infinity`
2. Dividing by `FootprintBaseline` must guard against zero baseline
3. An `EcoAction` cannot have a null or blank `name`
4. `HabitCategory` must be a sealed/enum type — no raw strings in the domain
5. `Habit` identity is a UUID — never an auto-increment integer

## Style Rules

- All public domain types must have KDoc (Kotlin) or DocC (Swift) comments
- No `lateinit var` in domain classes (Kotlin); no `var` in domain structs (Swift)
- Domain functions return `Result<T>` / `throws` — never return null for errors
- No `@Inject` or DI annotations in the domain layer — domain is framework-free
- No `import android.*` or `import UIKit` in domain files

## Carbon Emission Factors (source: ADEME 2024)

Use these constants. Do not hardcode elsewhere.

```
Transport:
  cycling       = 0.000 kgCO2e/km
  walking       = 0.000 kgCO2e/km
  electric_bike = 0.002 kgCO2e/km
  bus           = 0.040 kgCO2e/km
  train         = 0.030 kgCO2e/km
  car_petrol    = 0.150 kgCO2e/km
  car_electric  = 0.050 kgCO2e/km
  flight_short  = 0.255 kgCO2e/km (per passenger)

Food (per meal):
  vegan         = 0.500 kgCO2e
  vegetarian    = 0.700 kgCO2e
  meat          = 2.500 kgCO2e
  fish          = 1.200 kgCO2e
```
