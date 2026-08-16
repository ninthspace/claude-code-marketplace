# Discussion: Report disposition labels — making fixed vs. action-required unambiguous

**Date**: 2026-08-16  
**Agents**: Bella (Senior Developer)

## Discussion Highlights

### Key points so far

- Chris's problem: agents spot deficiencies, fix them, and report in a way that leaves it unclear whether the thing is fixed or still needs his action. Actions must be actionable; everything else is noise.
- Chris has **not** seen this in DPM; it happens a lot in **CPM**. Fix both, **DPM first** — that is what he intends to use going forward.
- Diagnosis: a missing *disposition vocabulary*, not a length problem. `dpm/shared/skill-conventions.md` has **Conversational Output** (cadence, length) and **Written Deliverable Length**, but nothing governing the state of a reported item.
- Structural reason DPM is less exposed: disposition is a column there (`met` tri-state, `verified_at`, `remediation_task_id`, change-moment resolution) and must be decided before the row is written. CPM composes prose, so disposition is whatever the sentence implies. DPM's residual gap is the *conversation*, which is prose in both. The DPM work is therefore preventive, not corrective.
- **All 21 DPM skills already reference Conversational Output** — so the baseline rule costs one new subsection in `dpm/shared/skill-conventions.md` and zero per-skill edits.
- Precedent already in DPM: `do`'s autonomous mode requires the applied and deferred retro sets be "surfaced separately" in the Step 8 summary. The disposition rule already exists, applied once.

### Decisions

1. **Four labels, and Unverified stays.** Chris chose to keep it as its own label rather than fold it into Needs you.
   - **Fixed** — repo is different; reader does nothing.
   - **Needs you** — an action only Chris can take, stated as an imperative.
   - **Left alone** — deliberately not fixed, with the reason.
   - **Unverified** — done but not proven (`do` Step 5 `target` criteria, a must-NOT with no control).
2. **The label is what the reader must do, not what the agent did.** Fixed-but-worth-a-look is **Fixed** with a note, never **Needs you**. Without this rule the Needs-you category rots within a week.
3. **Anything fitting none of the four is not reported** — the noise clause. "I considered doing X and didn't" is a diary entry, not a disposition.
4. **Actions go last, together, as imperatives**, so the reader can stop after the first block having missed nothing actionable.
5. **Unverified means the check is impossible in this environment, and why.** Not "I ran out of road." The two clean structural cases are a `target` criterion (a verdict from this machine is worth nothing) and a must-NOT with no control (absence asserted rather than shown) — no extra effort in that run turns either into Fixed. Where the reason is about the agent rather than the environment, it is **Needs you**. This mirrors `do`'s existing line on change moments: *the tests fail*, *I could not implement it*, *this was harder than expected* are reports about the run, not about the criterion. Without the guard, Unverified becomes the polite word for unfinished.

### Proposed change, two separable parts

- **One convention section** in `dpm/shared/skill-conventions.md` carrying the four labels and the rules above. Reaches all 21 skills via references they already carry.
- **Five site rules** where the disposition is already a row, making the report a *projection of those rows* rather than narration beside them: `do` Step 8 + change moments, `quick` Step 4 tri-state `met`, `review` findings→remediation tasks, `pivot` Phase 4 affected tasks, `audit` findings. This half has teeth — it fails loudly on drift, where a prose convention cannot.
- CPM gets the same treatment afterwards, as separate work.

### Sizing — why spec rather than quick

Every DPM skill carries its own prose-asserting suite (`tests/skill-do.test.js`, `skill-quick`, `skill-review`, `skill-pivot`, `skill-audit`), plus `skills-corpus` and `skills-authoring` over the shared file. The change is roughly six source files and seven suites. The assertions are where it is most likely to be got wrong: a test that pins the four label names passes happily while a skill still narrates its summary freely.

A smaller version exists — the convention section alone, one file and one suite, reaching all 21 skills. It is a real improvement but it is the half without teeth, and shipping it alone risks reading as done. The five site rules are the point.

**Chris chose `/cpm:spec`** for the whole thing (CPM remains the pipeline in use in this repo, even though the change targets `dpm/`).
