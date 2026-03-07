# Réévaluation du Dojo EcoTrack PROSE — Retours de 4 Profils

**Date :** 07/03/2026
**Méthode :** 4 agents simulant des profils juniors réels ont réalisé les exercices du Dojo en moins d'une heure, en documentant leurs freins, apprentissages et ressentis à chaque phase.

---

## Profils évalués

| Profil | Plateforme | Expérience |
|--------|-----------|-----------|
| **Stagiaire Android** | Android/Kotlin | Hello World sur Android Studio, jamais de tests, jamais Copilot |
| **Stagiaire iOS** | iOS/Swift | A ouvert Xcode, joué avec l'IDE, aucun code réel |
| **Alternant Android** | Android/Kotlin | Todo list perso, MVVM basique, jamais de tests ni Clean Architecture |
| **Alternant iOS** | iOS/Swift | Architecture UIKit/ViewController archaïque, quelques tests XCTest basiques |

---

## Synthèse par Phase

### Phase 0 — Kickoff (0:00–5:00)

**Ressenti général : Facile ✅**

Tous les profils ont bien saisi la démo. La visualisation "avec vs sans instructions" est efficace.

**Freins communs :**
- Le dossier `.github/` est mystérieux : visible comment ? Créé comment ? Le stagiaire iOS a perdu 2 minutes à cause des fichiers cachés sur Mac (nécessite `Cmd+Shift+.` dans Finder).
- L'acronyme **PROSE** est mentionné mais jamais expliqué formellement. Les 4 profils terminent la phase sans savoir ce que P-R-O-S-E signifie.
- Les termes "terme de domaine", "CarbonDelta" → OK intuitivement, mais "domaine" comme concept DDD reste flou.

**Recommandation :** Ajouter 1 slide (30 secondes) explicitant l'acronyme PROSE avant la démo. Mentionner que `.github/` est un dossier système créé automatiquement ou à créer manuellement.

---

### Phase 1A — Instructions globales (5:00–10:00)

**Ressenti général : Moyen ⚠️**

**Ce qui fonctionne :** La mécanique de création du fichier `.md` est accessible. Demander à Copilot de générer ses propres instructions est perçu comme "méta mais logique".

**Freins majeurs — terminologie surchargée :**

| Terme | Profils bloqués | Raison |
|-------|----------------|--------|
| `TDD-first` | Stagiaires (×2) | TDD = concept jamais pratiqué |
| `Sendable` (Swift) | Alternant iOS, Stagiaire iOS | Swift 6 concurrence, jamais vu |
| `WCAG 2.2 AA` | Tous | Norme inconnue, pas intuitive |
| `PII` | Stagiaires (×2) | Acronyme inconnu (= données personnelles) |
| `modèles immutables` | Stagiaires (×2) | Concept fonctionnel non formalisé |
| `fonctions pures` | Stagiaires (×2) | Programmation fonctionnelle non abordée |
| `Hilt` (Android) | Alternant Android | Jamais utilisé (manual DI seulement) |
| `SQLCipher` (Android) | Tous Android | Jamais vu |
| `@Observable` (iOS) | Tous iOS | iOS 17+ uniquement, nouveau |
| `BGAppRefreshTask` (iOS) | Tous iOS | Jamais implémenté |

**Tension identifiée :** On demande aux participants de créer des instructions sur des technologies qu'ils ne maîtrisent pas. Si les instructions sont incorrectes, ils ne peuvent pas le détecter. Sentiment de "faire semblant".

**Recommandation :** Distribuer en amont un **glossaire d'une page** (PII, WCAG, TDD, BDD, DDD, Gherkin, Sendable, immutable, fonctions pures). Ne pas supposer que ces termes sont connus.

---

### Phase 1B — Instructions domaine (10:00–15:00)

**Ressenti général : Difficile ❌ (conceptuellement)**

**Freins majeurs :**

1. **Le frontmatter YAML (`---`)** : tous les profils juniors sont déstabilisés. Ce n'est pas du Markdown standard qu'ils connaissent. Le stagiaire iOS a dû chercher "frontmatter markdown" sur Google.

2. **Le glob pattern `applyTo`** : `src/**/domain/**` — la syntaxe `**` est inconnue. Les profils devinent que ça veut dire "n'importe quel sous-dossier" mais sans certitude.

3. **Le concept "domain pur sans imports Android/UIKit"** : c'est la révélation architecturale la plus déroutante. L'alternant Android résume bien : *"Dans ma todo list, mon Repository importe `androidx.room.*`. L'idée qu'un domaine puisse tourner sans Android, c'est totalement étranger."*

4. **`Result<T>` vs exceptions** : les 4 profils utilisent soit `try/catch` soit des optionals. `Result<T>` est un pattern inconnu pour tous sauf l'alternant iOS (et encore, il l'a vu sans l'utiliser).

5. **"7 invariants de domaine"** : le terme "invariant" au sens DDD n'est pas familier. Le sens mathématique aide à deviner, mais pas à formuler.

6. **Facteurs d'émission ADEME 2024** : les profils ne savent pas où les trouver, ni si Copilot peut les inventer de façon fiable.

**Moment positif :** Tous les profils trouvent le concept de "langage ubiquitaire" intuitif et utile une fois expliqué.

**Recommandation :**
- Ajouter 2 minutes de présentation sur la **Clean Architecture** (couches Domain / Data / Presentation) avant la Phase 1B.
- Expliquer le frontmatter YAML avec un exemple visuel simple.
- Fournir les facteurs ADEME pré-remplis dans l'énoncé (ils sont déjà dans le repo, les rendre visibles).

---

### Phase 2 — Reduced Scope / Spec (15:00–23:00)

**Ressenti général : Moyen ⚠️**

**Ce qui fonctionne bien :**
- Le format Given/When/Then est intuitivement compris par tous. L'alternant iOS note l'équivalence avec Arrange/Act/Assert qu'il utilisait déjà.
- La section "Out of Scope" est appréciée unanimement : l'idée d'expliciter ce qu'on ne fait **pas** est perçue comme une bonne pratique immédiatement adoptable.
- Le calcul des kgCO2e (vélo 12km → -1.8 kgCO2e) est vérifié manuellement par les alternants et jugé correct.

**Freins :**
- Le terme **"Reduced Scope"** (et plus généralement PROSE) reste inexpliqué formellement à ce stade. Les profils comprennent empiriquement mais pas conceptuellement.
- **Ambiguïté critique** détectée par l'alternant Android : dans la section "Out of Scope : BDD", est-ce "Base De Données" ou "Behavior-Driven Development" ? → À clarifier dans le texte.
- La mesure de la **couverture à 80%** : personne ne sait comment la configurer (ni dans Android Studio ni dans Xcode).
- La contrainte **~150 lignes** est stressante quand on découvre le format en même temps.

**Recommandation :** Renommer "BDD" en "Base De Données (stockage persistant)" dans la section Out of Scope pour lever l'ambiguïté. Ajouter une note sur l'outil de couverture de chaque plateforme (JaCoCo/Kover pour Android, Xcode Coverage pour iOS).

---

### Phase 3A — BDD Prompt (23:00–28:00)

**Ressenti général : Moyen ⚠️**

**Ce qui fonctionne :** L'idée de prompt réutilisable avec des variables `{{HABIT_CATEGORY}}` est comprise par tous après explication. L'analogie avec les templates de mail ou les snippets est efficace.

**Freins majeurs :**

1. **Références croisées temporelles** : le prompt référence `security.instructions.md` et `accessibility.instructions.md` qui n'existent pas encore (créés en Phase 5). Tous les profils notent cette incohérence. L'alternant Android : *"Je dois référencer des fichiers pas encore créés. C'est comme écrire une table des matières d'un livre qu'on n'a pas encore écrit."*

2. **Syntaxe d'exécution** : comment "exécuter" un `.prompt.md` ? Copilot Chat ? Un bouton ? Une commande ? Les stagiaires sont perdus.

3. **Les 6 types de scénarios requis** sont listés sans détail dans certaines versions du brief. Les profils font des choix arbitraires.

**Recommandation :**
- Soit créer les fichiers de sécurité/accessibilité en amont (Phase 1C avant Phase 3A), soit ajouter une note "ces fichiers seront créés en Phase 5, ajoutez les références maintenant pour anticiper".
- Ajouter une capture d'écran ou une étape explicite sur comment exécuter un `.prompt.md` dans Copilot Chat.

---

### Phase 3B — Génération BDD live (28:00–33:00)

**Ressenti général : Facile ✅ — moment "aha!" unanime**

C'est la phase la plus satisfaisante pour tous les profils. Voir Copilot générer des scénarios qui utilisent `CarbonDelta`, `FootprintBaseline`, `EcoAction` — les termes qu'ils ont eux-mêmes définis en Phase 1A — est perçu comme la **première preuve concrète** que PROSE fonctionne.

**Freins mineurs :**
- Gherkin : le terme n'était pas connu avant la phase. Le lien avec Cucumber est découvert à la volée.
- La sortie est souvent en anglais même si la spec était partiellement en français.
- Copilot peut générer des références à des couches hors scope (ex : mock SwiftData alors qu'on l'avait exclu). Les instructions ne sont pas déterministes.

**Recommandation :** Capitaliser sur ce moment "aha!" — c'est le meilleur argument pour PROSE. Envisager de le déplacer plus tôt dans le Dojo pour maintenir la motivation pendant les phases difficiles.

---

### Phase 4A — TDD Prompt (33:00–37:00)

**Ressenti général : Difficile pour les stagiaires, Facile pour les alternants ❌/✅**

**Ce qui fonctionne pour l'alternant iOS :** Il est dans sa zone de confort. Il comprend immédiatement, améliore la convention de nommage (`test_given_when_then`), pose zéro question.

**Ce qui bloque les stagiaires :**
- Le concept de **"tests qui ÉCHOUENT intentionnellement"** est profondément contre-intuitif pour quelqu'un qui n'a jamais fait de tests. La phrase *"pourquoi écrire des tests qui échouent ?"* revient chez les deux stagiaires.
- **JUnit5 vs JUnit4** (Android) : même l'alternant Android ne fait pas la distinction. La configuration Gradle nécessaire pour JUnit5 sur Android est un mur technique.
- **AssertJ** : `assertThat(delta.kgCO2e).isCloseTo(-1.8, within(0.01))` — tous les profils Android identifient que ce n'est pas du JUnit natif mais ne savent pas quelle lib c'est.

**Recommandation :** Ajouter une explication de **30 secondes** sur le cycle Red-Green-Refactor avant cette phase, avec un schéma visuel. Référencer explicitement AssertJ dans le brief Android.

---

### Phase 4B/C — Tests rouges → verts (37:00–45:00)

**Ressenti général : Difficile ❌ — pic de complexité du Dojo**

C'est la phase avec le plus de blocages. Le "pic de difficulté" est unanimement identifié ici.

**Freins Android :**
- **Configuration Gradle JUnit5** : le plugin `de.mannodermaus.android-junit5` + `useJUnitPlatform()` + dépendances AssertJ → les profils perdent 5-10 minutes sur la configuration.
- La distinction entre `./gradlew test` (tests JVM locaux) et `./gradlew connectedAndroidTest` (tests instrumentés sur émulateur) n'est pas connue.
- Les **sealed classes imbriquées** (`ActionCategory.Transport.Cycling`) — l'alternant Android en connaît des simples, pas des imbriquées.
- `@JvmInline value class` : inconnu des deux profils Android.

**Freins iOS :**
- **Swift Package Manager vs projet Xcode** : les deux profils iOS ont créé des projets `.xcodeproj` et ne savent pas comment lancer `swift test`. L'alternant iOS perd 2-3 minutes sur le `Package.swift`.
- **Erreurs de précision flottante** : `0.5400000000000001` vs `0.54` → bloquant si on ne connaît pas `accuracy:` dans XCTAssertEqual.
- `enum CarbonCalculator` comme namespace : idiome inconnu des deux profils iOS.

**Points positifs :**
- Voir les tests passer au vert est le **moment de satisfaction maximale** du Dojo pour tous les profils.
- L'alternant iOS applique les erreurs typées `enum DomainError` et voit immédiatement l'avantage sur `NSError`.

**Recommandation :**
- **Android** : créer un template `build.gradle.kts` pré-configuré pour JUnit5 + AssertJ, ou pointer vers `ecotrack-android/docs/junit5-setup.md` explicitement dans le brief de Phase 4.
- **iOS** : créer un template `Package.swift` pré-configuré, ou pointer vers `ecotrack-ios/docs/run-tests-vscode.md`. Mentionner le cas de précision flottante et la solution `accuracy:`.
- Prévoir un **timing cushion de 5 minutes** sur cette phase (actuellement 12 min, souvent 17-20 min en réalité).

---

### Phase 5 — Safety Boundaries (45:00–53:00)

**Ressenti général : Facile mécaniquement, Formateur intellectuellement ✅**

**Ce qui fonctionne :** La mécanique est maintenant familière (créer un `.md` avec frontmatter). Les concepts sont plus intuitifs que ceux des phases DDD.

**Ce qui surprend (positivement) :**
- L'alternant iOS découvre que son `Timer` de polling toutes les 30 secondes est une mauvaise pratique → à corriger.
- L'alternant iOS réalise que ses tokens dans `UserDefaults` sont non chiffrés → `Keychain` à adopter.
- L'alternant Android réalise qu'il a probablement des `Log.d("MainActivity", "User: $user")` avec des données personnelles.
- La cohérence des patterns `// SECURITY:`, `// A11Y:`, `// ECO:` est unanimement appréciée.

**Freins :**
- Tous créent des règles pour des technologies qu'ils ne maîtrisent pas (Keystore, certificate pinning, BGAppRefreshTask). Ils ne pourraient pas vérifier si Copilot les applique correctement.
- `applyTo: "**/*.kt, **/*.swift"` mélange Android et iOS sur le fichier security — non intuitif dans un Dojo mono-plateforme.

**Recommandation :** Faire de cette phase une **révélation guidée** plutôt qu'une création mécanique. Poser la question *"Qui a un `Timer` de polling ?"* ou *"Qui met des tokens dans UserDefaults ?"* avant de créer les fichiers — les participants se reconnaîtront et l'exercice aura plus d'impact.

---

### Phase 6 — Rétrospective (53:00–60:00)

**Ressenti général : Satisfaisant ✅**

Tous les profils arrivent à la rétro avec des choses à dire. Les moments "je rentre avec une liste à corriger" sont fréquents.

**Ce qui manque :** PROSE n'a toujours pas été expliqué formellement. Les participants comprennent empiriquement ce qu'ils ont fait, mais ne pourraient pas définir P-R-O-S-E à un collègue.

---

## Analyse transversale

### Courbe de difficulté perçue

```
Difficulté
    │
10  │                    ████
 9  │                    ████ ████
 8  │               ████ ████ ████
 7  │          ████ ████ ████ ████
 6  │ ████     ████ ████ ████ ████
 5  │ ████ ████████ ████ ████ ████ ████ ████
 4  │ ████ ████████ ████ ████ ████ ████ ████ ████
    └──────────────────────────────────────────────
       P0   P1A  P1B  P2   P3A  P3B  P4A 4B/C  P5   P6
                                (pic ici ↑)
```

Le pic se situe clairement en **Phase 4B/C** pour tous les profils, dû à la combinaison : configuration outillage + concepts DDD + TDD pour la première fois.

### Freins universels (tous profils)

1. **PROSE non expliqué** : l'acronyme n'est jamais formellement décomposé
2. **Glossaire absent** : PII, WCAG, TDD, BDD, DDD, Gherkin, invariant, value object, ubiquitaire → inconnus ou flous
3. **Références croisées temporelles** : Phase 3A référence des fichiers créés en Phase 5
4. **Outillage de tests** : configuration JUnit5 (Android) et SPM/`swift test` (iOS) → pic de blocage
5. **Validation impossible** : les profils créent des fichiers sur des domaines qu'ils ne maîtrisent pas (sécurité, accessibilité avancée) sans pouvoir valider la qualité du contenu

### Freins par niveau

**Stagiaires (Hello World uniquement) :**
- Jargon technique dense dans les 15 premières minutes
- Absence de référence architecturale (pas de notion de "couches")
- Le TDD contre-intuitif ("tests qui échouent exprès")
- Densité conceptuelle trop élevée pour 60 minutes

**Alternants (projet perso) :**
- Concepts DDD inconnus mais assimilables rapidement
- Configuration outillage (Gradle JUnit5 / SPM) = blocage temporel
- Valider la qualité du code généré par Copilot dans les zones non maîtrisées

### Points unanimement appréciés

1. **Phase 3B (génération live)** : le moment "ça marche vraiment"
2. **Tests verts** en Phase 4C : satisfaction maximale
3. **Patterns commentaires** (`// SECURITY:`, `// A11Y:`, `// ECO:`) : simple, mémorisable, adoptable immédiatement
4. **Section "Out of Scope"** dans la spec : bonne pratique transposable
5. **Langage ubiquitaire** : l'idée est perçue comme utile bien au-delà du Dojo

---

## Recommandations Prioritaires

### P0 — Avant de commencer (5 min supplémentaires)

**Action :** Ajouter une slide de présentation formelle :
- Décomposer **P-R-O-S-E** avec une phrase par lettre
- Distribuer un **glossaire** : PII, WCAG, TDD, BDD, DDD, Gherkin, invariant, value object
- Montrer la **structure en couches** (Domain / Data / UI) en 3 boîtes

**Impact :** Réduit d'environ 70% le temps perdu à chercher des définitions.

### P1 — Réordonnancer les phases (neutre en temps)

**Action :** Créer les fichiers `security.instructions.md` et `accessibility.instructions.md` **en Phase 1C** (avant la Phase 3A), ou au moins ajouter une note dans Phase 3A : *"Ces fichiers seront créés en Phase 5, ajoutez dès maintenant les références pour anticiper l'architecture."*

**Impact :** Élimine la confusion sur les références croisées.

### P2 — Template Gradle/SPM pré-configuré

**Android :** Pointer explicitement vers `ecotrack-android/docs/junit5-setup.md` en Phase 4A. Ou fournir un `build.gradle.kts` avec JUnit5 + AssertJ déjà configurés.

**iOS :** Pointer vers `ecotrack-ios/docs/run-tests-vscode.md` en Phase 4B. Mentionner le cas de précision flottante et `accuracy:`.

**Impact :** Récupère 5-10 minutes sur la Phase 4B/C.

### P3 — Timing réaliste pour les profils juniors

Le timing de 60 minutes est **tenu par les alternants** avec une expérience préalable, mais **dépassé de 15-20 minutes par les stagiaires**.

**Proposition :**
- Dojo standard (60 min) : pour des alternants ayant des bases en tests et architecture
- Dojo découverte (90 min) : pour des profils débutants, avec les 30 min supplémentaires dédiées aux prérequis (glossaire, Clean Architecture, TDD intro)
- Ou : couper Phase 5C (éco-conception) pour les stagiaires → économie de 5 min

### P4 — Validation par le facilitateur

Prévoir des **points de contrôle actifs** à la fin des Phases 1B et 2 :
- *"Montrez-moi votre `applyTo`. Est-ce que le pattern correspond à vos dossiers ?"*
- *"Lisez votre Out of Scope à voix haute. Est-ce qu'il manque quelque chose ?"*

Ces 30 secondes de feedback évitent que les participants avancent sur une base incorrecte.

### P5 — Révélation active en Phase 5

Remplacer la création mécanique de fichiers de sécurité par une **séquence de questions** :
1. *"Qui log des données utilisateur avec `Log.d` / `print()` ?"*
2. *"Qui stocke des tokens dans SharedPreferences / UserDefaults ?"*
3. *"Qui a un Timer qui tourne toutes les X secondes ?"*

Puis créer les fichiers comme "antidotes" aux mauvaises pratiques identifiées. L'impact émotionnel est bien plus fort.

---

## Tableau de synthèse par profil

| Phase | Stagiaire Android | Stagiaire iOS | Alternant Android | Alternant iOS |
|-------|:-----------------:|:-------------:|:-----------------:|:-------------:|
| P0 Kickoff | Moyen | Facile | Facile | Facile |
| P1A Global instructions | Difficile | Moyen | Moyen | Moyen |
| P1B Domain instructions | Difficile/Bloquant | Moyen-Difficile | Difficile | Difficile |
| P2 Spec | Moyen | Moyen | Moyen-Difficile | Modéré |
| P3A BDD Prompt | Moyen-Difficile | Moyen | Moyen | Élevé |
| P3B BDD live | Facile ✨ | Facile ✨ | Facile/Moyen ✨ | Modéré ✨ |
| P4A TDD Prompt | Difficile | Moyen | Difficile | Facile ✨ |
| P4B/C Red→Green | Difficile | **DIFFICILE** ❌ | Difficile | Modéré |
| P5 Safety | Moyen | Facile | Moyen | Formateur |
| P6 Rétro | Positif | Positif | Positif | Positif |
| **Dépassement timing** | **~20 min** | **~18 min** | **~15 min** | **~5 min** |

---

## Conclusion

Le Dojo EcoTrack PROSE est **pédagogiquement ambitieux et cohérent**. Sa structure progressive et ses artefacts concrets (fichiers d'instructions, prompts réutilisables, tests TDD) sont bien conçus. La valeur pédagogique est unanimement reconnue par tous les profils.

Les deux ajustements les plus impactants seraient :

1. **Un préambule de 5 minutes** avec le glossaire et la décomposition de PROSE — il réduirait la charge cognitive initiale de façon significative pour tous les profils.

2. **Des guides d'outillage pointés explicitement** au bon moment (JUnit5 setup pour Android, SPM pour iOS) — il récupérerait 5-10 minutes critiques sur la phase la plus intensive.

Ces deux ajustements rendraient le Dojo accessible aux stagiaires dans les 60 minutes imparties, sans en réduire la richesse pour les alternants plus expérimentés.

---

*Rapport généré par simulation de 4 agents-personas — 07/03/2026*
