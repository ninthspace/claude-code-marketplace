# Ralph Retro Application & Simplifier Consistency

**Source spec**: docs/specifications/37-spec-ralph-retro-and-simplifier.md
**Date**: 2026-06-26
**Status**: Pending
**Blocked by**: —
**Retro applied**: 02 · Testing Gaps · Applied — verify by reading edited SKILL.md prose for behaviour/intent, not presence checks
**Retro applied**: 01 · Patterns Worth Reusing · Applied — keep edits structurally consistent; co-locate overrides; mirror existing line patterns

## Relocate the simplifier refactoring pass with guardrails
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: FR1, FR2, FR3, FR4, FR5, FR13
**Retro**: [Pattern worth reusing] Editing skill-prose with all-`[manual]` verification makes Step 5b's new no-test precondition self-skip the refactoring pass — the guardrail validated itself on its own verification gate (no test command present). Stories 2 and 3 are the same shape.

**Acceptance Criteria**:

- Refactoring pass is relocated out of "Step 5b (verification gates only)" into a single story-completion step that runs after every completed story that touched code, in both interactive and autonomous modes [manual]
- A verification-gate story receives exactly one refactoring pass [manual]
- must NOT run the pass on stuck, blocked, or threshold-skipped stories [manual]
- Stories that touched no code (pure docs/config) are skipped and logged as skipped [manual]
- Where a cached test command exists: refactor → retest → revert changes that break tests [manual]
- must NOT refactor when no test command exists — skip and log the reason [manual]
- Laravel → `laravel-simplifier` if available else self-directed; all other projects → self-directed [manual]

> `[manual]` justification: the change is `SKILL.md` instruction prose driving an LLM loop; no harness executes a `SKILL.md`. Verified by a human read of the edits plus an observational `ralph` run.

### Relocate the pass into a story-completion step
**Task**: 1.1
**Description**: Move the refactoring pass out of `do/SKILL.md` "Step 5b (verification gates only)" to fire once at story completion in both interactive and autonomous modes (AD1); covers FR1, FR13 and the exactly-one-pass criterion.
**Status**: Complete

### Add completed + touched-code gating
**Task**: 1.2
**Description**: Gate the pass using existing progress-file signals — story status and the Completed Tasks file list (AD2); covers FR2's must-NOT (never on stuck/blocked/skipped) and FR3 (skip and log no-code stories).
**Status**: Complete

### Wire the retest safety net with the no-test skip branch
**Task**: 1.3
**Description**: Preserve refactor → retest → revert where a cached test command exists; where none exists, skip and log the reason (FR4 + must-NOT); confirm FR5 agent-selection behaviour is carried over unchanged.
**Status**: Complete

---

## Auto-apply safe-category retros in autonomous runs
**Story**: 2
**Status**: Complete
**Blocked by**: —
**Satisfies**: FR6, FR7, FR8, FR9, FR10
**Retro**: [Codebase discovery] The autonomous retro-handling behaviour is encoded in three sites — `do/SKILL.md`'s autonomous override, `ralph/SKILL.md`'s override table, and `ralph`'s generated prompt template (~L87) — and all three must change together; the generated prompt is the operative one, so editing only the doc table would leave the loop behaving the old way.

**Acceptance Criteria**:

- Under autonomous mode, the consumption gate auto-applies safe-category observations: Codebase discoveries and Patterns worth reusing [manual]
- must NOT auto-apply Scope surprises, Criteria gaps, Complexity underestimates, or Testing gaps — these are deferred; Smooth deliveries is informational [manual]
- "Apply" carries the observation as explicit constraint/context into the work loop [manual]
- must NOT trigger autonomous re-planning or scope change when applying [manual]
- Auto-applied lessons record the breadcrumb `**Retro applied**: {nn} · {category} · applied (autonomous, safe-category) — {what it did}` [manual]
- Retros generated mid-run (epic N) are consumable by later epics (N+1) in the same run — Retro Check re-runs in the per-epic restart sequence [manual]
- The safe/defer split lives in a single source (`do`'s autonomous override); `ralph` references it [manual]
- must NOT auto-retire any retro under autonomous mode [manual]

> `[manual]` justification: as Story 1 — `SKILL.md` prose with no executable test oracle; verified by human read plus observational `ralph` run.

### Add the safe/defer category branch to `do`'s autonomous override
**Task**: 2.1
**Description**: Single-source the category split (AD3) in `do/SKILL.md`'s autonomous-mode retro override: auto-apply Codebase discoveries + Patterns worth reusing; defer Scope surprises/Criteria gaps/Complexity underestimates/Testing gaps; Smooth deliveries informational. Covers FR6 and FR7's must-NOT.
**Status**: Complete

### Define autonomous "apply" semantics and the applied breadcrumb
**Task**: 2.2
**Description**: Define "apply" as carrying the lesson as a constraint/context into the work loop, never re-planning (FR8 + must-NOT); record the `applied (autonomous, safe-category)` breadcrumb (FR9); preserve the never-auto-retire rule.
**Status**: Complete

### Add Retro Check to the per-epic restart and point `ralph` at the shared split
**Task**: 2.3
**Description**: Add Retro Check to `do`'s "continue to next epic" re-run list so mid-run retros are consumed (AD4/FR10); update `ralph/SKILL.md`'s disposition-gate row to reference `do`'s single-source split rather than restate it.
**Status**: Complete
**Inline change**: Also updated ralph's generated prompt template (~L87), not just the override table — the prompt is the operative autonomous instruction and still said "auto-defer each observation" (2026-06-26).

---

## Surface simplifier & retro outcomes in the run summary
**Story**: 3
**Status**: Complete
**Blocked by**: Story 1, Story 2
**Satisfies**: FR11, FR12
**Retro**: [Pattern worth reusing] Placing the run-summary reporting in `do`'s shared Step 8 item 4 (which `ralph` inherits by running `/cpm:do`) satisfied the "ralph run summary" requirements without forking a separate `ralph` summary block — single-source the behaviour and let the wrapper inherit it.

**Acceptance Criteria**:

- A per-story simplifier-outcome line is added to the progress file (mirroring `**Retro signals**:`), recording ran / skipped (+reason) / reverted / fell back to self-directed [manual]
- The `ralph` run summary logs, per story, the simplifier outcome [manual]
- The `ralph` run summary lists auto-applied retro lessons prominently for review, separately from deferred ones [manual]
- The new breadcrumb stays parseable by `cpm:status` and `cpm:retro` (backwards-compat) [manual]

> `[manual]` justification: as above — `SKILL.md` prose; verified by human read plus observational `ralph` run.

### Add the per-story simplifier-outcome accumulator to the progress file
**Task**: 3.1
**Description**: Add a per-story simplifier-outcome line mirroring `**Retro signals**:` to `do/SKILL.md`'s progress-file format (AD5; FR11 capture side), recording ran / skipped (+reason) / reverted / fell-back.
**Status**: Complete

### Report outcomes in `ralph`'s run summary
**Task**: 3.2
**Description**: Update `ralph`'s Step 8 run summary to aggregate per-story simplifier outcomes and list auto-applied vs deferred retros (FR11/FR12 report side); confirm the new breadcrumb stays parseable by `cpm:status` and `cpm:retro`.
**Status**: Complete
**Inline change**: Implemented in `do/SKILL.md` Step 8 item 4 (the shared Report step `ralph` inherits by running `/cpm:do`) rather than a separate `ralph` summary block — single source, no fork (2026-06-26).

---
