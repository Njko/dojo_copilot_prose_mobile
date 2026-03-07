# JUnit5 Setup — EcoTrack Android

> Reference document for DOJO.md Phase 4.
> Explains why JUnit5 requires manual configuration in Android projects,
> what was added, and how to run the tests.

---

## Pourquoi JUnit5 n'est pas disponible "par défaut" sur Android

Android Studio génère des projets préconfigurés avec **JUnit4** (`junit:junit:4.x`).
Le framework de tests JUnit5 (aussi appelé JUnit Jupiter) est une réécriture complète
qui n'est **pas incluse** dans le SDK Android et n'est **pas détectée automatiquement**
par le Gradle Android Plugin (AGP).

Deux obstacles techniques s'accumulent :

1. **Résolution du moteur de tests** — AGP délègue la découverte des tests à Gradle,
   qui doit savoir quel moteur utiliser. JUnit5 introduit la notion de "JUnit Platform"
   comme couche d'exécution. Sans `test.useJUnitPlatform()`, Gradle ignore les tests
   annotés `@org.junit.jupiter.api.Test`.

2. **Plugin de pont AGP ↔ JUnit Platform** — Le plugin officiel
   `de.mannodermaus.android-junit5` est nécessaire pour que le `testOptions` d'AGP
   soit compatible avec la JUnit Platform. Sans lui, l'option `useJUnitPlatform()`
   n'est pas reconnue dans le contexte d'un module `com.android.application`.

---

## Ce qui a été ajouté

### `app/build.gradle.kts` — bloc `plugins`

```kotlin
// JUnit5 support for Android unit tests (JVM layer — no emulator required)
id("de.mannodermaus.android-junit5") version "1.10.0.0"
```

Ce plugin agit comme un pont entre le Android Gradle Plugin et la JUnit Platform.
Il doit être déclaré **dans le module `app`**, pas dans le build racine.

---

### `app/build.gradle.kts` — bloc `android > testOptions`

```kotlin
testOptions {
    unitTests {
        isIncludeAndroidResources = true  // Required for Robolectric
        all { test ->
            // Enable JUnit Platform so Gradle discovers JUnit5 tests
            test.useJUnitPlatform()
        }
    }
}
```

`useJUnitPlatform()` indique à Gradle d'utiliser le moteur JUnit5 pour exécuter
les tests JVM (unit tests). Sans cette ligne, les tests `CarbonCalculatorTest`
ne sont pas exécutés — Gradle les ignore silencieusement.

---

### `app/build.gradle.kts` — bloc `dependencies`

```kotlin
// JUnit5 — required by CarbonCalculatorTest (Phase 4 PROSE Dojo)
testImplementation("org.junit.jupiter:junit-jupiter-api:5.10.1")
testRuntimeOnly("org.junit.jupiter:junit-jupiter-engine:5.10.1")

// AssertJ — fluent assertions (optionnel, enrichit la lisibilité)
testImplementation("org.assertj:assertj-core:3.24.2")
```

| Artifact | Role |
|---|---|
| `junit-jupiter-api` | Fournit `@Test`, `@DisplayName`, `assertThrows`, `assertDoesNotThrow` etc. — les annotations et assertions utilisées dans le code de test |
| `junit-jupiter-engine` | Moteur d'exécution JUnit5 chargé au `runtimeOnly` — nécessaire pour que la JUnit Platform puisse lancer les tests |
| `assertj-core` | Bibliothèque d'assertions fluentes (`assertThat(x).isEqualTo(y)`) — plus lisible que les assertions standard JUnit |

> **Note :** Les dépendances JUnit4 (`libs.junit`, Robolectric) sont conservées
> car `HabitTest.kt` et `LogHabitCompletionUseCaseTest.kt` utilisent
> `org.junit.Assert` et `@RunWith(RobolectricTestRunner::class)`.
> JUnit4 et JUnit5 coexistent dans le même module.

---

### Fichiers créés (infrastructure Gradle manquante)

Ces fichiers étaient absents et empêchaient tout build :

| Fichier | Rôle |
|---|---|
| `settings.gradle.kts` | Déclare le nom du projet et le module `:app` ; configure les dépôts de plugins (dont celui de `mannodermaus`) |
| `build.gradle.kts` (racine) | Build file racine — déclare les plugins sans les appliquer (`apply false`) |
| `gradle/libs.versions.toml` | Version catalog — résout tous les `alias(libs.*)` utilisés dans `app/build.gradle.kts` |
| `gradle/wrapper/gradle-wrapper.properties` | Déclare la version de Gradle utilisée par `./gradlew` (8.6) |

---

## Lancer les tests

### Depuis Android Studio

1. Ouvrir `app/src/test/kotlin/com/ecotrack/domain/CarbonCalculatorTest.kt`
2. Cliquer sur l'icône verte dans la gouttière à côté de la classe ou d'un test individuel
3. Ou utiliser le raccourci : **`Ctrl+Shift+F10`** (Windows/Linux) / **`Ctrl+Shift+R`** (macOS)
4. Ou via le menu : **Run → Run 'CarbonCalculatorTest'**

Android Studio affiche les résultats dans le panneau **Run** avec l'arborescence
des suites et des scénarios (`@DisplayName` visible).

### Depuis la ligne de commande

Depuis le dossier racine du projet (`ecotrack-android/`) :

```bash
# Lancer tous les unit tests (JUnit4 + JUnit5)
./gradlew test

# Lancer uniquement les tests du module app
./gradlew :app:test

# Lancer uniquement la suite CarbonCalculatorTest
./gradlew :app:test --tests "com.ecotrack.domain.CarbonCalculatorTest"
```

> Sur Windows : remplacer `./gradlew` par `gradlew.bat`

---

## Lire les résultats

### Rapport HTML

Après l'exécution, Gradle génère un rapport interactif :

```
app/build/reports/tests/test/index.html
```

Ouvrir ce fichier dans un navigateur pour voir :
- Le nombre de tests passés / échoués / ignorés
- La durée d'exécution de chaque test
- Le détail des erreurs avec stack trace
- L'affichage des `@DisplayName` (scénarios BDD)

### Sortie console

La sortie console indique le résultat en temps réel :

```
> Task :app:test
com.ecotrack.domain.CarbonCalculatorTest > User logs a cycling commute PASSED
com.ecotrack.domain.CarbonCalculatorTest > Zero-delta action does not cause division by zero PASSED
com.ecotrack.domain.CarbonCalculatorTest > Long-haul flight avoided is calculated correctly PASSED
com.ecotrack.domain.CarbonCalculatorTest > Carbon calculation works offline PASSED
com.ecotrack.domain.CarbonCalculatorTest > CarbonDelta is always finite PASSED
com.ecotrack.domain.CarbonCalculatorTest > FootprintBaseline must be positive PASSED

BUILD SUCCESSFUL in Xs
```

Si un test échoue, la console affiche directement le message d'erreur et la
ligne concernée. Le rapport HTML offre un détail complet avec stack traces.

---

## Dépannage

| Symptôme | Cause probable | Solution |
|---|---|---|
| `No tests found for given includes` | `useJUnitPlatform()` absent | Vérifier le bloc `testOptions` dans `app/build.gradle.kts` |
| `Could not resolve org.junit.jupiter:junit-jupiter-api` | Dépôt Maven Central absent | Vérifier `settings.gradle.kts > dependencyResolutionManagement > repositories` |
| `Plugin [id: 'de.mannodermaus.android-junit5'] was not found` | Dépôt Gradle Plugin Portal absent | Vérifier `settings.gradle.kts > pluginManagement > repositories` |
| Tests JUnit4 ne passent plus | Conflit JUnit4 / JUnit5 | Les deux moteurs doivent coexister ; ne pas supprimer `libs.junit` |
| `BUILD FAILED` à la compilation | Version catalog manquante | S'assurer que `gradle/libs.versions.toml` est présent |
