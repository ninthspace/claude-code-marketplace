# Product Brief: `cpm2:audit` — Codebase Audit Skill

**Date**: 2026-04-25
**Source**: docs/discussions/18-discussion-cpm2-audit-skill.md

## Vision

`cpm2:audit` gives cpm2 users a structured way to surface what their planning pipeline missed — debt, drift, and quality issues in inherited or pre-cpm2 codebases. It produces a commit-pinned audit document with `file:line (symbol)` citations across nine dimensions of code health, and ends with concrete handoffs into the rest of cpm2: findings to library, priorities to spec, quick wins to quick. In 6–12 months, success looks like teams reaching for `/cpm2:audit` whenever they inherit a codebase or suspect that planning has drifted from reality, and trusting its findings enough to feed them straight into the downstream pipeline.

## Value Propositions

1. **Surfaces what planning missed** — Users who inherit a codebase or suspect debt has accumulated outside the cpm2 pipeline get a structured catalogue of findings they can act on, not a vague sense that "something is off."
2. **Citations that survive code change** — Every finding is anchored to a commit SHA plus `file:line (symbol)`, so the audit remains useful weeks or months later even after refactors shift line numbers or rename symbols.
3. **Findings flow into work, not a stale doc** — The skill ends with concrete handoffs (library / spec / quick), so an audit produces downstream artifacts in the same session it was run, rather than becoming a forgotten document.
4. **Considered judgement, not a checklist** — The "looks bad but is actually fine" section, the no-rewrites rule, and the no-padding rule together mean users get findings they can trust, with explicit acknowledgement of intentional patterns rather than blanket criticism.

## Key Features

### Essential

- **Orient phase** — Read README, package manifests, directory structure, git history (`git log --oneline -200`, `git log --stat --since="6 months ago"`), top-20 largest and most-modified files, plus passive read of `docs/specifications/`, `docs/epics/`, `docs/briefs/`, `docs/architecture/` as context only. Builds the mental model that grounds the sweep. (VP1)
- **9-dimension audit sweep** — Architectural decay, consistency rot, type/contract debt, test debt, dependency/config debt, performance, error handling/observability, security, documentation drift. (VP1)
- **Stack-specific tooling integration** — Detect the project's stack and run native tooling, noting missing tools without blocking:
  - **TypeScript/JavaScript**: `npm audit`, `npx knip`, `npx madge --circular`, `npx depcheck`, `tsc --noEmit`
  - **PHP**: `composer audit`, `composer outdated`, `phpstan` or `psalm`
  - **Laravel**: `larastan`, `pint`, `php artisan about`
  - **Python**: `pip-audit`, `ruff check`, `vulture`, `pydeps --show-cycles`, `mypy --strict`
  - **Rust**: `cargo audit`, `cargo udeps`, `cargo machete`, `cargo clippy -- -W clippy::pedantic`
  - **Go**: `govulncheck`, `go vet`, `staticcheck`, `golangci-lint run`

  (VP1)

- **Commit-SHA-pinned, `file:line (symbol)` citations** — Capture `git rev-parse HEAD` during orient and record in deliverable header (e.g. `**Audited at**: abc1234`); every concrete finding cited as `file:line (symbol)`. Documented as a non-negotiable in the SKILL.md. (VP2)
- **User-shaping question after orient** — `AskUserQuestion`: "Specific areas to focus on, or sweep all 9 dimensions evenly?" Lets the user steer without biasing the orient phase. (VP4)
- **Numbered audit deliverable** — Output to `docs/audits/{nn}-audit-{slug}.md` via the shared Numbering procedure. Sections: executive summary, architectural mental model, findings table (30–80 entries with ID, category, citation, severity, effort, description, recommendation), top 5 priorities, quick wins checklist, "looks bad but is actually fine" (required), open questions. (VP1, VP3, VP4)
- **"Looks bad but is actually fine" section (non-negotiable)** — Surfaces considered-but-rejected findings; separates real audits from checklist regurgitation. (VP4)
- **No-rewrites and no-padding rules (non-negotiable)** — Recommend scoped changes only; remove empty categories entirely instead of padding with "Nothing material." (VP4)
- **Pipeline handoff offer** — Final `AskUserQuestion`: send findings to `/cpm2:library` / promote priorities to `/cpm2:spec` / run quick wins through `/cpm2:quick` / done. (VP3)
- **Standard cpm2 plumbing** — Library Check (scope `audit`), Retro Awareness, progress file lifecycle, AskUserQuestion idioms throughout. (Integration with the rest of cpm2.)
- **Optional scope hint argument** — `/cpm2:audit src/auth/` narrows the sweep to a directory or module; deliverable header records the declared scope. (Usability.)

### Enhancing (cut from v1 — flagged as future enhancements in the SKILL.md)

- **Subagent dispatch for >50k LOC repos** — Parallelise the 9-dimension sweep across modules using the Task tool. (Scalability.)
- **Repeat-run mode** — RESOLVED/NEW tagging that converts an existing audit document into a living tracked document. (Longitudinal usefulness.)
- **Contrast-against-existing-artifacts** — Tag findings as "outside planned scope" vs "drift from spec" by reading existing cpm2 specs/epics during the sweep. (Pipeline-aware framing.)

## Differentiation

### Compared to the source skill ([ksimback/tech-debt-audit](https://github.com/ksimback/tech-debt-skill))

- **Pipeline integration**: source ends at the markdown file; `cpm2:audit` ends with handoffs to library / spec / quick. That's the core value-add — turning audit output into downstream work.
- **cpm2 conventions**: progress file, library check, retro awareness, numbered artifact at `docs/audits/{nn}-audit-{slug}.md`. Fits the cpm2 workflow rather than being a parallel standalone tool.
- **Citation durability**: commit SHA pin + `file:line (symbol)` is more durable than the source's `file:line` alone.
- **User-shaping question**: `cpm2:audit` asks the user to point at concerns after the orient phase; the source runs end-to-end silent.
- **Stack coverage**: PHP and Laravel added to the toolchain list.
- **Where the source is stronger today**: subagent dispatch for >50k LOC repos and repeat-run mode — both deliberately deferred from v1.

### Compared to running static analysis tools directly (`npm audit`, `ruff`, `cargo clippy`, `larastan`, etc.)

- **Synthesis**: a list of tool warnings is a dump, not an audit. `cpm2:audit` runs the same tools but synthesises across nine dimensions, ranks by severity and effort, and produces concrete recommendations.
- **Mental model first**: the orient phase grounds findings in context; direct tool runs lack any such grounding.
- **"Looks bad but is actually fine" section**: tools can't make this distinction; the audit can.
- **Where direct tools are stronger**: speed (seconds vs 5–20 minutes), determinism, suitability for CI/CD pipelines.

### Compared to other cpm2 skills (`retro`, `status`, `architect`)

- **Different orientation**: `retro` reflects on cpm2-planned work; `status` recons project state from cpm2 artifacts; `architect` explores forward decisions. `cpm2:audit` is the only skill that does independent codebase inspection of code that may never have been planned through cpm2.
- **Honest overlap**: for projects fully planned through cpm2 from day one, `retro` will catch most quality drift through its feed-forward mechanism. `cpm2:audit`'s strength is for inherited code, pre-cpm2 codebases, or any project where planning has gaps.
- **Where they remain stronger**: `retro` is lighter weight (minutes, not 5–20 minutes); `status` is faster for "what's the project state right now" questions.

## User Journeys

### Journey 1: Inheriting a Laravel application

**Persona**: Senior developer who has just joined a small team and inherited a 3-year-old Laravel application. They have cpm2 installed and are technically experienced but new to *this* codebase.

**Trigger**: They've spent two days reading the code and have a pile of vague "this seems weird" reactions but no structured understanding. Their PM wants a new feature; they need to decide which areas need refactoring before they can build it cleanly.

**Steps**: They run `/cpm2:audit` from the project root. The skill orients (README, `composer.json`, directory structure, `git log`, top-20 files; notes that `docs/specifications/` is empty since this project pre-dates cpm2). After orient it asks if there are focus areas — they mention the auth layer feels off. The sweep runs `composer audit`, `larastan`, and `pint --test`, finishing with an audit document at `docs/audits/01-audit-app-health.md` with 47 findings, top 5 priorities, quick wins, and a "looks bad but is actually fine" section explaining two patterns the dev had been confused about. They take the top 5 priorities into `/cpm2:spec` and pick three quick wins to run through `/cpm2:quick`.

**Outcome**: Within an hour they have a structured catalogue of debt, have learned that two suspicious patterns are intentional, have scoped a refactor spec, and have shipped three quick wins. Vague unease is replaced with a plan.

### Journey 2: Solo dev preparing a project for a collaborator

**Persona**: Part-time maintainer of a TypeScript SPA they built solo over 18 months. They're onboarding a contractor in two weeks.

**Trigger**: They want to spot the highest-impact issues so the contractor's first impression isn't "this is a mess," and they want a referenceable document the contractor can read on day one.

**Steps**: They run `/cpm2:audit src/` to scope to the frontend. The skill orients, runs `npm audit`, `npx knip`, `npx madge --circular`, and `tsc --noEmit`, notes one missing tool (`depcheck`) without blocking, and produces `docs/audits/03-audit-frontend-cleanup.md` with 22 findings (smaller project, fewer findings). They send the audit into `/cpm2:library` so the contractor can read it on day one, and run two quick wins through `/cpm2:quick`.

**Outcome**: When the contractor starts, the project has a referenceable health document, the worst issues have been cleaned up, and onboarding includes "here's what to know about this codebase" rather than discovery on the fly.

### Journey 3: Team adopting cpm2 on a long-running codebase

**Persona**: A team of three Python engineers who just installed cpm2 on a 5-year-old service. They've never used cpm2 on this code; tribal knowledge lives in three engineers' heads.

**Trigger**: Before running `/cpm2:discover` for a new feature, they need a baseline understanding documented in cpm2 idioms, so future briefs and specs can reference it instead of relying on memory.

**Steps**: They run `/cpm2:audit` from the project root. Full orientation, full 9-dimension sweep with `pip-audit`, `ruff check`, `mypy --strict`, `vulture`, `pydeps --show-cycles`. The skill produces `docs/audits/01-audit-baseline.md` with 64 findings. They send all findings into `/cpm2:library` (scope: `spec`, `architect`) so future cpm2 work can reference them by ID. The top 5 priorities go into a refactor spec; the rest stand as known context.

**Outcome**: A 5-year-old codebase moves from "implicit tribal knowledge" to a referenceable cpm2 artifact. Future briefs and specs can cite findings by ID rather than re-discovering them.
