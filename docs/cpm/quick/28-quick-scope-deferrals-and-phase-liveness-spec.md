# Scope Deferrals and Phase Liveness

**Date**: 2026-07-27
**Status**: Complete

## Context

Found by the first live spec-mode run, in a separate repo (project "Split"). Phase 1 never
ended: `/cpm:epics` re-ran every iteration, and because sub-numbers are assigned `max + 1`
each run wrote a *fresh* set of epic docs rather than retrying one — so 50 iterations would
have littered `docs/epics/` with 50 generations without ever working a story.

The reported cause was a parser gap, and it is one: `coverage-parse.sh` reads only
`## Functional Requirements`, so a spec that defers requirements in its `## Scope` section is
invisible to the roll-up. But the gap underneath it is a disagreement between two skills
about the same fact:

- `cpm:epics` SKILL.md:308 — uncovered **Must Have** requirements are blockers, but  
  *"Should-have requirements not covered are warnings, not blockers."*
- `coverage-rollup.sh` — `is_wont()` excluded only headings starting `Won` and containing  
  `Have`, so every other uncovered requirement counted as untraced.
- `cpm:ralph`'s phase clause — any untraced count that is not 0 meant phase 1.

The loop demanded something the generator is licensed not to produce. The Scope section is
one route in; a spec with no Scope section hangs the same way whenever `/cpm:epics` declines
to cover a Should-have. That is why the liveness guard, not the parser, is the load-bearing
half of this fix.

AD1's phase semantics are unchanged: untraced == 0 still ends phase 1.

## Acceptance Criteria

### Fix criteria

- A spec whose Should/Could requirements are named in `### Deferred` or `### Out of Scope`  
  reports them as `EXCLUDED` rather than untraced, and `SUMMARY`'s untraced field reaches 0  
  — **Met**
- `REQ = STATE ∪ EXCLUDED` remains an exact partition, asserted from the records themselves  
  — **Met**
- Phase 1 runs `/cpm:epics` only on exit 4; on any other exit code with untraced > 0 it names  
  the untraced requirements and stops rather than generating another set of epics — **Met**
- Phase 2's exit-3 branch continues only while an epic remains to work; with none left it  
  reports and stops — **Met**
- Each changed clause's stated `**Length: N characters**` figure matches its actual length,  
  and the assembled spec-mode figure matches the sum of its parts — **Met**

### Regression criteria

- A fixture spec that defers requirements *only* via the Scope section reproduces the  
  non-terminating count today and reaches untraced 0 after the change — **Met**
- A **Must Have** named in `### Deferred` is **not** excluded — it stays untraced, so a  
  contradictory spec fails loud instead of reporting itself delivered — **Met**
- A prose-only Scope bullet naming no requirement label excludes nothing — **Met**
- Both guards are asserted against exit codes the script actually returns for a fixture in  
  that situation, not against hand-written codes — **Met**

## Changes Made

- `cpm/hooks/lib/coverage-parse.sh` — new `coverage_spec_scope_deferrals <spec>`, which reads  
  `## Scope` → `### Deferred` / `### Out of Scope` and emits one requirement label per line.  
  A bullet defers only the labels it **opens with** (separators: comma, `and`, `&`, `/`,  
  dash; a leading fragment ending in `:` is allowed), and ranges such as `C1–C5` expand  
  inclusively. Two small awk-lib helpers, `cov_label_prefix` and `cov_label_number`, support  
  the range expansion.
- `cpm/hooks/lib/coverage-rollup.sh` — a label is excluded when `is_wont(heading)` **or** it  
  was named in Scope, *unless* its heading is a Must Have. `EXCLUDED` keeps its two-field  
  arity, so `cpm:status` reads it unchanged, and the header comment now documents both routes  
  out of the count.
- `cpm/hooks/tests/coverage-fixture-helpers.sh` — `--could`, `--deferred` and `--out-of-scope`  
  options, plus `### Could Have` and `## Scope` emission. Scope bullets are written verbatim  
  so a test controls the sentence shape rather than the builder.
- `cpm/hooks/tests/test-coverage-rollup.sh` — the paired reproduction and its controls  
  (fixtures 72–77), 135 assertions in total.
- `cpm/skills/ralph/SKILL.md` — the **phase clause** (now 1,258 chars) makes exit 4 the only  
  route to `/cpm:epics` and forbids a second generation run outright; the **completion  
  clause** (now 991 chars) bounds its exit-3 branch to "only while an epic still has  
  unfinished work". Three paragraphs added: a phase that cannot make progress stops rather  
  than repeating; the same exit code means different things in the two clauses, deliberately;  
  and what a non-zero untraced count is evidence of depends on whether epics exist.
- `cpm/hooks/tests/test-ralph-two-phase-prompt.sh` — a liveness section that builds a fixture  
  where FR1 is covered and FR2 is not, runs the real script for its exit code, asserts it is  
  neither 4 nor 0, and asserts the clause routes that situation to a stop. Its control  
  restores the pre-fix wording and shows the same situation going back to generation.
- `cpm/skills/status/SKILL.md` — the `EXCLUDED` row and rule 5 no longer describe the record  
  as Won't Have only; both routes are named, with a note that the record does not say which  
  one it took.
- `cpm/hooks/tests/test-status-coverage-phase.sh` — the negative/control pair pinned to rule  
  5's old sentence moved with it. The rule's content is unchanged; only its wording moved.
- Version sites `3.5.0 → 3.5.1` (marketplace `3.15.0 → 3.15.1`).

## Verification

Full hook suite: `bash cpm/hooks/tests/run-all-tests.sh` — 48/48 suites, 0 failures.
`test-coverage-rollup.sh` 135/135, `test-ralph-two-phase-prompt.sh` 29/29,
`test-version-agreement.sh` 14/14.

The length figures were re-measured rather than trusted: template 2,858, opening 103, epic-mode
completion clause 927, phase clause 1,258, spec-mode completion clause 991 — assembling to
**4,077**, the figure `ralph/SKILL.md:181` states. The suite asserts the two clause figures
against their blocks; the assembled figure is arithmetic over measured parts.

The exclusion change was run against this repo's own specs before it shipped, which is what
caught the one real regression: spec 45's count moved 19 → 18 because its `### Deferred`
bullet reads *"Nothing. FR12 was the one candidate … NFR6 forbids duplication"* — mentioning
requirements, not deferring them. The "bullet must lead with its labels" rule fixed it,
restored `19 0 15 4`, and is now fixture 76.

Retro 27's rule was applied when `test-ralph-promise.sh`'s MoSCoW net fired on new prose:
the prose was reworded, not the net.

## Retro

**Codebase discovery**: Every existing `cpm:ralph` suite passed with the liveness guards added
— nothing in the repo asserted that a branch was *reachable for a real input*. The clauses
were tested for what they say, never for which branch a given situation lands in, so a clause
that routed every non-zero untraced count to `/cpm:epics` read correctly and looked tested.
The fix is the shape used in `test-ralph-two-phase-prompt.sh`'s new section: build a fixture
in the situation, run the real script for its exit code, assert *which branch* that code
selects, and add a control that restores the pre-fix wording so the assertion is shown to
discriminate. Worth applying to the other prompt-clause suites, which have the same blind spot.
