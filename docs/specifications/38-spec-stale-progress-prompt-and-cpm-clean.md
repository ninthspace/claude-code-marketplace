# Spec: Stale-Progress Prompt Reliability & `/cpm:clean`

**Date**: 2026-07-07
**Brief**: [docs/discussions/24-discussion-stale-progress-prompt-and-cpm-clean.md](../discussions/24-discussion-stale-progress-prompt-and-cpm-clean.md)

## Problem Summary

CPM's stale/orphaned progress-file prompt appears to have stopped working. In fact `session-start.sh` still detects orphans and injects the "BLOCKING — ORPHAN CLEANUP REQUIRED" block correctly — but because sessions are almost always opened with a slash command (e.g. `/cpm:status`), the invoked skill's own instructions steamroll the injected SessionStart context and the prompt is never surfaced. SessionStart stdout is advisory; it cannot win against an explicit skill invocation. The fix moves the check to where the user actually enters (the skills) via a once-per-session guard, and closes a real secondary bug: the `/clear`/compact path (`session-start-compact.sh`) has no orphan detection and silently resurrects stale/other-session files as active state. This is the successor to spec 21 (progress-file-cleanup): it delivers spec 21's deferred "compaction hook alignment" and revisits spec 21's decision to keep the logic inline.

## Functional Requirements

### Must Have

- **FR1 — Shared classifier.** A single bash helper classifies each `.cpm-progress-{id}.md` as `CURRENT`, `FRESH` (other session, <3 days), or `STALE` (other session, ≥3 days), emitting labelled records (path, skill, phase, age). Single source of truth for the age + session-ID rules.
- **FR2 — Both hook paths consume the classifier.** `session-start.sh` and `session-start-compact.sh` use the helper and drop their duplicated logic. On `/clear`, other-session/stale files are no longer silently injected as active state.
- **FR3 — Once-per-session safety-net.** A shared-conventions procedure that every `/cpm:*` skill runs as an early startup step, guarded by a `CPM_SESSION_ID`-keyed sentinel so it fires at most once per session regardless of how many skills run.
- **FR4 — Non-blocking, three-way presentation.** BLOCKING behaviour removed. Stale other-session → offered for deletion; fresh other-session → informational only ("active/recent parallel session"), never offered for deletion, never silent; current-session → active state as today.
- **FR5 — New `/cpm:clean` skill.** Exhaustive, on-demand: lists all progress + compact-summary files with age + session label; deletes only files the user names; no sentinel, no staleness filter.
- **FR6 — Never delete without confirmation.** Both the safety-net and `/cpm:clean` are strictly user-initiated; the user always sees what is being removed first.
- **FR7 — Staleness threshold = 3 days**, as a single named constant defined in the helper (replacing `STALE_HOURS=24`).
- **FR11 — Autonomous carve-out.** When an active ralph loop is detected (`.claude/ralph-loop.local.md`), the safety-net is fully suppressed and silent: no prompt, no output, no action. `/cpm:clean` is interactive-only and never part of autonomous execution.

### Should Have

- **FR8 — Compact-summary companions** (`.cpm-compact-summary-{id}.md`) are handled alongside their progress files (listed/cleaned together).
- **FR9 — Robustness.** Cross-platform `stat` (macOS/Linux), graceful skip of malformed/unreadable files, never block session startup or a skill on error.

### Could Have

- **FR10 — Age-based default selection** in the safety-net prompt.

### Won't Have (this iteration)

- Any form of auto-deletion.
- Changes to progress-file format / front-matter schema.
- Within-session skill-switch cleanup (same-path overwrite is already correct).
- Folding progress-file cleanup into `/cpm:archive` (move vs delete semantics differ).
- Hook-level interactive prompts; changes to `CPM_SESSION_ID` generation.

## Non-Functional Requirements

### Reliability
The safety-net and both hooks must never block session startup or a skill's work on error. Malformed progress files, `stat` failures, and unwritable sentinels are skipped gracefully. Sentinel errors fail safe — prefer running the check once over crashing, and never let a sentinel problem cause a deletion.

### Safety / Data Integrity
Deletion only ever targets files the user explicitly names. The current-session progress file is never a deletion candidate. No code path auto-executes a delete.

### Compatibility
macOS + Linux, bash, using the existing dual `stat -f %m` / `stat -c %Y` handling. No new runtime dependencies.

### Usability
Cleanup output stays scannable (a handful of files parsed in ~5s). The once-per-session sentinel prevents the check from nagging across repeated `/cpm:*` invocations.

### Performance
Negligible and bounded — globbing/`stat`-ing a few dotfiles in `docs/plans/` at skill startup; no perceptible latency added.

## Architecture Decisions

### AD1 — Shared classifier is a bash helper
**Choice**: A new `cpm/hooks/lib/progress-classify.sh` that classifies each progress file and emits labelled records. Both hooks and both skills (safety-net, `/cpm:clean`) call it. The 3-day threshold is a named constant defined here.
**Rationale**: One executable source of truth; the rule can't drift across consumers. Independently unit-testable, unlike the current inline logic.
**Alternatives considered**: Inline per script (spec 21's choice — rejected, now 3+ consumers); prose-only rule (rejected — reimplemented, drifts).

### AD2 — Once-per-session sentinel is a distinct marker file
**Choice**: `docs/plans/.cpm-cleancheck-{session_id}`, written on first safety-net run and checked to suppress re-runs. Distinct prefix so the classifier's `.cpm-progress-*.md` glob never picks it up.
**Rationale**: Survives compaction (unlike an in-context flag); prevents nagging; fails safe (sentinel error → run once, never delete).
**Alternatives considered**: In-context flag (rejected — lost across compaction); no guard (rejected — nags every skill).

### AD3 — Autonomous detection via the ralph state file
**Choice**: The safety-net checks for an active `.claude/ralph-loop.local.md` (the signal `session-start.sh` already uses) and fully suppresses itself when present.
**Rationale**: The state file already exists and is authoritative; no new signal needed.
**Alternatives considered**: An env var set by the ralph prompt (rejected — redundant with the state file).

### AD4 — `/cpm:clean` is a lightweight one-shot skill
**Choice**: New `cpm/skills/clean/SKILL.md`, registered in the plugin manifest, modelled on `cpm:quick`'s lightness. Calls the classifier in list-all mode; deletes only confirmed files.
**Rationale**: Distinct verb from `/cpm:archive` (delete ephemeral state vs move durable artifacts); no heavyweight state needed for a one-shot.
**Alternatives considered**: A flag on `/cpm:archive` (rejected — semantics differ); a flag on `/cpm:status` (rejected — status is read-only recon).

### AD5 — `/clear` path unified through the classifier
**Choice**: `session-start-compact.sh` stops its blanket "cat all progress files" fallback; on `clear` it uses the classifier so other-session/stale files are not silently injected as active state. `compact` (same session) still injects the matching file as active.
**Rationale**: Removes the silent-resurrection bug while preserving genuine compaction recovery.
**Alternatives considered**: Leave the compact path untouched (rejected — that is the bug).

## Scope

### In Scope

- New classifier helper `cpm/hooks/lib/progress-classify.sh`.
- Refactor `session-start.sh` (consume helper, remove BLOCKING, non-blocking 3-way output).
- Refactor `session-start-compact.sh` (consume helper on `clear`, stop silent resurrection; keep `compact` injection).
- New shared-conventions **Stale-Progress Check** procedure (sentinel, non-blocking offer, fresh=informational, ralph carve-out).
- One-line "Follow the shared Stale-Progress Check procedure" reference added to all `/cpm:*` skill startups (~20 skills).
- New `/cpm:clean` skill + plugin-manifest registration.
- Update the ralph prompt template's *Autonomous Behaviour* override table to register the new gate.
- Extend the bash test suites; update `cpm/README.md`.

### Out of Scope

- Auto-deletion; progress-file format/schema changes; within-session skill-switch cleanup; folding into `/cpm:archive`; hook-level interactive prompts; `CPM_SESSION_ID` generation changes.

### Deferred

- FR10 age-based default selection in the safety-net prompt.
- An informational stale-file note during ralph runs.

## Testing Strategy

### Tag Vocabulary
Test approach tags used in this spec:

- `[unit]` — Unit tests targeting individual components in isolation
- `[integration]` — Integration tests exercising boundaries between components
- `[feature]` — Feature/end-to-end tests exercising complete user-facing workflows
- `[manual]` — Manual inspection, observation, or user confirmation
- `[tdd]` — Workflow mode: task follows red-green-refactor loop. Composable with any level tag (e.g. `[tdd] [unit]`). Orthogonal — describes how to work, not what kind of test.

### Acceptance Criteria Coverage

| Requirement | Acceptance Criterion | Test Approach |
|---|---|---|
| FR1 Classifier | Current-session file classified `CURRENT` | `[unit]` |
| FR1 Classifier | Other-session file <3d → `FRESH`; ≥3d → `STALE` | `[unit]` |
| FR1 Classifier | must NOT classify the current-session file as STALE/FRESH at any age | `[unit]` |
| FR2 Hooks consume helper | `session-start.sh` orphan output is derived from the helper (no inline duplicate) | `[integration]` |
| FR2 `/clear` fix | On `clear`, other-session/stale files are NOT injected as active state | `[unit]` |
| FR2 `/clear` fix | must NOT blanket-`cat` all progress files as active state on `clear` | `[unit]` |
| FR3 Sentinel | First safety-net run performs the check and writes the session sentinel | `[integration]` |
| FR3 Sentinel | A second `/cpm:*` skill in the same session finds the sentinel and skips | `[unit]` |
| FR3 Sentinel | must NOT re-prompt when the current session's sentinel exists | `[unit]` |
| FR4 Non-blocking | Hook/helper output contains no `BLOCKING`/halt language | `[unit]` |
| FR4 Three-way | Stale → offered for deletion; fresh → informational only | `[manual]` |
| FR4 Three-way | must NOT offer fresh (parallel-session) files for deletion | `[manual]` |
| FR5 `/cpm:clean` | Lists all progress + compact-summary files with age + session label | `[manual]` |
| FR5 `/cpm:clean` | must NOT delete any file the user did not name | `[manual]` |
| FR6 Confirmation | No shell path auto-executes a delete (helper/hooks never `rm`) | `[unit]` |
| FR7 Threshold | Boundary: 3d0h → STALE, 2d23h → FRESH | `[unit]` |
| FR8 Companions | `/cpm:clean` lists a progress file's `.cpm-compact-summary-{id}.md` alongside it | `[manual]` |
| FR9 Robustness | Malformed/unreadable file is skipped; hook still exits cleanly | `[unit]` |
| FR11 Ralph carve-out | With `.claude/ralph-loop.local.md` present, safety-net emits nothing / takes no action | `[unit]` (detection gate); `[manual]` (skill-prose suppression) |

### Integration Boundaries

- **helper → hooks** and **helper → skills** — one shared contract: the helper's labelled output records. This is the primary `[integration]` focus.
- **safety-net → sentinel file** — filesystem read/write of the session-scoped marker.
- **safety-net → ralph state file** — autonomous-mode detection.
- **hook → LLM context** — injection/format contract (as in spec 21).

### Test Infrastructure
None new required. Reuse the mature bash framework (`test-helpers.sh`, `run-all-tests.sh`, fixtures `create_progress_file`/`make_stale`/`setup_project_dir`). Add a new suite `test-progress-classify.sh` for the helper; extend `test-startup-hook.sh`, `test-compact-hook.sh`, and `test-orphan-detection.sh`. Tests are written incrementally within implementation stories (per retro 01/21), not deferred to a separate testing story. Skill-prose criteria are verified by `[manual]` review gates.

### Unit Testing
Unit testing of individual components is handled at the `cpm:do` task level — each story's acceptance criteria drive test coverage during implementation.
