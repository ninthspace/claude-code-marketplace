# Spec: /cpm:ralph — Retro Application & Simplifier Consistency

**Date**: 2026-06-26
**Brief**: docs/discussions/23-discussion-ralph-retro-and-simplifier.md

## Problem Summary

The `/cpm:ralph` autonomous execution path has two observed gaps with a shared root cause — *it does work silently and skips silently*. First, retros are **generated** at each epic's completion but never **applied**: under autonomous mode the `cpm:do` consumption gate auto-defers every observation, so in a multi-epic run epic 1's retro is deferred (not applied) when epic 2 starts, and the loop produces learning it cannot consume mid-flight. Second, the `laravel-simplifier` refactoring pass (`cpm:do` Step 5b) is bolted to the verification gate — it runs only on verification-gate stories that pass, skipping implementation-only and stuck/skipped stories, with no record of what happened. This spec makes the simplifier run consistently (with guardrails), lets autonomous runs auto-apply *safe-category* retro lessons, and makes both outcomes visible in the run summary.

## Functional Requirements

### Must Have

- **FR1** — Relocate the refactoring pass out of "Step 5b (verification gates only)" into a single story-completion step that runs after **every completed story that touched code**, in both interactive and autonomous modes.
- **FR2** — Run the pass **only on stories that completed successfully** — never on stuck, blocked, or threshold-skipped stories.
- **FR3** — Skip stories that touched **no code** (pure docs/config), logged as skipped.
- **FR4** — Retest safety net: where a cached test command exists, refactor → retest → revert on break (preserves current behaviour). Where **no test command exists**, skip the pass and log the reason — never refactor untested code blind.
- **FR5** — Preserve agent selection: Laravel → `laravel-simplifier` if available, else self-directed; all other projects → self-directed.
- **FR6** — Under autonomous mode, the retro consumption gate **auto-applies** safe-category observations: **Codebase discoveries** and **Patterns worth reusing**.
- **FR7** — Under autonomous mode, it **defers** judgement-heavy categories: **Scope surprises, Criteria gaps, Complexity underestimates, Testing gaps**. **Smooth deliveries** is informational (no action).
- **FR8** — "Apply" (autonomous, safe-category) means carrying the observation as explicit constraint/context into the work loop — never autonomous re-planning or scope change.
- **FR9** — Auto-applied lessons record a distinct breadcrumb: `**Retro applied**: {nn} · {category} · applied (autonomous, safe-category) — {what it did}`.
- **FR10** — Retros generated mid-run (epic N) are consumable by later epics (N+1) in the same run: the per-epic restart re-runs the Retro Check so freshly written lessons are seen.
- **FR11** — The `ralph` run summary logs, per story, the simplifier outcome: ran / skipped (+reason) / reverted / fell back to self-directed.
- **FR12** — The `ralph` run summary lists auto-applied retro lessons prominently for review, separately from deferred ones.

### Should Have

- **FR13** — The simplifier relocation (FR1–FR4) applies to interactive `/cpm:do` as well as `ralph`. *(Retro auto-apply remains autonomous-only; interactive `/cpm:do` keeps the disposition gate.)*

### Could Have

- **FR14** — The safe/defer category split is documented as the default and written so it is easy to adjust later — as prose, not a configuration mechanism.

### Won't Have (this iteration)

- Autonomous auto-apply of judgement-heavy categories (scope/criteria/complexity/testing-gap).
- Autonomous auto-**retirement** of retros (remains a deliberate human action).
- Any change to retro *generation* logic.
- A configurable/tunable category set (mechanism).
- Refactoring agents for frameworks other than Laravel.

## Non-Functional Requirements

**Reliability / backwards compatibility** — The retest-and-revert safety net is preserved exactly; all degradation paths still hold (no test → skip; `laravel-simplifier` unavailable → self-directed; no retros → gate skipped silently). The new breadcrumb is additive — existing `**Retro applied**: … deferred …` breadcrumbs and the epic-doc format stay parseable by `cpm:status`, `cpm:retro`, and the next reader.

**Performance / cost** — Running the simplifier after every completed code-touching story adds per-loop time/token cost; accepted, but bounded by FR2/FR3 and capped at **one pass per story** (a verification-gate story is not refactored twice).

**Consistency with skill conventions** — Edits follow existing `SKILL.md` structure and shared conventions; no forked logic (the autonomous-mode override and the safe/defer split live in a single source).

## Architecture Decisions

### AD1 — Relocate the refactoring pass, don't duplicate it
**Choice**: Lift the pass out of "Step 5b (verification gates only)" into one story-completion step gated on *completed + touched code*, for both modes.
**Rationale**: one trigger, one pass per story (satisfies perf NFR), no mode-forked logic.
**Alternatives considered**: add a second completion-time trigger — rejected (double-pass risk, two paths to keep in sync).

### AD2 — Reuse existing progress-file signals for the guardrails
**Choice**: Determine "completed" from story status and "touched code" from the existing Completed Tasks file list; no new tracking for FR2/FR3.
**Rationale**: the data already exists where current Step 5b reads it.
**Alternatives considered**: new per-story metadata — rejected (redundant).

### AD3 — Single source for the safe/defer category split
**Choice**: Encode the category branch in `cpm:do`'s autonomous-mode override; `ralph`'s disposition-gate row references it rather than restating the list.
**Rationale**: consistency NFR — no forked category lists drifting apart.
**Alternatives considered**: duplicate the split in `ralph` — rejected.

### AD4 — Retro Check joins the per-epic restart sequence
**Choice**: Add Retro Check to the "continue to next epic" re-run list (alongside Library Check, Framework Detection, Story Hydration) so each epic re-globs `docs/retros/`.
**Rationale**: this is what makes FR10 (within-run learning) actually work.
**Alternatives considered**: glob once at loop start — rejected (defeats the purpose).

### AD5 — One new progress-file accumulator for the run summary
**Choice**: Add a per-story simplifier-outcome line to the progress file (mirroring `**Retro signals**:`), aggregated by `ralph`'s Step 8 summary for FR11/FR12.
**Rationale**: minimal new state, established pattern.
**Alternatives considered**: reconstruct outcomes at summary time — rejected (data may be gone).

## Scope

### In Scope

- FR1–FR12 (must) and FR13 (should); FR14 as documented default.
- Edits to `cpm/skills/do/SKILL.md` and `cpm/skills/ralph/SKILL.md`, including the AD4/AD5 structural changes.

### Out of Scope

- Changing retro generation logic; autonomous auto-retirement; autonomous auto-apply of judgement-heavy categories; a configurable category mechanism; non-Laravel refactoring agents.

### Deferred

- Tunable safe-category configuration if demand emerges.
- A `rename/format-only` fallback for no-test stories (skip chosen now).
- Framework-specific refactoring agents beyond Laravel.

## Testing Strategy

### Tag Vocabulary
Test approach tags used in this spec:

- `[unit]` — Unit tests targeting individual components in isolation
- `[integration]` — Integration tests exercising boundaries between components
- `[feature]` — Feature/end-to-end tests exercising complete user-facing workflows
- `[manual]` — Manual inspection, observation, or user confirmation
- `[tdd]` — Workflow mode: task follows red-green-refactor loop. Composable with any level tag (e.g. `[tdd] [unit]`). Orthogonal — describes how to work, not what kind of test.

**Why `[manual]`-dominant**: the artifacts are `SKILL.md` instruction prose driving an LLM loop; no harness executes a `SKILL.md`, and the plugin's bash tests cover hook scripts this change doesn't touch. Verification is a genuine human read of the edits plus an observational `ralph` run on a throwaway multi-epic project. Per retro 02, the `[manual]` read must not be reduced to a structural-presence check.

### Acceptance Criteria Coverage

| Requirement | Acceptance Criterion | Test Approach |
|---|---|---|
| FR1 | Pass fires after every completed code-touching story in both modes; "verification gates only" restriction removed | `[manual]` |
| FR1 (must NOT) | A verification-gate story gets exactly one refactoring pass, never two | `[manual]` |
| FR2 (must NOT) | Pass does NOT run on stuck / blocked / threshold-skipped stories | `[manual]` |
| FR3 | Stories touching no code are skipped and logged | `[manual]` |
| FR4 | With a test command: refactor → retest → revert on break | `[manual]` |
| FR4 (must NOT) | With no test command: pass does NOT refactor — skips + logs reason | `[manual]` |
| FR5 | Laravel → `laravel-simplifier` if available else self-directed; others self-directed | `[manual]` |
| FR6 | Autonomous mode auto-applies Codebase-discovery & Pattern-worth-reusing observations | `[manual]` |
| FR7 (must NOT) | Autonomous mode does NOT auto-apply scope/criteria/complexity/testing-gap; defers them | `[manual]` |
| FR8 (must NOT) | "Apply" carries lesson as constraint; does NOT trigger autonomous re-planning/scope change | `[manual]` |
| FR9 | Auto-applied lessons get the `applied (autonomous, safe-category)` breadcrumb | `[manual]` |
| FR10 | Epic N+1 consumes a retro written by epic N in the same run | `[manual]` |
| FR11 | Run summary logs per-story simplifier outcome (ran/skipped+reason/reverted/fell-back) | `[manual]` |
| FR12 | Run summary lists auto-applied lessons prominently, separate from deferred | `[manual]` |
| Won't (guard) | Autonomous mode does NOT auto-retire any retro | `[manual]` |

### Integration Boundaries

- **`ralph` → `do`**: the relocated pass and per-epic Retro Check must fire through `ralph`'s autonomous overrides, not only in standalone `do`.
- **`do` → progress file → `ralph` summary**: the per-story outcome accumulator (AD5) is the contract feeding FR11/FR12.
- **`do` retro gate → `docs/retros/`**: the per-epic re-glob (AD4) is the seam enabling FR10.
- **Breadcrumb → downstream consumers**: the new breadcrumb must stay parseable by `cpm:status` and `cpm:retro`.

### Test Infrastructure
None required and none feasible to add for behaviour — no harness executes `SKILL.md` prose, and building one is out of scope. Verification is manual prose review plus an observational `ralph` run.

### Unit Testing
Unit testing of individual components is handled at the `cpm:do` task level — not applicable here, as the change is instruction prose rather than executable code.
