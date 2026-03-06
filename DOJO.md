# Coding Dojo: PROSE Methodology with GitHub Copilot
## "EcoTrack" — A Mobile App for Personal Carbon Footprint Tracking

> **Duration:** 60 minutes
> **Audience:** Android & iOS developers (mixed pairs encouraged)
> **Tools:** GitHub Copilot (Chat + Completions), VS Code or JetBrains IDE
> **Level:** Intermediate — participants know their mobile stack; PROSE is new to them

---

## The Story

> *It is 2026. Climate anxiety is real. A scrappy startup called GreenLoop wants to ship EcoTrack — a mobile app that helps people log eco-friendly habits (cycling to work, eating plant-based, skipping a flight), calculates their carbon footprint delta, and nudges them with accessible, privacy-safe notifications.*
>
> *The team has one sprint. They have GitHub Copilot. They have never heard of PROSE. You are about to change that.*

Participants will build the **domain core** of EcoTrack — not a full app, but the logic that matters: the habit model, the carbon calculator, and the BDD scenarios that prove it works. Every artifact they touch is a PROSE artifact. Every Copilot prompt is intentional.

---

## PROSE Quick Reference Card

| Letter | Constraint | One-line definition |
|--------|-----------|---------------------|
| **P** | Progressive Disclosure | Context arrives just-in-time, not just-in-case |
| **R** | Reduced Scope | Match task size to AI context capacity |
| **O** | Orchestrated Composition | Simple things compose; complex things collapse |
| **S** | Safety Boundaries | Autonomy within guardrails |
| **E** | Explicit Hierarchy | Layer guidance from global → local specificity |

---

## Timing Breakdown

```
00:00 ─── Kickoff & Context         (5 min)
05:00 ─── E: Explicit Hierarchy     (10 min)  ← copilot-instructions.md + domain.instructions.md
15:00 ─── R: Reduced Scope          (8 min)   ← ecotrack-domain.spec.md
23:00 ─── P: Progressive Disclosure (10 min)  ← habit-bdd.prompt.md + live BDD generation
33:00 ─── O: Orchestrated Comp.     (12 min)  ← carbon-calculator.prompt.md + TDD loop
45:00 ─── S: Safety Boundaries      (8 min)   ← security.instructions.md + accessibility review
53:00 ─── Retrospective             (7 min)   ← "What would collapse without PROSE?"
60:00 ─── End
```

---

## Phase 0 — Kickoff & Context (00:00 – 05:00)

### What happens
Facilitator sets the scene. Participants open the repo. Nothing is there except a `README.md` that says *"EcoTrack: start here."*

### The key question to plant
> "You are about to ask Copilot to build part of a carbon-tracking app. Before you type anything — what does Copilot know about your standards? Your domain language? Your security rules? Your accessibility requirements?"

**Expected answer from participants:** *"Nothing."*

**Facilitator response:** *"That changes right now. Welcome to PROSE."*

### Setup commands
```bash
git clone <dojo-repo>
cd ecotrack
# Repo has only .git and README.md — everything else participants create
```

---

## Phase 1 — E: Explicit Hierarchy (05:00 – 15:00)
### PROSE Constraint: Layer guidance from global to local specificity

**Learning outcome:** Participants understand that Copilot reads context in layers. Global rules go in `.github/copilot-instructions.md`. Domain rules go in `.github/instructions/*.instructions.md`. Task rules go in `.prompt.md` files. The hierarchy ensures the right guidance is always present — never too much, never too little.

### Step 1A — Create the global instructions file (5 min)

**Participants create:** `.github/copilot-instructions.md`

**Copilot prompt to write (in Chat):**
```
I am building a mobile app called EcoTrack. Help me write a
.github/copilot-instructions.md that establishes:
- Domain language (habit, carbon delta, eco-action, footprint baseline)
- Code quality rules: TDD-first, no logic in UI layer, immutable domain models
- Platform rules: Kotlin for Android, Swift for iOS, shared domain logic in KMP or a spec
- Accessibility: WCAG 2.2 AA minimum, dynamic type support, screen-reader labels on all interactive elements
- Security: no PII in logs, no hardcoded credentials, data encrypted at rest
- Eco-conception: no background polling, batch network calls, lazy image loading
Keep it under 80 lines. Use H2 sections.
```

**Expected file:** See `.github/copilot-instructions.md` in this repo.

**Debrief question:** "Why is the line limit important here?" → Reduced Scope preview.

### Step 1B — Create the domain instructions file (5 min)

**Participants create:** `.github/instructions/domain.instructions.md`

**Copilot prompt to write:**
```
Create a .github/instructions/domain.instructions.md for the EcoTrack
domain layer. It should:
- Apply to files matching: src/**/domain/**, **/domain/**, **/*Domain*.kt, **/*Domain*.swift
- Define the ubiquitous language: Habit, EcoAction, CarbonDelta, FootprintBaseline, UserProfile
- Enforce: pure functions for calculations, sealed types for action categories, no side effects in domain
- Require KDoc/DocC comments on every public type
```

**What participants observe:** The `applyTo` frontmatter field scopes these rules. Copilot will only inject them when editing domain files. This is Explicit Hierarchy in action — global rules always apply; scoped rules apply contextually.

---

## Phase 2 — R: Reduced Scope (15:00 – 23:00)
### PROSE Constraint: Match task size to AI context capacity

**Learning outcome:** A single Copilot session cannot hold an entire app in mind. PROSE uses spec files to carve out bounded, completable units of work. A good spec is a contract — not a wish list.

### Exercise: Write the domain spec

**Participants create:** `ecotrack-domain.spec.md`

**Copilot prompt to write:**
```
I need to write a spec file for the EcoTrack domain model.
The scope is ONLY: Habit entity, EcoAction value object, CarbonDelta calculation.
NOT in scope: UI, networking, storage, notifications.

Generate ecotrack-domain.spec.md with these sections:
- Overview (3 sentences max)
- Domain Model (entities, value objects, aggregates)
- Invariants (rules that must never be violated)
- Acceptance Criteria (5 BDD-style Given/When/Then scenarios)
- Out of Scope (explicit list)
- Success Metrics (how do we know this is done?)
```

**The key teaching moment — Reduced Scope anti-patterns:**

| Anti-pattern | Why it fails |
|---|---|
| "Build me the whole app" | Context overflow; Copilot hallucinates connections |
| No "Out of Scope" section | Copilot expands scope to fill silence |
| Acceptance criteria missing | Copilot has no definition of done |
| Spec > 150 lines | Too much to hold in one context window |

**Facilitator challenge:** Ask one pair to write an intentionally vague prompt ("build me an eco app") and share the result. Compare with the spec-grounded result. The difference is visceral.

---

## Phase 3 — P: Progressive Disclosure (23:00 – 33:00)
### PROSE Constraint: Context arrives just-in-time, not just-in-case

**Learning outcome:** PROSE prompt files are not documentation. They are context injectors. They deliver exactly the context Copilot needs for one specific task — no more — and they reference upstream artifacts without duplicating them.

### Step 3A — Create the BDD prompt file

**Participants create:** `.github/prompts/habit-bdd.prompt.md`

**Copilot prompt to write:**
```
Create a .github/prompts/habit-bdd.prompt.md reusable prompt template.
It should:
- Reference [ecotrack-domain.spec.md](../../ecotrack-domain.spec.md) for domain context
- Reference [domain.instructions.md](../instructions/domain.instructions.md) for language rules
- Ask Copilot to generate Gherkin BDD scenarios for the Habit entity
- Require scenarios covering: happy path, edge cases (zero carbon delta),
  accessibility (screen reader announces habit completion),
  and a security scenario (habit data not leaked in crash reports)
- Include a variable: {{HABIT_CATEGORY}} so the prompt is reusable per category
```

### Step 3B — Run the BDD prompt (live generation)

**Participants open** `.github/prompts/habit-bdd.prompt.md` in Copilot Chat and run it with:
- `{{HABIT_CATEGORY}}` = `transport` (cycling, walking, public transit)

**Expected output structure:**
```gherkin
Feature: Transport Habit Tracking

  Background:
    Given the user has established a FootprintBaseline of 8.5 tCO2e/year

  Scenario: User logs a cycling commute
    Given the user selects the "Cycling" EcoAction
    And the distance is 12 km
    When the habit is recorded
    Then the CarbonDelta should be -1.8 kgCO2e
    And the habit list announces "Cycling habit recorded, saving 1.8 kg CO2" to screen readers

  Scenario: User logs a zero-emission action with no measurable delta
    Given the user selects the "Reusable Cup" EcoAction
    When the habit is recorded
    Then the CarbonDelta is 0.0
    And the app does not divide by zero in footprint percentage calculation

  Scenario: Crash report must not contain habit descriptions
    Given a fatal crash occurs during habit submission
    When the crash report is generated
    Then no EcoAction descriptions or user habit names appear in the report payload
```

**The "just-in-time" insight:** The prompt file pulled in domain context and security context only when it was time to write BDD scenarios. It did not dump all of that context into every Copilot interaction all day long.

---

## Phase 4 — O: Orchestrated Composition (33:00 – 45:00)
### PROSE Constraint: Simple things compose; complex things collapse

**Learning outcome:** PROSE orchestrates AI work as a pipeline. Each prompt produces an artifact. The next prompt consumes that artifact. This is how you build complex features without losing coherence — small verified steps compose into reliable wholes.

### The TDD composition pipeline

Participants will execute this three-step pipeline, where each output feeds the next prompt:

```
[spec.md] ──▶ [BDD scenarios] ──▶ [Failing tests] ──▶ [Implementation]
              (Phase 3 output)    (Step 4A)              (Step 4B)
```

### Step 4A — Generate failing tests from BDD scenarios

**Participants create:** `.github/prompts/carbon-calculator.prompt.md`

**Copilot prompt to write:**
```
Create .github/prompts/carbon-calculator.prompt.md that:
- Accepts the BDD scenarios from habit-bdd.prompt.md as input context
- Generates platform-specific unit tests (Kotlin/JUnit5 OR Swift/XCTest)
  based on {{PLATFORM}} variable
- Tests must be FAILING first (TDD red phase) — no implementation yet
- Test class must be named CarbonCalculatorTest / CarbonCalculatorTests
- Each test maps to exactly one BDD scenario (reference by scenario title in @DisplayName)
- Include a test for the zero-delta edge case and the crash-report security scenario
```

**Participants run this prompt** with `{{PLATFORM}}` = their own platform (Android or iOS).

**Android output example:**
```kotlin
// CarbonCalculatorTest.kt — RED PHASE (no implementation exists yet)
@DisplayName("Transport Habit Tracking")
class CarbonCalculatorTest {

    @Test
    @DisplayName("User logs a cycling commute")
    fun `cycling commute produces correct negative carbon delta`() {
        val action = EcoAction(category = ActionCategory.Transport, name = "Cycling", distanceKm = 12.0)
        val delta = CarbonCalculator.calculate(action)
        assertThat(delta.kgCO2e).isCloseTo(-1.8, within(0.01))
    }

    @Test
    @DisplayName("Zero-delta action does not cause division by zero")
    fun `reusable cup action has zero delta and safe percentage calculation`() {
        val action = EcoAction(category = ActionCategory.Consumption, name = "Reusable Cup")
        val delta = CarbonCalculator.calculate(action)
        assertThat(delta.kgCO2e).isZero()
        assertThatCode { FootprintCalculator.percentageOf(delta, baseline = FootprintBaseline(8.5)) }
            .doesNotThrowAnyException()
    }
}
```

### Step 4B — Drive implementation from red tests

**Participants open** their failing test file and trigger Copilot inline:

```
// In the test file, select all failing tests and write in Copilot Chat:
The tests above are failing. Implement CarbonCalculator as a pure function
with no side effects. Use the domain model from ecotrack-domain.spec.md.
Do not add any persistence, networking, or UI logic.
Carbon factors (kgCO2e per km): cycling=0.0, car=0.15, bus=0.04, train=0.03.
```

**The orchestration insight:** Copilot's implementation is constrained by three layers it can see simultaneously:
1. The failing tests (what it must satisfy)
2. The domain spec (what the types must look like)
3. The domain instructions (what style rules apply)

**This is composition.** Three simple artifacts, each correct in isolation, compose into a trustworthy implementation prompt.

### Composition failure demo (facilitator optional)

Ask one pair to skip the spec and prompt files and just say: *"Build me a carbon calculator for a mobile eco app."* Show the result. It works, technically. But: wrong naming, no domain language, no test coverage, no security considerations. The complexity collapsed instead of composing.

---

## Phase 5 — S: Safety Boundaries (45:00 – 53:00)
### PROSE Constraint: Autonomy within guardrails

**Learning outcome:** PROSE does not just tell Copilot what to build — it tells Copilot what it must never do. Safety boundaries are explicit, machine-readable rules that prevent AI from generating code that violates privacy, security, accessibility, or eco-conception constraints.

### Step 5A — Create the security & privacy instructions

**Participants create:** `.github/instructions/security.instructions.md`

**Copilot prompt to write:**
```
Create .github/instructions/security.instructions.md for EcoTrack.
Apply to: **/*.kt, **/*.swift, **/*.ts
Rules to enforce:
- NEVER log habit names, user IDs, or location data (these are PII)
- NEVER hardcode API keys, OAuth secrets, or carbon factor lookup URLs
- ALL data at rest must use platform encryption (Android Keystore / iOS Keychain)
- Network calls must use certificate pinning — flag any URLSession or OkHttp
  call that does not reference a pinning interceptor
- Crash reports (Firebase Crashlytics, Sentry) must scrub habit descriptions
  before submission
- Carbon factor lookup must support offline fallback — no feature should be
  unavailable without network
Flag violations with: // SECURITY: <reason> comment before the offending line.
```

### Step 5B — Accessibility safety boundary

**Participants add to** `.github/instructions/accessibility.instructions.md`:

**Copilot prompt to write:**
```
Create .github/instructions/accessibility.instructions.md.
Apply to: **/*.xml, **/*.swift, **/*View*.kt, **/*ViewController*.swift, **/*Screen*.swift
Rules:
- Every interactive element must have a contentDescription (Android)
  or accessibilityLabel (iOS)
- Minimum touch target: 44x44dp / 44x44pt
- Color must never be the ONLY means of conveying information
  (carbon delta: use icon + color + text, not color alone)
- Dynamic type: all font sizes must use sp (Android) or Dynamic Type styles (iOS) —
  no hardcoded pixel sizes
- Focus order must follow reading order — no custom focusOrder unless documented
Flag violations with: // A11Y: <reason>
```

### Step 5C — Eco-conception safety boundary (the meta-moment)

**Participants add to** `.github/instructions/eco-conception.instructions.md`:

**Copilot prompt to write:**
```
Create .github/instructions/eco-conception.instructions.md.
Apply to: **/*.kt, **/*.swift
Rules — the app must model the values it promotes:
- No background polling intervals under 15 minutes
- Batch all network calls — no single-item API fetches in loops
- Images must use WebP format and lazy loading
- Dark mode must be supported (OLED screen energy saving)
- Local computation preferred over server round-trips for carbon calculation
- No autoplay media
Flag violations with: // ECO: <reason>
```

**The Safety Boundaries insight:** These three files are guardrails. Every time Copilot generates code touching these file patterns, the instructions are in context. Copilot cannot forget the accessibility rule because the rule travels with the file type — not with the developer's memory.

**Discussion prompt:** "What happens to these guardrails when a new developer joins the team?" → They inherit them immediately, on day one, without reading a wiki.

---

## Phase 6 — Retrospective (53:00 – 60:00)
### "What would collapse without PROSE?"

Run a fast round-table. Each pair answers one question:

| Question | PROSE constraint it tests |
|---|---|
| "Copilot keeps suggesting network calls in our domain layer. What prevents this?" | E + S (domain.instructions.md scope + safety boundaries) |
| "We have 3 new BDD scenarios to add next sprint. How do we reuse existing work?" | P (habit-bdd.prompt.md with new {{HABIT_CATEGORY}}) |
| "The junior dev asked Copilot to 'add accessibility'. What went wrong?" | R (scope too vague — no spec, no prompt file) |
| "We want to add push notifications. How do we start?" | O (new spec → new prompt → BDD → TDD → impl pipeline) |
| "A security audit found PII in crash logs. How did our PROSE setup fail?" | S (security.instructions.md was missing the crash log scrubbing rule) |

### Artifacts created today

By the end of the dojo, each pair has produced:

```
.github/
  copilot-instructions.md              ← E: Global hierarchy layer
  instructions/
    domain.instructions.md             ← E: Domain-scoped layer
    security.instructions.md           ← S: Security guardrails
    accessibility.instructions.md      ← S: Accessibility guardrails
    eco-conception.instructions.md     ← S: Eco guardrails
  prompts/
    habit-bdd.prompt.md                ← P: Just-in-time BDD context
    carbon-calculator.prompt.md        ← O: Composition pipeline step
ecotrack-domain.spec.md               ← R: Bounded scope contract
src/domain/
  CarbonCalculator.kt / .swift        ← O: Composed implementation
  CarbonCalculatorTest.kt / .swift    ← O: TDD red→green cycle
```

### Learning outcomes by constraint

| Constraint | What participants can now do |
|---|---|
| **E — Explicit Hierarchy** | Structure Copilot guidance in layers: global → domain → task. Know that local context wins, but global context is always present. |
| **R — Reduced Scope** | Write spec files that bound AI work to one completable unit. Use explicit "Out of Scope" sections as a forcing function. |
| **P — Progressive Disclosure** | Build reusable prompt files that inject just-in-time context. Use `{{variables}}` to make prompts reusable across categories. |
| **O — Orchestrated Composition** | Run multi-step pipelines where each output is the next input. Trust that small verified steps compose into reliable systems. |
| **S — Safety Boundaries** | Write machine-readable guardrails that travel with file types. Make compliance automatic, not dependent on developer memory. |

---

## Bonus Round (if time permits or async homework)

### Observability challenge
```
Using your existing PROSE setup, create:
.github/prompts/observability.prompt.md

It should generate OpenTelemetry spans for the carbon calculation pipeline.
Constraint: spans must NOT include habit names or user identifiers (PII).
Use your security.instructions.md as the reference for what is forbidden.
```

### Automation challenge
```
Create .github/prompts/ci-gate.prompt.md that generates a GitHub Actions
workflow enforcing:
- All domain files pass the domain.instructions.md rules (use a linter step)
- BDD scenarios run before merge
- Accessibility scan (axe-core or mobile equivalent) runs on every PR
- ECO: no new background work added without eco-conception review label
```

---

## Facilitator Notes

See `FACILITATOR.md` for:
- Common mistakes and how to redirect them
- Timing safety valves (what to cut if running long)
- Platform-specific notes for Android vs iOS pairs
- How to debrief the "composition failure" demo safely

---

*EcoTrack Coding Dojo — PROSE Methodology with GitHub Copilot*
*Designed for 60-minute delivery with mixed Android/iOS pairs*
