# Lancer les tests iOS dans VS Code

Ce guide explique comment exécuter les tests Swift du projet EcoTrack depuis VS Code, sans avoir besoin d'Xcode.

---

## Prérequis

Swift doit être installé sur votre machine. Vérifiez avec :

```bash
swift --version
```

Vous devriez obtenir une sortie comme :

```
swift-driver version: 1.90.11 Apple Swift version 5.10 (swiftlang-5.10.0.13 clang-1500.3.9.4)
```

Si la commande n'est pas reconnue :
- **macOS** : installez Xcode via l'App Store ou les Command Line Tools (`xcode-select --install`)
- **Linux** : suivez les instructions sur [swift.org/install](https://www.swift.org/install/linux/)

---

## Lancer tous les tests

Depuis le dossier `ecotrack-ios/` :

```bash
cd ecotrack-ios
swift test
```

SPM compile automatiquement les cibles `EcoTrack` et `EcoTrackTests`, puis exécute tous les tests.

### Lire la sortie

Chaque test affiché comme suit :

```
Test Suite 'CarbonCalculatorTests' started
Test Case 'CarbonCalculatorTests.test_cyclingCommute_producesCorrectCarbonDelta' passed (0.001 seconds)
Test Case 'CarbonCalculatorTests.test_zeroDelta_doesNotCauseDivisionByZero' passed (0.000 seconds)
...
Test Suite 'CarbonCalculatorTests' passed at 2026-03-06 10:00:00.000
     Executed 7 test cases, with 0 failures (0 unexpected) in 0.012 (0.014) seconds
```

- `passed` : le test est vert
- `failed` : le test est rouge — la description de l'échec s'affiche juste en dessous

---

## Lancer un seul fichier de tests

Pour cibler uniquement les tests liés à `CarbonCalculator` :

```bash
swift test --filter CarbonCalculatorTests
```

Pour cibler un test précis par son nom de méthode :

```bash
swift test --filter CarbonCalculatorTests/test_cyclingCommute_producesCorrectCarbonDelta
```

---

## Alternative VS Code : extension Swift officielle

Apple publie une extension VS Code qui intègre l'exécution des tests directement dans l'interface.

**Installation :**

1. Ouvrez la palette de commandes : `Cmd+Shift+P` (macOS) ou `Ctrl+Shift+P` (Linux/Windows)
2. Tapez `Extensions: Install Extensions`
3. Recherchez `Swift` et installez l'extension dont l'ID est **`sswg.swift-lang`**

**Lancer les tests depuis VS Code :**

1. Ouvrez la palette de commandes : `Cmd+Shift+P`
2. Tapez `Swift: Run Tests`
3. Les résultats apparaissent dans le panneau **Testing** (icone eprouvette dans la barre latérale)

---

## Note importante : raccourcis clavier

| Raccourci | Environnement | Action |
|-----------|--------------|--------|
| `Cmd+U` | **Xcode uniquement** | Lancer tous les tests |
| `Cmd+Shift+P` → `Swift: Run Tests` | VS Code + extension `sswg.swift-lang` | Lancer tous les tests |
| `swift test` | Terminal | Lancer tous les tests |

`Cmd+U` est le raccourci Xcode. Il **n'est pas disponible dans VS Code** sans l'extension Swift installée et configurée.

---

## Dépannage rapide

| Problème | Solution |
|---------|---------|
| `error: no targets found at 'Sources'` | Vérifiez que vous êtes bien dans `ecotrack-ios/` et que `Package.swift` existe |
| `error: cannot find module 'XCTest'` | Normal sur certaines installations Linux ; installez le SDK complet Swift |
| `build error: cannot find 'SwiftUI'` | Normal : les fichiers Presentation sont exclus du package SPM par design |
| Tests non trouvés avec `--filter` | Utilisez le nom exact de la classe ou de la méthode (sensible à la casse) |
