# The skills

**Number**: 04-05  
**Source spec**: 04  
**Status**: complete  

## Story 1 — The pivot names and gates the bindings it broke

**Status**: complete  
**Blocked by**: —  

### Acceptance Criteria

- A pivot run amending a requirement's text names every binding whose fragment the amended text no longer contains, and names no others. `[feature]`
- Each named binding is offered under its own approval: a run that approves one of two retires that one. `[feature]`
- must NOT — The pivot does not retire a binding the run did not approve. `[feature]`
- must NOT — The pivot does not recover the bindings by reading a generated markdown file instead of calling the list tool. `[unit]`
- control — A run amending a requirement whose bound fragments all survive names no binding and offers no retirement, so naming nothing is the amendment rather than a step that never ran. `[feature]`

### Task 1 — Add the retirement step to dpm:pivot

**Status**: complete  

The skill calls list_coverage, performs the substring comparison itself, and calls retire_coverage once per approval. Addresses the skill-and-tools boundary: the server never scans for broken bindings and the skill never writes a column, which is what keeps the gate meaningful.

### Task 2 — Write tests for The pivot names and gates the bindings it broke

**Status**: complete  

Follows the existing pivot suite, driving a run and approving one proposal of two so a batched retirement would land both. The all-fragments-survive control separates an amendment that broke nothing from a step that never ran.

### Retro

- The batching mutation control split a test that should never have been one. Criteria 2 and 3 were written into a single test — "one of two is approved" followed by "the other is not retired" — and when the driver was mutated to retire every broken binding, the test failed on criterion 2's count assertion and never reached criterion 3's. So criterion 3, a must-NOT, had no evidence of its own: it was a line inside a test that a different criterion had already failed. Splitting it into a test that reads the refused row *first*, with the approved sibling asserted afterwards purely as the control, made both go red independently under the same mutation.

The general shape: a must-NOT sharing a test with the positive it is the complement of is only verified when the mutation happens to fail the must-NOT's assertion first. Assertion order inside a test is load-bearing evidence, and the cheap way to stop depending on it is to give the rejection its own test with its own control row.

## Story 2 — The breakdown steers a fragment to the obligation clause

**Status**: complete  
**Blocked by**: —  

### Acceptance Criteria

- The breakdown skill's coverage step instructs that a fragment be quoted from the clause carrying the obligation, and says why connective phrasing is the fragment an amendment breaks. `[unit]`
- A breakdown run over a requirement whose obligation and connective wording are separable binds the obligation clause. `[feature]`
- must NOT — That instruction must not weaken the existing refusal of a fragment traceable to no spec text. `[unit]`

### Task 1 — Write the fragment guidance into dpm:epics Step 3d

**Status**: complete  

Adds the steer toward the obligation clause and the reason for it. Scoped to adding guidance: the existing refusal of an untraceable fragment stands unchanged.

### Task 2 — Write tests for The breakdown steers a fragment to the obligation clause

**Status**: complete  

Covers the two unit criteria over the skill file and the driven run over a requirement whose obligation and connective wording are separable.

### Retro

- Inserting a requirement into the middle of a shared fixture array silently re-aimed a criterion that indexed by position. `skill-epics.test.js` builds its acceptance criteria as `{ requirement: requirements[2], ... }`, so adding FR3 before ENV1 moved ENV1's "the suite runs from one command" onto FR3 — and the whole suite stayed green, because nothing asserts which requirement that criterion hangs off. The fixture was internally consistent and semantically wrong, and no test could tell.

Moving the new requirement to the end of the array fixed it, but the general lesson is the ordering: a fixture that indexes a shared array by position is only extensible at the tail, and nothing enforces that. The cheap fix when adding to one is to append, and the durable one is to look up by label the way the run itself does (`requirements.find((row) => row.label === 'FR1')`) — which the run already does and the fixture, three functions earlier, does not.

## Story 3 — The roll-up counts what remains

**Status**: complete  
**Blocked by**: —  

### Acceptance Criteria

- The execution roll-up's sentence names the remaining bindings rather than implying every binding ever made was verified. `[unit]`
- must NOT — The roll-up must not report a count that includes retired bindings. `[integration]`

### Task 1 — Reword dpm:do's roll-up to name the remaining bindings

**Status**: complete  

The sentence describes the set that is left rather than every binding ever made. Addresses the wording, not the count.

### Task 2 — Give dpm:do warrant awareness

**Status**: complete — Already delivered by epic 04-03 story 3, which wrote the accounted_for paragraph into Step 8 — no change was needed here. Verified present in skills/do/SKILL.md before closing.  

The skill reads a warranted criterion as accounted for rather than as an unbound gap. The behaviour itself is measured in epic 3; this is the skill text that reaches it.

### Task 3 — Write tests for The roll-up counts what remains

**Status**: complete  

Covers the wording criterion over the skill file and the count criterion over a requirement holding a retired binding.

### Retro

- Task 2 of this story was already done, and finding that out took one grep. "Give dpm:do warrant awareness" was written into the breakdown for epic 04-05, but epic 04-03 story 3 had already put the `accounted_for` paragraph into Step 8 while delivering its own criteria — the two epics were shaped from the same spec at the same time, and neither breakdown could see what the other would land.

Worth recording because the loop's instinct at that point is to write the paragraph again, and a second copy of a rule in one step is worse than the duplicate task: the two would drift and nothing would notice. Reading the target step before implementing the task is the cheap guard, and closing the task with a `status_note` naming where the work actually landed is what stops the next reader concluding it was skipped.

The version skew also lifted somewhere between epics — `update_task` accepted `status_note` this run, having refused it on 04-04.2. Worth re-testing the other blocked calls rather than carrying the assumption forward.

## Dependencies

- blocks → 04-06

## Retro Applied

- 06 · codebase-discoveries · applied — The new pivot prose carries include_body wherever it names a withholding tool, and each site is registered in tests/support/body-reads.js as part of the story rather than repaired after the sweep fires.
- 07 · criteria-gaps · applied — Story 1's two must-NOTs get planted mutations — batch the approvals, and recover a binding from a rendered file — each watched failing before being removed, and each checked for whether it leans on a neighbouring criterion for its discrimination.
- 05 · patterns-worth-reusing · applied — Any forbidden pattern this epic plants as a control — a rendered-file read, a matrix path — is assembled from parts rather than written literally, so the corpus sweeps that read the suite's own sources stay clean without an exemption.
- 05 · testing-gaps · applied — The retirement step belongs to dpm:pivot alone, so its assertions name that skill rather than sweeping every SKILL.md for a retire_coverage mention — a sweep would put a skill added later silently in scope.
