# Discussion: `cpm:ralph` — autonomous stalls and the pivot gate

**Date**: 2026-07-26
**Agents**: Jordan (PM), Margot (Architect), Bella (Senior Developer), Priya (UX Designer), Tomas (QA Engineer), Casey (Test Engineer), Sable (DevOps), Elli (Technical Writer), Ren (Scrum Master)

## Discussion Highlights

### Chris's topic — occasional stalls in `cpm:ralph`

Symptom as reported: *sometimes, but not often*, an autonomous run stops to ask a question or pauses for manual continuation.

**Cause 1 — an uncovered `cpm:do` gate (the one Chris chose to fix).** Every `AskUserQuestion` in `do/SKILL.md` was mapped against the 15 rows of `ralph`'s override table (`ralph/SKILL.md:232-246`). Fourteen are covered. **`do/SKILL.md:476` — the Change Type Decision gate — is not.** Worse than a plain omission: the prompt's blanket instruction ("choose the most reasonable option for every AskUserQuestion") combines with the shared convention's *"When in doubt, choose pivot"* to steer the loop into `/cpm:pivot`, which has 5 `AskUserQuestion` gates of its own. Fires rarely — only when a change-worthy situation appears mid-task — which matches "sometimes, but not often". The stop hook cannot rescue this: an `AskUserQuestion` is not a session stop, so the hook never fires.

**Cause 2 — stop-hook bail-outs (raised, not chosen, still open).** `stop-hook.sh` has seven paths that `rm` the state file and `exit 0`: `:35`, `:46`, `:53`, `:65`, `:76`, `:85`, `:103`. Each ends the loop with a stderr message the user may not see. Prime suspect `:71` — `grep -q '"role":"assistant"'` matches unspaced JSON literally, so any upstream transcript-format change kills the loop. Also `set -euo pipefail` (`:7`) means a failing `jq` at `:90` exits non-zero *before* the handler at `:98`, making that handler dead code; a non-zero hook exit does not block the stop either.

**Distinguishing them (Tomas):** gate stall → question card on screen, session alive, `.claude/ralph-loop.local.md` still present with its iteration count. Hook bail-out → no question, session ended, **state file gone** (the hook deletes it on every giving-up path). Third possibility not yet ruled out: a plain Claude Code permission prompt (acknowledged at `ralph/SKILL.md:60`), which looks like a gate stall but is not CPM's card.

### DECISION — how the pivot gate behaves under autonomy

Chris's steer: *"`cpm:ralph` should implicitly resolve the pivot itself so `cpm:pivot` isn't required."*

Two readings were put to him and a third emerged and won.

- **Option 1 — record and continue** (nothing upstream moves). **Rejected.** Chris asked whether the essence of the pivot still gets applied under this option; Margot's answer split it: where the artefact is wrong but the right work is knowable, the code lands correctly and only the document goes stale (spec→reality drift) — but where it is a *scope* change, the essence is lost entirely, because later stories never receive it. Since the decision matrix defines a pivot as warranted precisely when a change "affects ≥2 stories or any downstream document", option 1 preserves the cases where a pivot was **not** needed and drops the ones where it was.
- **Option 2 — amend and cascade upstream autonomously.** Rejected as too broad: an unsupervised process rewriting specs destroys the spec's value as the thing code is measured against.
- **Option 3 — amend the epic under execution, defer upstream. ACCEPTED by Chris.** Ralph applies the change to the epic doc it is currently running, so later stories in the same run inherit corrected criteria; everything upstream (spec, architecture, other epics) gets a deferred breadcrumb for human review. Rationale (Jordan): ralph already writes that epic doc constantly — statuses, breadcrumbs, coverage rows — so the blast radius stops at an artefact it was already authorised to write, while the cross-story value is retained.

**Guard (Casey), accepted as part of the decision:** ralph may amend criteria that are **wrong**; never criteria that are merely **unmet**. Without this the loop has a legal move that converts a failing story into a passing one, and no test suite catches it.

**Verification consequence (Casey):** the coverage matrix records proof against requirements, and Step 8 reports a verified count. If criteria move mid-run, some rows carry proof against the old wording and some the new, indistinguishably — "9/9 verified" then means less than it appears. The amendment breadcrumb should carry the story number it landed at so a reader can see which side of the change each proof sits on.

**Reporting requirement (Priya):** amended criteria get their own named block in the run summary, above the completions — not folded into the deferred-retro list. That list is "things I chose not to do"; this is "things I did to your epic while you slept". Without it, a story that completed *because ralph rewrote what completion meant* looks identical to one that genuinely passed, and the silent-work problem discussion 23 closed is rebuilt.

### Design constraints carried into the change

- **Placement (Margot):** this belongs in `cpm:do` as an autonomous-mode branch on the `:476` gate, mirroring the existing retro split at `do/SKILL.md:56-64` — which is explicitly written as single-source-of-truth with `cpm:ralph` referencing it rather than keeping a parallel list. Retro 03's recommendation: *prefer `do`-level changes over `ralph`-level forks*.
- **Direct contradiction to resolve:** `do/SKILL.md:64` currently states that autonomous application "does **not** trigger autonomous re-planning, story re-scoping, or any edit to the epic or spec." Option 3 deliberately changes this for the epic; the sentence must be amended rather than left in conflict.
- **Every encoding site changes together (retro 03's codebase discovery):** autonomous behaviour is re-stated in coupled places, and the **generated prompt template** (`ralph/SKILL.md:91`) is *the operative one*. Editing only the doc table leaves the loop behaving the old way. The four sites Bella identified:
  1. `do/SKILL.md:476` — add the autonomous-mode branch on the gate.
  2. `do/SKILL.md:64` — amend the sentence forbidding autonomous edits to the epic.
  3. `ralph/SKILL.md:232-246` — a sixteenth row in the override table.
  4. `ralph/SKILL.md:91` — the generated prompt clause (operative).
- **Fifth site worth folding in (Bella):** the shared **Change Type Decision** convention has exactly one consumer — `do/SKILL.md:476`. The convention's own text names `cpm:quick` as a second consumer, but `quick/SKILL.md` never references it. `CLAUDE.md` already flags the section as a relocation candidate on a count of one. Moving it into `do` while editing its only caller is the same change, not extra work — and it takes the "when in doubt, choose pivot" line, which is what steered the loop wrong, out of every session's preamble.
- **Naming (Elli):** `**Inline change**: {summary} ({YYYY-MM-DD})` and `**Retro**:` already exist for the two auto-taken options. The missing vocabulary is for the declined-pivot case — proposed `**Pivot deferred**: {what would need to change} ({date})`.
- **Prompt budget (Elli):** the template at `ralph/SKILL.md:91` states "keep concise — around 1100 chars" and measures **1,477**. Any added clause pushes further past a target the skill sets for itself; decide whether to honour that number or raise it honestly.

### Team recommendation (consensus)

Add an autonomous-mode branch to `cpm:do`'s Change Type Decision gate so ralph auto-takes inline edits and retro observations, amends the epic it is currently executing (so later stories inherit corrected criteria), and never invokes `/cpm:pivot` — deferring all upstream artefacts with a `**Pivot deferred**` breadcrumb. Guard: only *wrong* criteria may be amended, never merely *unmet* ones. Report amendments as their own block in the run summary, and change all four encoding sites together, the generated prompt included.

### Parked findings from the opening rounds

- **The execution log is a phantom.** `ralph/SKILL.md:74` globs `docs/plans/ralph-log-*.md`; `:50` logs stripped `[plan]` tags "for inclusion in the execution log"; `:260` calls it "the audit trail... the primary post-run artifact". Nothing in `cpm/` writes it. Chris has never broken or resumed a run, so resume is theoretical — cutting the reader and the README claims is the live option over building the writer. Not decided.
- **The completion promise exits by accident.** `cpm:ralph` does terminate (Chris confirmed). Mechanism: `stop-hook.sh:119`'s perl substitution fails to match when there are no `<promise>` tags, leaving `PROMISE_TEXT` as the whole last assistant message, which compares equal to `ALL_EPICS_COMPLETE` at `:123` because the prompt makes the final message that bare token. Brittle in one direction — any trailing prose (`Epic 26 complete. ALL_EPICS_COMPLETE`) fails the comparison and costs an extra iteration. Sable and Margot recommend emitting `<promise>ALL_EPICS_COMPLETE</promise>`; the Maintenance Coupling table (`:216-222`) already documents the tag path as the real contract. Not decided.
