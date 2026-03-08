# EcoTrack — Coding Dojo PROSE avec GitHub Copilot

> Un Coding Dojo de 60 minutes pour apprendre la méthodologie **PROSE** appliquée au développement mobile avec GitHub Copilot.

---

## Présentation

Ce dojo guide des développeurs Android et iOS à travers la construction du cœur domaine d'**EcoTrack**, une application de suivi d'empreinte carbone personnelle. En une heure, les participants découvrent comment structurer leurs interactions avec GitHub Copilot via la méthode PROSE — pas pour coder plus vite, mais pour coder de manière plus **maintenable, sûre et transmissible**.

**Audience :** Développeurs Android & iOS, tous niveaux (intermédiaire à senior)
**Durée :** 60 minutes
**Outils :** GitHub Copilot (Chat + Completions), VS Code

---

## La méthode PROSE

| Lettre | Contrainte | Ce que ça change |
|--------|-----------|-----------------|
| **P** | Progressive Disclosure | Le contexte arrive juste-à-temps, pas en vrac |
| **R** | Reduced Scope | Une tâche = un contexte borné = un résultat vérifiable |
| **O** | Orchestrated Composition | Des artefacts simples composent en pipelines fiables |
| **S** | Safety Boundaries | Les règles voyagent avec les fichiers, pas dans la mémoire |
| **E** | Explicit Hierarchy | Global → domaine → tâche : chaque couche a sa place |

---

## Structure du dépôt

```
.github/
  copilot-instructions.md          # Règles globales (E — Explicit Hierarchy)
  instructions/
    domain.instructions.md         # Règles domaine auto-actives (E)
    security.instructions.md       # Garde-fous sécurité/vie privée (S)
    accessibility.instructions.md  # Garde-fous accessibilité WCAG 2.2 (S)
    eco-conception.instructions.md # Garde-fous éco-conception (S)
  prompts/
    habit-bdd.prompt.md            # Génération BDD just-in-time (P)
    carbon-calculator.prompt.md    # Pipeline TDD CarbonCalculator (O)
    observability.prompt.md        # Bonus : OpenTelemetry sans PII
    ci-gate.prompt.md              # Bonus : CI gate PROSE

ecotrack-android/
  app/src/main/kotlin/com/ecotrack/domain/    # Implémentation Android (Kotlin)
  app/src/test/kotlin/com/ecotrack/domain/    # Tests TDD Android (JUnit5)
  docs/junit5-setup.md                        # Guide configuration JUnit5

ecotrack-ios/
  Sources/EcoTrack/Domain/                    # Implémentation iOS (Swift)
  Tests/EcoTrackTests/Domain/                 # Tests TDD iOS (XCTest)
  docs/run-tests-vscode.md                    # Guide tests iOS sous VS Code
  Package.swift                               # Configuration SPM

ecotrack-domain.spec.md    # Spec de périmètre borné (R — Reduced Scope)
DOJO.md                    # Guide participant — à distribuer en session
FACILITATOR.md             # Guide animateur — pour l'animateur uniquement
```

---

## Démarrage rapide

### Prérequis

- **GitHub Copilot** : extension installée et authentifiée dans VS Code
- **VS Code** (pour Android ET iOS — les fichiers `.instructions.md` ne sont pas lus dans Xcode ni JetBrains sans configuration supplémentaire)
- **Android** : JDK 17+, Gradle
- **iOS** : Swift toolchain (`swift --version`), extension `sswg.swift-lang` dans VS Code

### Cloner et démarrer

```bash
git clone <url-du-repo>
cd dojo_copilot_prose_mobile
# Ouvrir dans VS Code
code .
```

### Lancer les tests

```bash
# Android
cd ecotrack-android && ./gradlew test

# iOS
cd ecotrack-ios && swift test
```

---

## Les phases du Dojo

| Phase | Durée | Contrainte PROSE | Ce qu'on construit |
|-------|-------|-----------------|-------------------|
| 0 — Kickoff | 5 min | — | Contexte & setup |
| 1 — Explicit Hierarchy | 10 min | **E** | `copilot-instructions.md` + `domain.instructions.md` |
| 2 — Reduced Scope | 8 min | **R** | `ecotrack-domain.spec.md` |
| 3 — Progressive Disclosure | 10 min | **P** | `habit-bdd.prompt.md` + scénarios BDD |
| 4 — Orchestrated Composition | 12 min | **O** | Use case TDD : rouge → vert via composition |
| 5 — Safety Boundaries | 8 min | **S** | `security` + `accessibility` + `eco-conception` |
| 6 — Rétro | 7 min | — | "Qu'est-ce qui s'effondrerait sans PROSE ?" |

---

## Artefacts produits à la fin du Dojo

Chaque binôme repart avec un pipeline PROSE complet et fonctionnel :

```
Spec bornée (R)
  → Instructions hiérarchiques (E)
    → Prompt BDD just-in-time (P)
      → Tests TDD pré-positionnés (O)
        → Implémentation composée (O)
          → Guardrails permanents (S)
```

Ce pipeline n'est pas un exercice : c'est un template directement transférable dans un projet réel.

---

## Pour l'animateur

Consulter **`FACILITATOR.md`** pour :
- La checklist T-30 minutes
- Les soupapes de sécurité timing (quoi couper si en retard)
- La gestion des profils Android vs iOS
- Le script de rétro 1-2-4-All
- Les erreurs fréquentes et les redirections

---

## Amélioration continue par simulation multi-agents

Ce dépôt a été développé et affiné par un processus d'amélioration continue assisté par des agents IA simulant des participants réels.

Chaque itération d'amélioration suit ce protocole :
1. **Simulation de session complète** — une équipe d'agents joue les rôles de participants (développeurs Android et iOS, intermédiaires et seniors) et d'un animateur expérimenté. Chaque agent lit le DOJO.md de bout en bout et simule chaque phase depuis son profil.
2. **Collecte de feedback structuré** — chaque agent-participant rapporte ses points de friction, ses blocages, ses incompréhensions et ses suggestions concrètes avec des références précises aux lignes du document.
3. **Synthèse par l'animateur** — un agent animateur senior analyse les patterns transversaux entre profils, identifie les corrections à forte valeur pédagogique et hiérarchise les améliorations.
4. **Application des corrections** — les améliorations validées sont appliquées directement dans `DOJO.md` et `FACILITATOR.md`, commitées, et le cycle recommence.

Ce processus a permis, au fil des itérations successives, d'affiner les instructions iOS pour les développeurs non familiers avec VS Code, de renforcer les checkpoints de validation entre phases, de clarifier les distinctions Fake/Mock/Stub dans le glossaire, d'améliorer la parité de traitement Android/iOS, et de préciser les garde-fous de sécurité et d'accessibilité pour qu'ils correspondent à des standards professionnels réels (OWASP Mobile, WCAG 2.2).

Le résultat est un dojo testé contre une diversité de profils avant d'être joué en conditions réelles.

---

*EcoTrack Coding Dojo — PROSE Methodology with GitHub Copilot*
*Conçu pour une livraison de 60 minutes avec des binômes Android/iOS mixtes*
