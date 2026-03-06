# EcoTrack Dojo — Facilitator Guide

> For use by the session lead only. Participants receive `DOJO.md`.

---

## Before the Session (T-30 min)

### Environment checks

- [ ] GitHub Copilot extension installed and authenticated in VS Code / JetBrains
- [ ] Copilot Chat enabled (not just completions)
- [ ] Repo cloned on all participant machines — only `.git` and `README.md` present at start
- [ ] Projector / screen share ready for "failure demo" in Phase 4
- [ ] Timer visible to participants (use a projected countdown or browser tab)
- [ ] Platform split: count Android vs iOS pairs — balance if possible

### Starter kit backup

If a pair falls behind, they can pull individual files from the `solutions/` branch:
```bash
git checkout solutions -- .github/copilot-instructions.md
```
Use sparingly — struggling is learning.

---

## Timing Safety Valves

If running behind schedule, apply these cuts in order:

| Cut | Time saved | What is lost |
|---|---|---|
| Skip Phase 3 Step B (live BDD run) — show expected output from this guide | 5 min | Live generation experience |
| Skip Phase 4 Step B (implementation generation) — stop at red tests | 4 min | GREEN phase; keep RED — TDD message lands |
| Shorten retro to 3 questions only | 4 min | 2 retro questions |
| Skip eco-conception instructions file entirely | 3 min | Eco meta-lesson (pick up in debrief) |

**Do not cut:** Phase 1 (hierarchy) or Phase 5 (safety boundaries) — these are the core PROSE insights.

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

### "Copilot ignored our instructions file and used `Log.d` with PII"

**This is intentional friction — use it.** Ask the group: "Why did this happen?"
Answer: The instructions file glob may not have matched, or Copilot was not given the file in context.
Lesson: Safety boundaries only work if the file is in context. PROSE helps ensure that — but it requires discipline.

---

## Android vs iOS Pair Dynamics

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

---

## Retro Facilitation Script

Use a quick "1-2-4-All" format for the 7-minute retro:

1. **1 min — Individual silent reflection:** "Write one thing PROSE prevents that you've experienced as a real problem."
2. **2 min — Pairs:** Share and pick the most resonant one.
3. **4 min — All:** 3–4 pairs share. Facilitator maps to PROSE letters on the board.

**Target landing:** Participants leave with a personal story of a real problem PROSE would have prevented.
That story is what they'll share with their team on Monday.

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
