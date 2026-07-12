# Spec: cpm2:audit — Codebase Audit Skill

**Date**: 2026-04-25
**Brief**: docs/briefs/01-brief-cpm2-audit-skill.md

## Problem Summary

cpm2's planning pipeline catches what *planning* surfaces — discover, brief, spec, epics, do — but has no skill for systematically auditing what's actually in a codebase. Users with inherited or pre-cpm2 projects have nowhere to land observations about debt, drift, or quality issues that no spec or epic ever touched. `cpm2:audit` fills this gap by producing a commit-pinned audit document with `file:line (symbol)` citations across nine dimensions of code health, ending with concrete handoffs to library / spec / quick.

## Functional Requirements

### Must Have

1. Skill triggers on `/cpm2:audit`; accepts an optional scope hint argument.
2. Standard cpm2 plumbing: Library Check (scope `audit`), Retro Awareness, progress file lifecycle.
3. Orient phase: README, package manifests, directory structure, `git log --oneline -200`, `git log --stat --since="6 months ago"`, top-20 largest, top-20 most-modified files.
4. Orient phase reads `docs/specifications/`, `docs/epics/`, `docs/briefs/`, `docs/architecture/` as **passive context only** — must not bias or shortcut the independent sweep.
5. Capture `git rev-parse HEAD` during orient and record in deliverable header as `**Audited at**: <sha>`.
6. Auto-detect TS/JS, PHP, Laravel (PHP overlay), Python, Rust, Go from manifests.
7. Run stack-specific tooling per detected stack (toolset listed in SKILL.md).
8. Graceful tool degradation: missing/failing tools recorded as `Tool: <name> — <reason>` under "Open questions"; never abort.
9. After orient, present `AskUserQuestion`: "Specific areas to focus on, or sweep all 9 dimensions evenly?"
10. 9-dimension sweep: architectural decay, consistency rot, type & contract debt, test debt, dependency & config debt, performance & resource hygiene, error handling & observability, security hygiene, documentation drift.
11. Every concrete finding cited as `file:line (symbol)`. Non-negotiable.
12. Output to `docs/audits/{nn}-audit-{slug}.md` via shared Numbering.
13. Deliverable structure: header (date, commit SHA, scope), executive summary (max 10 bullets), architectural mental model, findings table (30–80 rows: ID, Category, Citation, Severity, Effort, Description, Recommendation), Top 5 priorities (concrete refactor outlines), Quick wins (checklist), "Things that look bad but are actually fine" (required), Open questions.
14. Severity: Critical/High/Medium/Low. Effort: S/M/L.
15. No-rewrites rule (non-negotiable): recommendations describe scoped changes only.
16. No-padding rule (non-negotiable): empty categories removed entirely; no "Nothing material" placeholders.
17. Scoped audit consistency: deliverable structure stays identical when scope hint is provided; declared scope recorded in header; out-of-scope dimensions omitted.
18. Pipeline handoff offer: final `AskUserQuestion` (library / spec / quick / done); selected option invokes downstream skill via Skill tool with audit document path as args.
19. Plugin registered: skill source at `cpm2/skills/audit/SKILL.md` (auto-discovered); cpm2 plugin version bumped to `0.1.0` in `cpm2/.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`; optional `audit` keyword added.
20. Executive summary includes effort aggregates (e.g. `Effort: S×12, M×7, L×3`).
21. Re-orientation on failure: when a stack tool surfaces a finding that invalidates a recommendation drafted earlier in the same run, the recommendation is updated and the conflict noted in Open questions.

### Should Have

22. Scope hint disambiguation: if hint matches multiple plausible interpretations, confirm with user.
23. Run-time progress signalling: emit `Sweeping dimension N/9: <name>...` at each transition.

### Could Have

(none)

### Won't Have (this iteration)

24. Subagent dispatch for repos >50k LOC.
25. Repeat-run mode (RESOLVED/NEW tagging on existing audit docs).
26. Contrast-against-existing-cpm2-artifacts.

## Non-Functional Requirements

### Performance

- Sweep duration target: 5–20 minutes for typical projects.
- Single-pass v1; no parallel execution.

### Reliability

- Graceful tool degradation across stack tooling, git invocations, and any other shell-out.
- Idempotent re-runs: each run produces a new numbered audit document.
- Compaction resilience via standard cpm2 progress file pattern.

### Security

- Findings must cite `file:line (symbol)` only. **Never** quote actual secret values in the audit document, even for security-hygiene findings.
- Local-only execution; no findings, source, or tool output transmitted externally.

### Usability

- Single-user, single-session.
- Plain markdown deliverable, no custom syntax or tooling required to read it.

### Scalability (deferred)

- Repos >50k LOC: known v1 limitation; subagent dispatch is the v2 enhancement.

## Architecture Decisions

### Plugin registration mechanism
**Choice**: Skill at `cpm2/skills/audit/SKILL.md` (auto-discovered). Plugin version bumped `0.0.2 → 0.1.0` in both `cpm2/.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`. Optional `audit` keyword added.
**Rationale**: Matches every other cpm2 skill — auto-discovery is the established pattern.
**Alternatives considered**: Explicit registration in plugin.json — no precedent.

### Stack detection
**Choice**: Manifest-presence detection. `package.json` → TS/JS; `composer.json` → PHP; `composer.json` + `artisan` → Laravel (PHP overlay); `pyproject.toml`/`requirements.txt`/`setup.py` → Python; `Cargo.toml` → Rust; `go.mod` → Go. Multi-stack supported.
**Rationale**: Cheap, deterministic, no project-tooling invocation needed first.
**Alternatives considered**: Asking the user — breaks the single-question-after-orient discipline. File-extension heuristics — less reliable.

### Tool execution & graceful degradation
**Choice**: Direct `Bash` invocation with structured outcome capture. Failures, missing binaries, and timeouts logged as `Tool: <name> — <reason>` under "Open questions"; audit always continues.
**Rationale**: Matches every other cpm2 skill that runs project tooling. Open-questions placement keeps tool gaps visible to the reader.
**Alternatives considered**: Wrapper script — overhead with no benefit.

### 9-dimension sweep orchestration
**Choice**: Sequential — dimension 1 through 9 in documented order. Run-time progress emits `Sweeping dimension N/9: <name>...`.
**Rationale**: Predictable, matches source skill, supports clean progress signalling and compaction recovery.
**Alternatives considered**: Single-pass classification — harder to track progress and recover.

### Pipeline handoff invocation
**Choice**: `Skill` tool invokes the chosen downstream skill (`/cpm2:library`, `/cpm2:spec`, `/cpm2:quick`) with audit document path as args. "Done" ends session with no invocation.
**Rationale**: Established cpm2 pattern. Each receiver already accepts file-path `$ARGUMENTS`.
**Alternatives considered**: Print-the-command — breaks one-session end-to-end flow.

### Library handoff semantics
**Choice**: Single library wrapper entry per audit. Handoff copies audit to `docs/library/{nn}-library-audit-{slug}.md` with frontmatter prepended; scope keywords selected via `AskUserQuestion`.
**Rationale**: Simplest to implement, cleanest to consume, lowest noise in library scans. Fragmentation deferred to v2.
**Alternatives considered**: Many entries (one per category) — noisy. Combined wrapper + linked index — over-engineered for v1.

## Scope

### In Scope

- All 21 must-have FRs, both should-haves.
- All NFR sections.
- All six architecture decisions.
- Skill source at `cpm2/skills/audit/SKILL.md` (auto-discovered).
- Audit output artifacts at `docs/audits/{nn}-audit-{slug}.md`.
- Plugin version bump `0.0.2 → 0.1.0` in both manifests; optional `audit` keyword.
- Single-entry library handoff with scope-keyword selection.
- Spec and quick handoffs invoking downstream skills with audit path.
- New bash test suite under `cpm2/hooks/tests/` (or `cpm2/skills/tests/`) for structural `[unit]` assertions.

### Out of Scope

- Subagent dispatch.
- Repeat-run mode.
- Contrast-against-cpm2-artifacts.
- Multi-entry library fragmentation.
- CI/CD integration.
- Skill performing fixes (recommendations only; quick wins flow through `/cpm2:quick`).
- Custom severity calibration / configurable thresholds.
- Stack support beyond TS/JS, PHP, Laravel, Python, Rust, Go.

### Deferred

- Subagent dispatch (v2).
- Repeat-run mode (v2).
- Contrast-against-artifacts (v2).
- Library fragmentation (v3-ish, demand-driven).
- Audit-aware `/cpm2:retro` (long-term).
- Custom severity thresholds (demand-driven).
- Additional stack support (demand-driven).

## Testing Strategy

### Tag Vocabulary
Test approach tags used in this spec:

- `[unit]` — Structural file/content assertions runnable from a bash test (extends existing `cpm2/hooks/tests/` framework).
- `[integration]` — Not applicable to v1.
- `[feature]` — Not applicable to v1.
- `[manual]` — Run skill end-to-end on a real or fixture project; inspect deliverable; observe behaviour. Dominant tag for this skill.
- `[tdd]` — Not applicable to a SKILL.md (no red-green-refactor loop fits writing a prompt).

### Acceptance Criteria Coverage

| Requirement | Acceptance Criterion | Test Approach |
|---|---|---|
| #1 Trigger and argument parsing | Skill triggers on `/cpm2:audit`; optional argument parsed as scope hint | `[manual]` |
| #2 cpm2 plumbing | Library Check, Retro Awareness, progress file lifecycle all run as documented | `[manual]` |
| #3 Orient phase | All listed orientation reads occur during orient | `[manual]` |
| #4 Passive cpm2 artifact read | Existing cpm2 artifacts read and surfaced as context | `[manual]` |
| #4 (must NOT) | Skill must NOT use cpm2 artifacts to skip dimensions or shortcut findings | `[manual]` |
| #5 Commit SHA capture | Deliverable header contains `**Audited at**: <40-char-sha>` matching `git rev-parse HEAD` | `[unit]` |
| #6 Stack detection | Manifests map to expected stack(s); Laravel detected when `composer.json` + `artisan` present | `[manual]` |
| #7 Stack-specific tooling | At least one tool from each detected stack invoked | `[manual]` |
| #8 Graceful tool degradation | Missing/failing tool produces "Open questions" entry; audit completes | `[manual]` |
| #8 (must NOT) | Skill must NOT abort on tool failure | `[manual]` |
| #9 User-shaping question | Post-orient AskUserQuestion presented; user input shapes (does not skip) the sweep | `[manual]` |
| #10 9-dimension sweep | Deliverable handles all 9 dimensions in documented order | `[manual]` |
| #11 Citation format | Every concrete finding cited as `file:line (symbol)` | `[unit]` |
| #11 (must NOT) | Citations must NOT quote actual secret values | `[unit]` |
| #12 Numbered deliverable | Output written to `docs/audits/{nn}-audit-{slug}.md` with shared Numbering | `[unit]` |
| #13 Deliverable structure | All required sections present | `[unit]` |
| #14 Severity and effort scales | Critical/High/Medium/Low and S/M/L used | `[unit]` |
| #15 No-rewrites rule | Recommendations describe scoped changes only | `[manual]` |
| #15 (must NOT) | Recommendations must NOT include rewrite/full-replacement phrasing | `[manual]` |
| #16 No-padding rule | Empty dimension sections omitted | `[manual]` |
| #16 (must NOT) | Deliverable must NOT contain "Nothing material" placeholders | `[unit]` |
| #17 Scoped audit consistency | Header records `**Scope**: <hint>`; out-of-scope dimensions omitted | `[unit]` |
| #18 Pipeline handoff offer | Final AskUserQuestion presents 4 options; selection invokes downstream skill via Skill tool | `[manual]` |
| #19 Plugin manifest registration | Both manifests at version `0.1.0`; skill folder exists at `cpm2/skills/audit/` | `[unit]` |
| #20 Effort aggregates | Executive summary contains effort totals | `[unit]` |
| #21 Re-orientation on failure | Late-breaking finding updates earlier recommendation; conflict noted in Open questions | `[manual]` |

### Integration Boundaries

- **Skill → Bash**: stack-tool invocation. Tool failures must surface as Open-questions entries (#8 must-NOT verified at this seam).
- **Skill → File-system**: writes `docs/audits/`; reads `docs/specifications/`, `docs/epics/`, `docs/briefs/`, `docs/architecture/`.
- **Skill → Skill-tool**: pipeline handoffs to `/cpm2:library`, `/cpm2:spec`, `/cpm2:quick`. Receiving skills already accept file-path `$ARGUMENTS`. The audit document is the contract.
- **Skill → Git**: `git rev-parse HEAD`, `git log --oneline -200`, `git log --stat --since="6 months ago"`. Git unavailability handled by the same graceful-degradation rule as stack tools.

### Test Infrastructure
Existing `cpm2/hooks/tests/` framework (bash + `test-helpers.sh`) extended by a new test suite covering the structural `[unit]` criteria. No new framework needed. Captured as a story for `cpm2:epics`: "Plugin manifest + skill structure tests" covering criteria #5, #11, #12, #13, #14, #16 (must-NOT), #17, #19, #20.

### Unit Testing
Unit testing of individual components is handled at the `cpm2:do` task level — each story's acceptance criteria drive test coverage during implementation.
