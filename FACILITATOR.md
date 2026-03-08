# EcoTrack Dojo — Facilitator Guide

> For use by the session lead only. Participants receive `DOJO.md`.

---

## Before the Session (T-30 min)

### Environment checks — tâches solo (avant l'arrivée des participants)

- [ ] GitHub Copilot extension installed and authenticated in VS Code / JetBrains
- [ ] Copilot Chat enabled (not just completions)
- [ ] **Licences Copilot actives** : sur chaque machine participante, vérifier sur `github.com/settings/copilot` que la licence est allouée ET que l'extension est authentifiée. L'extension peut être installée sans être authentifiée — Copilot refusera de fonctionner silencieusement.
- [ ] Repo cloned on all participant machines — branche `dojo-<date>` créée
- [ ] Projector / screen share ready for "failure demo" in Phase 4
- [ ] Timer visible to participants (use a projected countdown or browser tab)
- [ ] Platform split: count Android vs iOS pairs — balance if possible
- [ ] **Glossaire imprimé ou projeté** — voir section "Glossaire" dans `DOJO.md`. Distribuer avant de commencer ou afficher pendant la Phase 0. Réduit de ~70% les interruptions pour des définitions de termes.
- [ ] **Vérifier les frontmatters PROSE** : s'assurer que les fichiers `.instructions.md` ont leur bloc `---` YAML.
  Si le script `scripts/validate-prose.sh` existe, le lancer. Sinon, vérifier manuellement les 3 premières lignes de chaque fichier dans `.github/instructions/`.
  Un fichier sans frontmatter n'est pas activé automatiquement par Copilot — source de 10+ minutes de debugging.
- [ ] **Tester la démo Phase 0 seul** — s'assurer que le contraste "avant/après" est visible. Si Copilot génère quelque chose de propre sans instructions (modèles récents 2025-2026), préparer le pivot "maintenabilité" (voir section "Composition Failure Demo").

### Checklist T-5 — tâches avec les participants (à l'arrivée)

- [ ] Chaque participant lève la main quand Copilot Chat est ouvert (validation licences live)
- [ ] iOS uniquement : `swift --version` dans le terminal — résultat visible
- [ ] Android uniquement : `cd ecotrack-android && ./gradlew :app:testDebugUnitTest --tests "com.ecotrack.domain.CarbonCalculatorTest"` — BUILD SUCCESSFUL
- [ ] Distribuer ou projeter le Glossaire `DOJO.md` avant Phase 0

### Préparer les participants selon leur profil

**Si la salle contient des profils débutants** (jamais de tests unitaires, pas de notion d'architecture en couches) :
- Consacrer 5 minutes supplémentaires en Phase 0 pour expliquer le schéma Domain / Data / Presentation (3 boîtes sur un tableau)
- Montrer visuellement le cycle TDD rouge/vert **avant** Phase 4, pas pendant
- Pointer explicitement vers les guides d'outillage **avant** Phase 4 : [`ecotrack-android/docs/junit5-setup.md`](../ecotrack-android/docs/junit5-setup.md) et [`ecotrack-ios/docs/run-tests-vscode.md`](../ecotrack-ios/docs/run-tests-vscode.md)

### Adapter la facilitation au profil — 4 archétypes

**Archétype 1 : Novice absolu (jamais utilisé Copilot, jamais VS Code)**
- Prévoir 10 min de prise en main VS Code avant Phase 0 (panneau Explorer, terminal intégré, Activity Bar)
- Jumeler avec un profil intermédiaire pour les Phases 1-2
- Objectif réduit : comprendre E (Explicit Hierarchy) et S (Safety Boundaries) — le reste est bonus

**Archétype 2 : Utilisateur Chat uniquement (utilise Copilot depuis < 3 mois, jamais configuré d'instructions)**
- Attention aux confusions entre suggestions inline et Chat : les deux fonctionnent différemment
- Question de révélation : "Tu as déjà eu Copilot qui te suggère exactement le bon nom de variable ?" — la réponse mène naturellement à l'Explicit Hierarchy
- Cet archétype tire le plus de valeur de Phase 1 et Phase 4

**Archétype 3 : Utilisateur avancé d'un autre outil (Cursor, Cody, Windsurf avec règles custom)**
- Rediriger les comparaisons : "Chez PROSE, la valeur est dans la hiérarchie et la composition — pas seulement dans les règles"
- Leur `cursorrules` ou `cody.json` existant est un bon point de départ pour Phase 1 : "Comment tu migres ça vers la hiérarchie PROSE ?"
- Risque : ils peuvent aller trop vite et sauter les checkpoints. Ralentir en Phase 4.

**Archétype 4 : Profil venant d'un autre IDE (Xcode, Android Studio sans Copilot)**
- Distribuer une fiche VS Code minimum avant Phase 0 : Explorer (Ctrl+Shift+E), Terminal (Ctrl+`), Command Palette (Ctrl+Shift+P)
- Copilot Chat : `Ctrl+Alt+I` (Windows/Linux) ou `Cmd+Alt+I` (macOS)
- Pour iOS : vérifier Swift dans le PATH avant de commencer (`swift --version`)
- Leur dire explicitement que VS Code est utilisé ici pour les features Copilot spécifiques (`.instructions.md`, `.prompt.md`) — pas par préférence générale

### Coordination avec l'expert Copilot en renfort (si présent)

Si un expert Copilot est présent pour répondre aux questions techniques :

- **Rôle par défaut :** L'expert intervient sur les paires en binôme silencieux pendant que le facilitateur anime. Il ne prend pas la parole devant le groupe sans signal du facilitateur.
- **Signal de prise de parole :** Le facilitateur dit *"[prénom], tu as quelque chose à ajouter sur ça ?"* — jamais d'intervention spontanée de l'expert pendant une explication du facilitateur.
- **Protocole de clôture synchrone :** À 53:00 pile, tout le monde s'arrête où il est. Le facilitateur annonce la retro collective — le niveau d'avancement de chaque paire est une donnée pédagogique, pas un échec.

### Starter kit backup

If a pair falls behind, they can pull individual files from the `solutions/` branch:
```bash
git checkout solutions -- .github/copilot-instructions.md
```
Use sparingly — struggling is learning.

---

## Timing Safety Valves

**Triggers de déclenchement — activer la coupe si :**
- À **20:00** tu n'es pas encore en Phase 2 → couper Phase 3 Step B (live BDD run)
- À **28:00** tu n'es pas encore en Phase 3 → couper Phase 4 Step B (implementation generation)
- À **40:00** tu n'es pas encore en Phase 4 → couper eco-conception + raccourcir la retro
- À **50:00** tu n'es pas encore en Phase 5 → retro de 3 questions uniquement, pas de 1-2-4-All

If running behind schedule, apply these cuts in order:

| Cut | Time saved | What is lost |
|---|---|---|
| Skip Phase 3 Step B (live BDD run) — show expected output from this guide | 5 min | Live generation experience |
| Skip Phase 4 Step B (implementation generation) — stop at red tests | 4 min | GREEN phase; keep RED — TDD message lands |
| Shorten retro to 3 questions only | 4 min | 2 retro questions |
| Skip eco-conception instructions file entirely | 3 min | Eco meta-lesson (pick up in debrief) |

**Do not cut:** Phase 1 (hierarchy) or Phase 5 (safety boundaries) — these are the core PROSE insights.

**Si un binôme finit Phase 4 avant l'heure :** ne pas les envoyer sur le Bonus Round (désynchroniserait le groupe pour la retro). Leur donner à la place : *"Préparez 3 arguments pour la retro : sans PROSE, quel bug serait arrivé en prod dans 6 mois ?"*

> **Phase 5 — Révélation guidée :** avant de créer les fichiers de sécurité/accessibilité/éco, posez les questions de révélation (voir `DOJO.md` Phase 5 intro). Les participants qui se reconnaissent dans les anti-patterns comprennent les règles comme des *corrections*, pas comme des contraintes. Même si vous manquez de temps, gardez ces 2 minutes — elles ont plus d'impact pédagogique que la création mécanique des fichiers.

---

## Common Mistakes and Redirects

### "I just asked Copilot to build the whole app and it kind of worked?"

**Redirect:** "It worked for 3 minutes. Now add a security audit requirement, a platform change,
and a new team member. Does it still work? PROSE is about maintainability and team scaling,
not just first-generation code quality."

### "The instructions file isn't being picked up by Copilot"

**Check:**
1. Is the `applyTo` frontmatter field correct? (glob must match the open file's path)
2. Is the file saved? (Copilot reads from disk)
3. Is Copilot Chat open with the file in context? (drag file into chat if needed)
4. Is the file in `.github/instructions/` (not `/instructions/` at root)?
5. Le fichier actuellement ouvert dans l'éditeur correspond-il au glob `applyTo` ? Un fichier `domain.instructions.md` avec `applyTo: "**/*.swift"` ne s'appliquera pas si l'éditeur actif est un fichier `.md` ou `.kt`. Ouvrir un fichier Swift (ou Kotlin) avant de tester.

### "Our BDD scenarios are too vague / too implementation-specific"

**Gherkin red flags to watch for:**
- "When the user calls `CarbonCalculator.calculate()`" — too implementation-specific
- "Then the result is correct" — not verifiable
- "Given everything is set up" — too vague

**Redirect:** Good Gherkin reads like a conversation with a non-technical stakeholder.
Ask: "Could you read this scenario to your product manager and have them confirm it's correct?"

### "The spec is getting really long"

**Redirect:** "Stop. How many things are in scope right now? Count them.
If it's more than one domain concept, split the spec. Reduced Scope means one spec = one bounded context."

### "Je ne comprends pas ce que veut dire [terme du glossaire]"

**Redirect :** pointer vers la section Glossaire dans `DOJO.md`. Si la question revient souvent pendant la session, projetez le glossaire sur le côté de l'écran.
Termes qui reviennent le plus fréquemment : *PII, invariant, value object, frontmatter, Sendable, Result\<T\>*.

### "Pourquoi les tests doivent-ils échouer au départ ?"

**Redirect :** "Si le test passe sans implémentation, soit il ne teste rien, soit l'implémentation existait déjà. Un test rouge prouve que le test est valide — il détectera un vrai problème. Un test vert sans code, c'est un faux sentiment de sécurité." Montrer le cycle sur le tableau : Rouge = le test sait ce qu'il veut → Vert = le code l'a satisfait.

### "Le Gherkin généré contient littéralement `{{HABIT_CATEGORY}}`"

**Ce qui s'est passé :** Le participant a oublié de remplacer la variable avant d'ouvrir Copilot Chat.

**Redirect :** "Pas de problème — ferme le Chat, ouvre `habit-bdd.prompt.md`, remplace `{{HABIT_CATEGORY}}` par `transport`, sauvegarde (`Ctrl+S`), rouvre le Chat. Ça prend 30 secondes."

**Alternative si ça se répète :** Pour les sessions suivantes, envisager de pré-substituer la variable dans le fichier avant la session (`transport` étant le cas le plus illustratif) et demander aux participants de créer une copie pour d'autres catégories plutôt que d'éditer le template original.

### "Copilot a modifié le fichier de test pour que ça passe"

**Arrêter immédiatement.** Revenir à la version précédente du fichier de test :
```bash
git checkout -- <chemin-du-fichier-test>
```
Expliquer : "Un test modifié pour passer n'est plus un test. On a supprimé le contrat, pas satisfait les exigences."
Demander au binôme de relire le test original et d'identifier ce que l'implémentation doit réellement faire.
Cette situation est un enseignement précieux : les tests sont des spécifications vivantes, pas des obstacles à contourner.

### "Duplicate class error après avoir créé le vrai fichier use case (Android)"

**Ce qui s'est passé :** Le stub `LogHabitCompletionUseCase` dans le fichier de test n'a pas été supprimé après avoir créé `domain/usecase/LogHabitCompletionUseCase.kt`. Le compilateur Kotlin voit deux définitions de la même classe dans le même classpath.

**Redirect :** "Normal — deux définitions de la même classe. Ouvre le fichier de test, descends en bas, supprime tout ce qui est sous le commentaire `// Stubs — participants delete these`. Relance `./gradlew compileDebugKotlin`."

Le message d'erreur exact : `error: duplicate class com.ecotrack.domain.usecase.LogHabitCompletionUseCase`.

### "Le glossaire dit Fake mais le test Android utilise Mockito ?"

**C'est intentionnel — les deux plateformes font des choix différents.**
Le test iOS (`CompleteHabitUseCaseTests.swift`) utilise un `FakeHabitRepository` (état en mémoire — approche DDD pure).
Le test Android (`LogHabitCompletionUseCaseTest.kt`) utilise Mockito — convention courante dans l'écosystème Android/JVM.
PROSE ne prescrit pas d'outil de test ; il prescrit que les tests existent et guident l'implémentation.
Reformuler en question de rétro : "Quelle approche préférez-vous sur votre projet réel, et pourquoi ?"

### "Copilot ignored our instructions file and used `Log.d` with PII"

**This is intentional friction — use it.** Ask the group: "Why did this happen?"
Answer: The instructions file glob may not have matched, or Copilot was not given the file in context.
Lesson: Safety boundaries only work if the file is in context. PROSE helps ensure that — but it requires discipline.

---

## Android vs iOS Pair Dynamics

### Rituel d'ouverture pour groupe senior (< 2 min)

Avant Phase 0, dire explicitement : *"Dans ce dojo, l'expertise mobile que vous avez accumulée est un avantage — vous allez voir comment PROSE structure ce que vous faites déjà instinctivement. La configuration des fichiers `.instructions.md` est nouvelle pour tout le monde ici. On explore ensemble."*

Ce rituel neutralise la compétence-anxiety chez les seniors : il autorise la curiosité sans risque de regard des pairs.

### Gestion de l'asymétrie d'expertise Copilot dans les paires

Si un participant utilise déjà Copilot Chat (Archétype 2) et son partenaire est novice (Archétype 4) :

**Règle des 5 minutes :** Si tu observes qu'un participant drive le clavier depuis plus de 5 minutes sans que son partenaire touche le clavier — intervenir : *"Est-ce que tu peux expliquer à voix haute ce que tu fais ? Je veux m'assurer que tout le monde voit la même chose."*

**Rotation forcée à Phase 4A :** Demander explicitement au participant le moins à l'aise avec Copilot de faire la manipulation : *"C'est toi qui tapes le `#` dans Chat — ton partenaire te guide."*

**Si un participant avancé saute des phases** (ex: génère les tests directement depuis la spec sans passer par BDD) : ne pas stopper l'élan, transformer en insight : *"Tu viens de faire P + O en un prompt. Est-ce que ça marche aussi quand c'est un nouveau membre d'équipe qui repart de zéro ?"*

### Mixed pairs (recommended)
Instruct mixed pairs to write specs and prompts in platform-agnostic language,
then each developer translates to their native platform in Phases 3–4.
This reinforces DDD — the domain model is platform-independent.

### All-Android or all-iOS room
All participants use one platform. The dojo still works — the `{{PLATFORM}}` variable
in prompts just has one value. Consider adding a "what would this look like on the other platform?"
discussion in the retro.

### KMP question
If participants ask about Kotlin Multiplatform: acknowledge it is valid, but out of scope
for this dojo. The spec-based approach (describe once, implement per platform) demonstrates
the same separation-of-concerns principle without requiring KMP setup time.

---

## The "Composition Failure" Demo (Phase 4 — Optional but Powerful)

**Setup:** Ask one volunteer pair (ideally the most confident pair in the room).

**Script:**
1. Open a new Copilot Chat
2. Type exactly: `Build me a carbon calculator for a mobile eco app`
3. Show the result on the projector

**What Copilot will likely produce:**
- A function that works technically
- Wrong naming (no domain language)
- Hard-coded magic numbers
- No test coverage
- Possibly suggests network calls
- No accessibility or security considerations

**Discussion questions (2 min):**
- "Would you ship this?"
- "How long before a new team member misunderstands this code?"
- "How would you enforce the security rules in this output?"

**Then show** the result from the PROSE pipeline (spec → BDD → tests → implementation).
The contrast lands without needing to say anything more.

**Si la démo ne produit pas de contraste visible** (Copilot 2025+ peut générer quelque chose de propre sans instructions) : pivoter vers l'argument de maintenabilité : *"Super — est-ce que ce comportement est garanti pour tous les développeurs de l'équipe, sur toutes les sessions, pour tous les fichiers ? Ou juste pour vous, aujourd'hui, dans ce chat ?"* Le point de PROSE n'est pas que Copilot fait mieux avec des instructions — c'est que le comportement devient **reproductible et versionnable**.

**Plan B si connexion Copilot instable :** avoir 2 captures d'écran prêtes (avant/après `copilot-instructions.md`) dans les slides ou dans un fichier local. La démo live est idéale mais pas obligatoire.

---

## Retro Facilitation Script

**Format adapté pour groupe de 4 (plus fiable que 1-2-4-All à cette taille) :**

1. **2 min — Réflexion silencieuse individuelle :** Chacun écrit ses réponses aux 3 questions de DOJO.md (pad partagé, post-it, ou mémo). Pas de discussion.
2. **3 min — Tour de table rapide :** Chaque participant partage sa réponse à la **question 3 uniquement** ("quelle pratique tu introduis lundi"). Le facilitateur mappe sur les lettres PROSE au tableau.
3. **2 min — Question bonus ou fermeture :** Poser la question des 3 freelances si le groupe est engagé, ou fermer directement sur les ressources post-dojo.

> **Pourquoi question 3 en priorité :** c'est la plus actionnable et la plus mémorisable. Les questions 1 et 2 peuvent être traitées en discussion informelle post-session.

**Livrable de sortie — artefact tangible (30 secondes) :**
Avant de fermer, demander à chaque participant d'écrire sur un post-it ou dans le pad :
> *"La règle PROSE que j'introduis dans mon repo cette semaine : [une ligne]"*

Ce n'est pas une évaluation — c'est un engagement public minimal. Photographier les post-its si en présentiel.

**Target landing:** Participants leave with a personal story of a real problem PROSE would have prevented.
That story is what they'll share with their team on Monday.

**Question bonus haute-valeur (si temps disponible) :**
> *"Imaginez que 3 développeurs freelance rejoignent votre équipe demain, en remote, sans onboarding verbal.
> Comment ils héritent de vos règles domaine, sécurité et accessibilité — sans une heure de vidéo ?*"
>
> Réponse attendue : "Les fichiers `.github/instructions/*.instructions.md` sont dans le repo.
> Copilot les lit automatiquement dès le premier clone."
>
> **C'est le moment où PROSE passe de "technique intéressante" à "valeur équipe concrète".**

---

## Questions That Reveal Deep Understanding

Use these to probe confident participants:

- "What's the difference between a `.instructions.md` file and a comment in the code?"
  → Instructions are active (in Copilot context); comments are passive (in the file, not necessarily in context)

- "If you had to remove one PROSE file, which would hurt the most?"
  → There is no single answer — the value is in the composition. Good discussion.

- "How would you version PROSE artifacts alongside features?"
  → Treat them like code: branch, review, merge. The spec file for a feature lives in the same PR.

- "What is the difference between Progressive Disclosure and just writing good prompts?"
  → Progressive Disclosure is structural. Good prompts are individual. PROSE makes the structure reusable.

---

## Post-Dojo Resources

Point participants to:
- GitHub Copilot custom instructions documentation
- VS Code `.github/copilot-instructions.md` official support page
- ADEME carbon factor database (source used in `domain.instructions.md`)
- WCAG 2.2 quick reference

---

## Session Retrospective (for facilitators only, after each run)

After the session, capture:
- Which phase caused the most confusion?
- Which Copilot prompt produced the most surprising result (good or bad)?
- Did mixed Android/iOS pairs struggle more or less than same-platform pairs?
- What was the most common mistake in the spec-writing exercise?

Use these notes to iterate the dojo design before the next run.

---

## Copilot — Nouveautés 2025-2026 (à mentionner en rétro)

> Ces fonctionnalités ne sont pas couvertes dans le dojo principal mais peuvent être mentionnées en rétro comme "prochaines étapes PROSE".

| Feature | Impact sur PROSE | Disponibilité |
|---|---|---|
| **Copilot Coding Agent** (GitHub.com) | Peut lire une spec, créer une branche, implémenter et ouvrir une PR — Phase 4 entière en automatisé | Copilot Pro+ et Business |
| **Instructions org-level** | Règles globales définies au niveau organisation — appliquées à tous les repos sans `copilot-instructions.md` local | Copilot Enterprise |
| **`mode: "agent"` dans `.prompt.md`** | Exécute un prompt TDD et itère jusqu'aux tests verts | VS Code Copilot 2025+ |
| **Context Providers** | Indexation sémantique du repo — la spec peut être trouvée automatiquement sans `#`-référencement | VS Code Copilot 2025+ (preview) |
| **Copilot Extensions** | Intégration de sources externes (Jira, Confluence, bases ADEME) directement dans Chat | Marketplace 2025 |

**Question bonus rétro :** *"Si Copilot Agent peut lire votre spec et ouvrir une PR, que reste-t-il à faire à l'équipe ?"* → La réponse : écrire et maintenir les artefacts PROSE. L'humain n'est plus dans la boucle d'implémentation — il est dans la boucle de spécification et de validation. C'est la vraie promesse de PROSE à long terme.
