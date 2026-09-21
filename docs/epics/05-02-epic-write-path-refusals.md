# Write-path refusals

**Number**: 05-02  
**Source spec**: 05  
**Status**: pending  

## Why this epic is shaped this way

Seven guards that have nothing in common except their shape: a write that is legal today, produces no error, and records something nobody decided. They are grouped because the property that binds them is a single one — no stored row changes how it reads — and that property is only checkable across the whole set, which is what the closing story exists for.

**Every rejection here is transcribed from the spec's own must-nots.** None was proposed by this breakdown. A rejection invented in the moment can be unsatisfiable as written, and leaves a story nobody can close.

Two orderings are real. The story that adds the closing hook to the delivery factory blocks the one that adds a second condition to it, because the second has nothing to hang on until the first lands. And all five implementation stories block the closing story, whose subject is the set rather than any member of it.

**The fixtures this epic breaks were always wrong.** A fixture that closes a story over outstanding work is asserting the behaviour the epic exists to stop; a fixture holding a ruled-out requirement with no exclusion was incomplete before the refusal existed. Both are fixed rather than the rules softened, and the exclusion case takes an added test pinning that a stored row in that state still reads as excluded — so the change is proved not to reopen settled exclusions.

## Story 1 — Refuse a fragment that is nowhere in its requirement

**Status**: pending  
**Blocked by**: —  

### Acceptance Criteria

- control — A coverage write whose fragment does occur in the text of the requirement it names succeeds and stores a row. `[integration]`
- must NOT — A coverage write whose fragment occurs nowhere in the text of the requirement it names is accepted, leaving a row for the integrity register to find later. `[integration]`
- Where a sibling requirement in the same spec does contain the fragment, the refusal names that requirement as the one the fragment belongs to. `[integration]`

### Task 1 — Move the register's substring test onto the create path

**Status**: pending  

The test already exists in SQL in the integrity register. Scope is running it at write time; the register keeps its own copy for what a restore brings in.

### Task 2 — Name the sibling requirement in the refusal

**Status**: pending  

Addresses the third criterion. Searches the same spec for a requirement whose text does contain the fragment, and names it; where none does, the refusal says only that the fragment is unfound.

### Task 3 — Write tests for Refuse a fragment that is nowhere in its requirement

**Status**: pending  

Covers the rejection, its control and the sibling-naming criterion, with the rejection driven on its own rows so it can fail without depending on the control's assertion order.

## Story 2 — Refuse a story close over outstanding tasks

**Status**: pending  
**Blocked by**: —  

### Acceptance Criteria

- must NOT — A story with a task still outstanding beneath it is set finished. `[integration]`
- The refusal lists every outstanding task beneath that story, so it performs the reconciliation rather than asking for one. `[integration]`
- control — The same story with every task beneath it finished is set finished without objection. `[integration]`
- control — A task is set finished exactly as it is today, the closing hook being one that a task passes none of. `[integration]`

### Task 1 — Add the optional closing hook to the delivery update factory

**Status**: pending  

The seam only: a hook asked for when a call sets the finished status, receiving the resolved row. A table that passes none behaves exactly as it does today, and that is the contract the task path asserts.

### Task 2 — Give the story its outstanding-task condition

**Status**: pending  

Addresses the first two criteria. The condition names every outstanding task in the refusal; the task table passes no hook and is untouched.

### Task 3 — Write tests for Refuse a story close over outstanding tasks

**Status**: pending  

Covers the rejection and both controls, the second being the task path proved unchanged. Existing fixtures that close a story over outstanding work are fixed rather than the rule softened — they assert the behaviour this story removes.

## Story 3 — Require a note when a story closes over an unverified binding

**Status**: pending  
**Blocked by**: Story 2  

### Acceptance Criteria

- must NOT — A story carrying an unverified bound coverage row and no status note is set finished. `[integration]`
- control — The same story with a status note is set finished, so the unverified binding is shown not to be what was refused. `[integration]`
- A status note already stored on the row satisfies the condition without being restated in the closing call, and a note of whitespace alone does not satisfy it. `[integration]`

### Task 1 — Add the unverified-binding condition to the story's closing hook

**Status**: pending  

Addresses all three criteria. It refuses the missing note, never the unverified binding, and reads a note already on the row rather than requiring the closing call to carry one.

### Task 2 — Write tests for Require a note when a story closes over an unverified binding

**Status**: pending  

Covers the rejection, its control and the stored-note case, including a note of whitespace alone failing to satisfy it.

## Story 4 — Refuse a ruled-out requirement with no exclusion

**Status**: pending  
**Blocked by**: —  

### Acceptance Criteria

- must NOT — A create or an update that would leave a requirement ruled out with no exclusion recorded is accepted. `[integration]`
- control — The same call carrying an exclusion succeeds, and a requirement at any other priority with no exclusion succeeds too. `[integration]`
- An update naming only the priority is judged against the exclusion already stored on the row rather than against the absence of one in its own arguments. `[integration]`

### Task 1 — Guard the create handler

**Status**: pending  

Addresses the rejection on the create path, naming the field that is missing.

### Task 2 — Guard the update handler against the resolved row

**Status**: pending  

Addresses the third criterion. The judgement is on the state the edit would leave, not on the arguments the call carries, so a row already recording its reason is not refused for failing to repeat it.

### Task 3 — Give the existing fixtures their exclusion

**Status**: pending  

Any fixture holding a ruled-out requirement with no exclusion becomes invalid when the refusal exists. It was always incomplete; add a test pinning that a stored row in that state still reads as excluded, so the change is proved not to reopen settled exclusions.

### Task 4 — Write tests for Refuse a ruled-out requirement with no exclusion

**Status**: pending  

Covers the rejection, its control including the other three priorities, and the update judged against the stored row.

## Story 5 — Three guards on unrelated writes

**Status**: pending  
**Blocked by**: —  

### Acceptance Criteria

- must NOT — A tradeoff naming an option the decision does not hold is accepted. `[integration]`
- The refusal lists the options the decision actually holds, so the caller is handed the real set rather than told the one it named is wrong. `[integration]`
- must NOT — A second live acceptance criterion with the same text under one story is accepted. `[integration]`
- must NOT — A binding attaching a coverage row to a story in a different epic is accepted. `[integration]`
- control — Each of the three guards admits its legitimate neighbour: a tradeoff on an option the decision holds, a criterion whose text differs from its siblings, and a binding to a story within the same epic. `[integration]`

### Task 1 — Guard a tradeoff against an option the decision does not hold

**Status**: pending  

Addresses the first two criteria. The refusal lists the decision's real options, which is where an invented option id is caught.

### Task 2 — Guard a duplicate live criterion under one story

**Status**: pending  

Addresses the third criterion, naming the twin's position. Live criteria only — a superseded one with the same text is not a duplicate.

### Task 3 — Guard a binding across epics

**Status**: pending  

Addresses the fourth criterion, naming both epics in the refusal.

### Task 4 — Write tests for Three guards on unrelated writes

**Status**: pending  

Covers the three rejections and the control that each admits its legitimate neighbour. Each rejection is driven on its own rows, so no one of the three can pass because another failed first.

## Story 6 — Verify cross-story integration for Write-path refusals

**Status**: pending  
**Blocked by**: Story 1, Story 2, Story 3, Story 4, Story 5  

### Acceptance Criteria

- For each refusal this epic adds, a row written into the now-refused state before the change reads identically through every tool after it — same columns, same values, same standing in any report that mentions it. `[integration]`
- Each refusal is shown able to fail: the state it forbids is driven, and the test guarding it goes red on its own rather than behind a sibling assertion. `[integration]`

### Task 1 — Write the cross-story integration tests for Write-path refusals

**Status**: pending  

Covers both criteria: every stored row in a now-refused state reading unchanged, and every refusal proved able to fail. The read-back comparisons ask for withheld columns explicitly — a comparison written without that compares undefined against undefined and passes on the exact defect it was written to catch, which has cost this project two red runs.

## Dependencies

- blocks → 05-04
- blocks → 05-07
