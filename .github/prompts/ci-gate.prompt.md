---
mode: "chat"
description: "Generate GitHub Actions CI workflow enforcing PROSE quality gates"
---

# CI Quality Gate Generator

## Context

Apply rules from [copilot-instructions.md](../copilot-instructions.md).
Reference domain spec: [ecotrack-domain.spec.md](../../ecotrack-domain.spec.md).

## Task

Generate a GitHub Actions workflow file at `.github/workflows/quality-gate.yml`
that enforces all PROSE quality dimensions on every pull request.

## Required Jobs

### 1. `domain-tests` — TDD gate

- Run on: `push` to any branch, `pull_request` to `main`
- Android: `./gradlew :domain:test` — fail if any domain test fails
- iOS: `xcodebuild test -scheme EcoTrackDomain` — fail if any XCTest fails
- Upload JUnit XML test report as artifact
- Coverage threshold: 80% line coverage on `src/**/domain/**`

### 2. `bdd-scenarios` — BDD gate

- Parse all `.feature` files in `features/`
- Run with Cucumber (Android) or XCTest BDD runner (iOS)
- Fail if any Gherkin scenario is unimplemented (pending steps fail the build)
- Post scenario results as PR comment using `actions/github-script`

### 3. `security-scan` — Safety Boundaries gate

- Run `semgrep` with rules targeting:
  - Hardcoded credentials pattern
  - `Log.d` / `print` calls containing string interpolation (PII risk)
  - `http://` URL literals
  - Missing certificate pinning patterns
- Fail on any HIGH or CRITICAL finding
- Post findings as PR annotations

### 4. `accessibility-lint` — Accessibility gate

- Android: run `lint` with `AccessibilityDetector` checks enabled
  - Fail on: missing `contentDescription`, hardcoded font sizes in `sp`
- iOS: run `SwiftLint` with accessibility rules
- Eco-label: add `eco-review-needed` label to PR if any `// ECO:` comment is added

### 5. `eco-conception-check` — Eco gate

- Detect new background polling intervals under 15 minutes (regex scan)
- Detect new `http://` import or direct `URLSession.shared` usage without pinning comment
- Post warning comment if `// ECO:` suppression comments are added (must be reviewed)
- Label PR with `eco-review-needed` if triggered

## Workflow Constraints

- All jobs run in parallel (no `needs:` between them) — fast feedback
- Use `ubuntu-latest` for Android; `macos-latest` for iOS
- Cache Gradle and Swift Package Manager dependencies
- Secrets: `GITHUB_TOKEN` only — no third-party secrets in CI
- Timeout per job: 10 minutes maximum
- Add a required status check summary job:

```yaml
quality-gate-summary:
  needs: [domain-tests, bdd-scenarios, security-scan, accessibility-lint, eco-conception-check]
  runs-on: ubuntu-latest
  steps:
    - name: All quality gates passed
      run: echo "PROSE quality gates green"
```
