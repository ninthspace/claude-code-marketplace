# Server-supplied stamps

**Number**: 05-03  
**Source spec**: 05  
**Status**: pending  

## Why this epic is shaped this way

One requirement, two stories, and it is kept apart from the other refusals for a reason that is about release mechanics rather than subject matter. This is the only argument-surface break in the spec, and a suite assertion couples it to skill text: every argument a run passes must be named in that skill's body inside a code span, and the assertion's word boundary means the old argument name does not satisfy a run passing the new one. So each story's code change and its skill-text change are two tasks of one story, and splitting them across commits leaves the suite red in between.

The failure being removed is the one with no error in it. A run supplied a verification time it had never read off a clock, and nothing downstream can tell that row from a real one — while verification time is exactly what the coverage matrix publishes as proof.

The claim story follows the stamp story rather than running beside it, so the second swap is made against a pattern already proved rather than inventing it twice.

## Story 1 — The coverage verification stamp takes a boolean

**Status**: pending  
**Blocked by**: —  

### Acceptance Criteria

- A verification call supplying no time records a stamp holding the server's clock at the moment of the call, with the binding hash derived alongside it exactly as it is today. `[integration]`
- must NOT — A call supplying a time for a verification is accepted and the supplied value is stored. `[integration]`
- control — The same call with the time omitted succeeds and stores a stamp, so the refusal is shown to discriminate rather than to reject every call of that shape. `[integration]`

### Task 1 — Swap the verify argument to a boolean and supply the clock

**Status**: pending  

A tool-boundary swap: the handler reads the clock where the caller used to pass one. The hash helpers are unchanged.

### Task 2 — Update the skill text naming the verify argument, in this same change

**Status**: pending  

A suite assertion requires every argument a run passes to be named in that skill's body inside a code span, and its word boundary means the old name does not satisfy a run passing the new one. Splitting this across two commits leaves the suite red in between.

### Task 3 — Write tests for The coverage verification stamp takes a boolean

**Status**: pending  

Covers the stamp, the rejection of a supplied time and its control. The stamp is asserted against a clock the test controls, not against a literal.

## Story 2 — The requirement coverage claim takes a boolean

**Status**: pending  
**Blocked by**: Story 1  

### Acceptance Criteria

- A claim call supplying no time records the claim with the server's clock, and the claim hash is computed over the bound set exactly as it is today. `[integration]`
- must NOT — A call supplying a time for a coverage claim is accepted and the supplied value is stored. `[integration]`
- control — The same call with the time omitted succeeds and records the claim. `[integration]`

### Task 1 — Swap the claim argument to a boolean and supply the clock

**Status**: pending  

The same swap on the requirement side. The claim hash goes on being computed over the bound set, which was never the caller's to supply.

### Task 2 — Update the skill text naming the claim argument, in this same change

**Status**: pending  

Same coupling as Story 1's second task, on the skills that make a claim.

### Task 3 — Write tests for The requirement coverage claim takes a boolean

**Status**: pending  

Covers the claim, the rejection of a supplied time and its control.

## Dependencies

- blocks → 05-04
- blocks → 05-07
