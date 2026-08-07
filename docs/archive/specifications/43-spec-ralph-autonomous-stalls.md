# Spec: Eliminating Autonomous Stalls in `cpm:ralph`

**Date**: 2026-07-26
**Brief**: [docs/discussions/27-discussion-ralph-autonomous-pivot.md](../discussions/27-discussion-ralph-autonomous-pivot.md)

## Problem Summary

`cpm:ralph` intermittently stops for human input during runs that are meant to be unsupervised. Three defects produce this. **A**: `do/SKILL.md:476`, the Change Type Decision gate, is the only `cpm:do` gate with no row in `ralph`'s override table — and the generated prompt's blanket "choose the most reasonable option" combined with the shared convention's *"when in doubt, choose pivot"* routes the loop into `/cpm:pivot`, itself a five-gate facilitation skill. The ralph-wiggum stop hook cannot recover, because an `AskUserQuestion` is not a session stop. **B**: `cleancheck-guard.sh` reads `RALPH_STATE` from `$CLAUDE_PROJECT_DIR`, which is unset in the Bash tool environment and — unlike `STATE_DIR` — has no argument override, so `SUPPRESS` is unreachable from any skill-issued call and the autonomous carve-out never fires; the sentinel write fails identically, so `SKIP` is unreachable too. **C**: `test-cleancheck-guard.sh:31` supplies both `CLAUDE_PROJECT_DIR` and an explicit `STATE_DIR`, exercising a calling convention no skill uses — which is why both defects have been green all along. Verified live: `cpm:clean`'s documented invocation returns zero records with a progress file on disk; the same command with the variable exported returns it correctly.

## Functional Requirements

### Must Have

- **FR1** — Autonomous branch on `do:476`: inline edit / retro observation / amend the epic under execution. `/cpm:pivot` is never invoked.
- **FR2** — Wrong-vs-unmet guard: only a *wrong* criterion may be amended, never a merely *unmet* one. This is the load-bearing safety property — without it the loop has a legal move that converts a failing story into a passing one.
- **FR3** — `**Pivot deferred**` breadcrumb carrying change, target artefact, story number, date, citation.
- **FR4** — Amendments reported as their own run-summary block, distinct from the deferred-retro list.
- **FR5** — Resolve the `do:64` contradiction.
- **FR6** — All four encoding sites change together; the generated prompt is operative.
- **FR7** — `SUPPRESS` fires from a skill-issued invocation.
- **FR8** — `SKIP` fires from a skill-issued invocation.
- **FR9** — `/cpm:clean` enumerates real progress files.
- **FR10** — Tests exercise the skills' calling convention.

### Should Have

- **FR11** — Relocate the Change Type Decision convention into `cpm:do` (verified single consumer; the convention names `cpm:quick` as a second, but `quick/SKILL.md` never references it).
- **FR12** — Make the `ralph:91` prompt budget honest (claims ~1100 chars, measures 1,477).
- **FR13** — Review frontmatter `description` fields of every changed skill.

### Could Have

- **FR14** — A drift check binding the override table to the generated prompt.

### Won't Have (this iteration)

- The phantom execution log and resume detection.
- The completion-promise `<promise>` tag fix.
- Any change to `/cpm:pivot`.
- Autonomous cascade to upstream artefacts.

## Non-Functional Requirements

- **NFR1 Fail-safe** — an unresolvable project root yields `SUPPRESS`, not `RUN`. The safety net is advisory (worst case: leftover files); a stalled loop is the defect being fixed.
- **NFR2 Observability** — any degraded path reports on stderr. Cause B was silent for months.
- **NFR3 Hook callers unchanged** — `session-start.sh:65`, `session-start-compact.sh:47` and `post-compact.sh` run in hook context where the variable is set. They are correct and stay untouched.
- **NFR4 Portability** — macOS and Linux, no new dependencies.
- **NFR5 Net reduction** in `cpm/shared/skill-conventions.md`, attributable to *relocated* content rather than removed rules. The file is 49,704 bytes / ~12.4k tokens and is injected in full into every session in this repo.
- **NFR6 Determinism** — same epics plus same config yields the same prompt.
- **NFR7 Backwards compatibility** — existing `.cpm-progress-*.md` files, existing `.claude/ralph-loop.local.md` files, and the `**Retro applied**` / `**Inline change**` formats parse unchanged.

## Architecture Decisions

### AD1 — Project-directory resolution

**Choice**: helpers resolve their own root (`$CLAUDE_PROJECT_DIR` → `git rev-parse --show-toplevel` → `$PWD`), validate it, and echo it to stderr; `RALPH_STATE` gains an argument override so tests can drive it directly; an unresolvable root yields `SUPPRESS` per NFR1.
**Rationale**: fixes every caller including `/cpm:clean` in one place, and keeps the shared convention's documented invocation valid as written — turning a 21-site change into a 2-file one.
**Alternatives considered**: export the variable at each call site, and require callers to pass both paths. Both rejected as propagation defects (retro 17); the missing `RALPH_STATE` override is precisely what made the current bug unfixable from outside.

### AD2 — Placement of the autonomous branch

**Choice**: an autonomous-mode block in `cpm:do` at the `:476` gate, single-sourced, with `ralph`'s override table referencing it rather than restating the rule.
**Rationale**: mirrors the existing retro-consumption split at `do:56-64`, already written as single source of truth. Retro 03: prefer `do`-level changes over `ralph`-level forks.
**Alternatives considered**: a `ralph`-side fork — rejected, that divergence is the failure retro 03 recorded.

### AD3 — Blast radius of an autonomous amendment

**Choice**: the epic doc `cpm:do` currently has open, plus its companion coverage matrix (`docs/epics/{nn}-coverage-{slug}.md`) — both files `cpm:do` already writes to. Sibling epics, specs, architecture docs and briefs get a `**Pivot deferred**` breadcrumb only.
**Rationale**: draws the boundary at "files this skill was already authorised to modify", which needs no new trust and states cleanly as a criterion.
**Alternatives considered**: epic doc only (rejected — an amended criterion with an unamended matrix row is exactly the ambiguity this spec is trying to remove); including sibling epics (rejected — that is cascade, rejected in discussion 27).

### AD4 — Distinguishing wrong from unmet

**Choice**: amendment requires a **citable contradiction** — a `file:line`, a named spec requirement, or a conflicting criterion in the same epic — recorded in the breadcrumb. Absent a citation the criterion is treated as unmet and existing stuck/blocked handling applies.
**Rationale**: converts a judgement call into a check with an artefact, making violations findable after the run rather than only during it.
**Alternatives considered**: prose guidance alone (rejected — unverifiable, and FR2 is the safety property); forbidding criterion amendment entirely (rejected — that is the record-and-continue option, which drops precisely the cross-story cases a pivot exists for).

### AD5 — How the behaviour reaches the generated prompt

**Choice**: a short clause in `ralph:91` naming the behaviour and its guard, with the detail living in `cpm:do`.
**Rationale**: the generated prompt is the operative site (retro 03), so it cannot be omitted — but it is already 34% over its stated budget, and the retro split shows a short clause plus a `do`-side rule works.
**Alternatives considered**: rely on `do`'s block alone (rejected — the prompt is load-bearing); restate the full rule in the prompt (rejected — budget, and it creates the drift FR14 exists to prevent).

## Scope

### In Scope

- `cpm/hooks/lib/cleancheck-guard.sh` — self-resolution, `RALPH_STATE` argument override, suppress-on-unknown, stderr reporting
- `cpm/hooks/lib/progress-classify.sh` — self-resolution
- `cpm/skills/clean/SKILL.md:28` — drop the now-harmful explicit path (it would override the working resolution with an empty-prefixed one)
- `cpm/skills/do/SKILL.md` — `:476` autonomous branch, `:64` contradiction, `**Pivot deferred**` breadcrumb definition, Step 8 run-summary block
- `cpm/skills/ralph/SKILL.md` — override-table row, `:91` prompt clause, budget statement
- `cpm/shared/skill-conventions.md` — relocate Change Type Decision to `cpm:do`; review the documented guard invocation
- Four test suites (`test-cleancheck-guard.sh`, `test-progress-classify.sh`, `test-hooks-integration.sh`, `test-orphan-detection.sh`) plus new calling-convention coverage
- Frontmatter `description` review for `do`, `ralph`, `clean`

### Out of Scope

- The ralph-wiggum plugin itself — third-party
- `/cpm:pivot` — we stop calling it, we do not alter it
- The other 20 skills' Stale-Progress references — unchanged **by design**; that AD1 makes this true is the decision's main justification, so leaving them alone is a result rather than an omission
- Hook-context callers (`session-start*.sh`, `post-compact.sh`)

### Deferred

- **FR14** — the override-table/prompt drift check. Retro 03 recommended it; it stays a could-have because the four sites are being changed together *this* time and the check protects the *next* time.
- The phantom execution log, and the completion-promise tag fix — both documented in discussion 27 with enough evidence to pick up cold.
- Further relocations out of `skill-conventions.md` — owned by `docs/quick/27-quick-shared-conventions-relevance-check-spec.md`.

## Testing Strategy

### Tag Vocabulary

Test approach tags used in this spec:

- `[unit]` — Unit tests targeting individual components in isolation
- `[integration]` — Integration tests exercising boundaries between components
- `[feature]` — Feature/end-to-end tests exercising complete user-facing workflows
- `[manual]` — Manual inspection, observation, or user confirmation
- `[tdd]` — Workflow mode: task follows red-green-refactor loop. Composable with any level tag (e.g. `[tdd] [unit]`). Orthogonal — describes how to work, not what kind of test.

Runner: `cpm/hooks/tests/run-all-tests.sh`, helpers in `test-helpers.sh`.

The guard/classifier half of this spec is genuinely automatable; the skill-prose half is not. Where a prose requirement carries `[integration]`, that assertion is a **regression net** against later removal — the `[manual]` read beside it is the verification. Structural assertions establish that a section exists, never that its claims are true.

### Acceptance Criteria Coverage

**Inline change**: added the missing NFR2 row — observability was stated as a requirement but given no criterion; surfaced by epic 43-01's coverage matrix (2026-07-26)

| Requirement | Acceptance Criterion | Test Approach |
|---|---|---|
| FR1 | `do:476` carries an autonomous branch naming all three dispositions (inline edit / retro observation / amend the epic under execution) and stating `/cpm:pivot` is never invoked | `[integration]` |
| FR1 | End-to-end read of the finished `:476` block: the three dispositions do not overlap or leave a change type unhandled | `[manual]` — prose coherence has no automated oracle |
| FR1 | must NOT introduce any `AskUserQuestion` in that gate's autonomous path | `[integration]` |
| FR2 | A worked separating case — a criterion plausibly both wrong and unmet — is stated with its correct disposition (decline, mark blocked), and the epic's fixture uses it | `[manual]` |
| FR2 | must NOT permit amendment on evidence of the form "tests fail" or "could not implement" | `[manual]` |
| FR3 | The `**Pivot deferred**` format is defined once and names all five fields: change, target artefact, story number, date, citation | `[integration]` |
| FR4 | `do` Step 8's Report step defines an amendments block distinct from the deferred-retro list | `[integration]` |
| FR4 | must NOT fold amendments into the existing `**Retro applied**` deferred list | `[manual]` |
| FR5 | `do:64` permits the epic-scoped amendment and still forbids edits to the spec and other upstream artefacts | `[manual]` — the requirement is whether two sentences now agree |
| FR6 | The override-table row and the `ralph:91` prompt clause are asserted together in one test, so neither can land alone | `[integration]` |
| FR7 | With `.claude/ralph-loop.local.md` present and `CLAUDE_PROJECT_DIR` **unset**, the guard invoked as `shared/skill-conventions.md` documents returns `SUPPRESS` | `[integration]` |
| FR7 | must NOT export `CLAUDE_PROJECT_DIR` in that test — the unset case *is* the requirement | `[integration]` |
| FR8 | Two guard calls, same `CPM_SESSION_ID`, `CLAUDE_PROJECT_DIR` unset → `RUN` then `SKIP` | `[integration]` |
| FR9 | With N progress files present and `CLAUDE_PROJECT_DIR` unset, `clean`'s documented invocation emits N records | `[integration]` |
| FR10 | Every guard/classifier suite contains at least one case run with `CLAUDE_PROJECT_DIR` unset | `[integration]` |
| NFR1 | An unresolvable project root yields `SUPPRESS` and a stderr warning naming the resolution attempt | `[integration]` |
| NFR2 | The resolved project root is echoed to stderr, and any degraded path reports the resolution attempt it made | `[integration]` |
| NFR3 | `session-start.sh`, `session-start-compact.sh` and `post-compact.sh` behaviour is unchanged — existing suites pass untouched | `[integration]` |
| NFR5 | `shared/skill-conventions.md` is smaller, with the reduction attributable to the relocated Change Type Decision section rather than removed rules | `[manual]` |
| NFR7 | `**Retro applied**` and `**Inline change**` formats parse unchanged in `cpm:status` and `cpm:retro` | `[integration]` |

### Integration Boundaries

1. **Skill → helper** — the Bash invocation shape documented in `skill-conventions.md`. This is where the bug lives, and the boundary the current suite never crosses.
2. **Helper → filesystem** — resolved project root to `docs/plans/` and `.claude/ralph-loop.local.md`.
3. **Hook → helper** — `session-start*.sh` to the classifier. A regression boundary: it works today and must keep working.
4. **`cpm:do` → `cpm:ralph`** — the override table and the generated prompt, the seam retro 03 found drifting.
5. **Breadcrumb → downstream parsers** — `**Pivot deferred**` and `**Inline change**` as read by `cpm:status` and `cpm:retro`.

### Test Infrastructure

Largely present — `run-all-tests.sh`, fixtures, and assertions all exist. One real gap: **the harness cannot currently express the failing case.** `test-cleancheck-guard.sh:31` sets `CLAUDE_PROJECT_DIR` on every invocation, and no helper runs a script with a variable deliberately scrubbed. FR7–FR10 all depend on it, so a run-with-unset-env addition to `test-helpers.sh` is a prerequisite story rather than an afterthought.

### Unit Testing

Unit testing of individual components is handled at the `cpm:do` task level — each story's acceptance criteria drive test coverage during implementation.

## Retro Lessons Incorporated

Selected during startup and applied throughout:

- **Retro 18 (+16/17/19), scope surprises** — fifth consecutive epic where the named sites were not the only sites; a skill's frontmatter `description` is a site every output-changing story touches. Applied: the site survey in Scope was run rather than assumed, and FR13 exists.
- **Retro 17 (+16), criteria gaps** — a criterion propagated to several skills fails at the skills whose shape differs. Applied: per-site criteria above, not one sentence propagated across `do` and `ralph`.
- **Retro 15 (+17), criteria gaps** — third instance of "repo-wide grep criterion implies repo-wide edit scope". Applied: criteria name specific files rather than sweeping `cpm/`.
- **Retro 20, criteria gaps** — when a criterion admits more than one reading, the fixture must contain the case that separates them. Applied: FR2's worked separating case, and FR7's deliberately-unset environment.
- **Retro 17, confirmed five times, patterns worth reusing** — the end-to-end read at the gate catches prose defects that green suites miss. Applied: it is a verification criterion here, not a per-epic disposition.
