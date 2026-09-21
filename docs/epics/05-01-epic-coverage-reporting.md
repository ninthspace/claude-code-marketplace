# Coverage reporting

**Number**: 05-01  
**Source spec**: 05  
**Status**: pending  

## Why this epic is shaped this way

The report and the requirement label sit in one epic although they land in different files, because they share a hazard rather than a module. Both are values a caller reads back, and neither is visible to any of the derived sweeps this suite carries: a new tool's registration cost has to be established by running each sweep's own reader against the intended change before a line of it is written, and a field computed after the read reaches neither the schema nor the tool registry, so no sweep can see it at all.

That second case is the sharper one and it is why the label story carries a task that looks like documentation. The only pressure on a derived response field is the skill sentence that consumes it. An answer of *no sweep covers this* is a finding to write down, not a relief.

The warnings depend on the report and could not start before it, which is the only internal ordering here. Everything else in this epic is independently schedulable.

## Story 1 — The coverage report for one spec

**Status**: pending  
**Blocked by**: Story 5, Story 2, Story 3  

### Acceptance Criteria

- Given a spec, the report returns every requirement with its standing, computed from the coverage rows bound to it. `[integration]`
- It returns, each as its own list, the criteria that are accounted for by nothing, the criteria carrying no approach tag, and the must-have criteria. `[integration]`
- It returns a block of counts, and every number in that block agrees with the list it summarises. `[unit]`
- The whole report is obtained in a single call, with no per-requirement page read behind it. `[integration]`

### Task 1 — Establish which derived sweeps read the tool registry

**Status**: pending  

Run each sweep's own reader against the intended tool before a line of it is written, and record the count. Addresses the registration cost, not the report's behaviour. A sweep that turns out to be silent on this surface is a finding to write down rather than a relief.

### Task 2 — Add the coverage-check module and register it

**Status**: pending  

The module and its registration only. Scope is the tool existing and being reachable, not what it computes.

### Task 3 — Compute each requirement's standing from its coverage rows

**Status**: pending  

Addresses the first criterion. The standing comes from the rows bound to the requirement and from nothing on the requirement itself.

### Task 4 — Assemble the three lists and the counts block

**Status**: pending  

Addresses the second and third criteria. The counts are derived from the lists in the same pass, so the two cannot disagree.

### Task 5 — Write tests for The coverage report for one spec

**Status**: pending  

Covers the criteria tagged integration and unit, including the single-call criterion, which is checked by counting the reads the call makes rather than by timing it.

## Story 2 — The epic roll-up

**Status**: pending  
**Blocked by**: Story 5  

### Acceptance Criteria

- Given a spec and an epic, the report adds a roll-up of that epic's stories, its bindings and its verified bindings. `[integration]`
- On a fixture whose bindings number thirteen, the roll-up says thirteen and agrees with the lists it summarises. `[unit]`

### Task 1 — Add the epic roll-up branch

**Status**: pending  

Addresses the roll-up criterion. Scope is the added branch when an epic is named; the spec-level report is Story 1's and is not changed here.

### Task 2 — Write tests for The epic roll-up

**Status**: pending  

Covers both criteria, with a fixture whose binding count is known and is not the count any earlier fixture uses.

## Story 3 — The three warnings

**Status**: pending  
**Blocked by**: Story 5  

### Acceptance Criteria

- A requirement whose every binding is verified and whose claim was never made is reported as claimable. `[integration]`
- An in-scope requirement that carries no acceptance criterion at all is reported, which is a state no gap computed from criteria can ever show. `[integration]`
- One criterion text, whitespace-normalised, live under two different stories is reported as duplicated. `[integration]`
- must NOT — One of the three new findings is reported as a gap rather than as a warning. `[integration]`
- control — An epic that closes cleanly before the warnings exist still closes with all three present and firing, so the refusal to call them gaps is shown to hold where it matters. `[integration]`

### Task 1 — Report a requirement whose bindings are all verified and whose claim is unmade

**Status**: pending  

Addresses the claimable warning. The condition is over the bound set and the claim stamp, and it is a warning in every case.

### Task 2 — Report an in-scope requirement carrying no acceptance criterion

**Status**: pending  

Addresses the second warning. This state can never surface as a gap, because a gap is computed from criteria and this requirement has none — which is why it needs its own detection rather than a widened gap rule.

### Task 3 — Report one criterion text live under two stories

**Status**: pending  

Addresses the third warning. Comparison is on whitespace-normalised text over live criteria only.

### Task 4 — Write tests for The three warnings

**Status**: pending  

Covers the three detections, the rejection that none of them is a gap, and its control — an epic that closes today closing with all three firing. The control is its own test with its own rows, not a line inside the rejection's.

## Story 4 — The requirement label on coverage rows

**Status**: pending  
**Blocked by**: Story 5  

### Acceptance Criteria

- A coverage row read back carries the label of the requirement it binds, so the read-back can be checked against a label rather than against an id held from an earlier call. `[integration]`
- The label is present on rows the coverage report returns as well as on rows read directly, and the skill text that quotes it names the field. `[integration]`

### Task 1 — Derive the requirement label on the coverage read path

**Status**: pending  

Addresses the first criterion. A read-side derivation, so it is not stored and there is no second place for it to arrive from.

### Task 2 — Name the label field in the skill text that reads it

**Status**: pending  

Addresses the second criterion, and it is the only pressure this field has. A value computed after the read reaches neither the schema nor the tool registry, so no derived sweep in this suite can see it — the skill sentence that consumes it is what holds it in place.

### Task 3 — Write tests for The requirement label on coverage rows

**Status**: pending  

Covers both criteria. The read-back assertion asks for the withheld column explicitly — a comparison written without it compares undefined against undefined and passes on the defect it was written to catch.

## Story 5 — Verify cross-story integration for Coverage reporting

**Status**: pending  
**Blocked by**: —  

### Acceptance Criteria

- The spec report and the epic roll-up return one response shape, so a skill quoting a count names one field whichever scope it asked for. `[integration]`
- The three warnings appear alongside the standings in the same response and change no standing that response computes. `[integration]`

### Task 1 — Write the cross-story integration tests for Coverage reporting

**Status**: pending  

Covers the two cross-story criteria: one response shape across both scopes, and the warnings coexisting with the standings without altering one.

## Dependencies

- blocks → 05-07
