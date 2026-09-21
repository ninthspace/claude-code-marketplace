# Repair verbs

**Number**: 05-05  
**Source spec**: 05  
**Status**: pending  

## Why this epic is shaped this way

Three verbs, three stories, no integration story: they touch different tables, share no state, and a fourth story asserting that none reaches another's rows would be asserting a fact the schema already carries.

Each answers a specific mistake a run made and could not undo. Two of them retire and one deletes, and the difference is deliberate. An observation written twice can be withdrawn and left readable, because the historical question — what did this retro hear? — is one somebody asks. A dependency edge written the wrong way round has to be *removed*: a retired edge that still constrained the graph would leave the recovery it exists for impossible, since the correct edge would close a cycle over the wrong one.

The binding deletion needs a delete-by-key on the shared write helper, because the row has a composite key rather than an id. That is the only piece of shared machinery this epic touches.

## Story 1 — Retire an observation

**Status**: pending  
**Blocked by**: —  

### Acceptance Criteria

- An observation written twice can be withdrawn, and the withdrawn row stops appearing in the lists that gather observations. `[integration]`
- control — A live observation under the same retro is unaffected by its sibling's withdrawal and goes on being returned. `[integration]`

### Task 1 — Add the observation retirement verb

**Status**: pending  

Modelled on the coverage retirement that already exists, including the reason it requires. Scope is the verb; the lists that gather observations already omit retired rows.

### Task 2 — Write tests for Retire an observation

**Status**: pending  

Covers the withdrawal and the control that a live sibling goes on being returned, so the test cannot pass against a list that returns nothing.

## Story 2 — Delete a dependency

**Status**: pending  
**Blocked by**: —  

### Acceptance Criteria

- A dependency edge written the wrong way round can be removed, and the correct edge can then be written without the first closing a cycle over it. `[integration]`
- control — Removing one edge leaves every other edge of that kind in place and readable. `[integration]`

### Task 1 — Add the dependency deletion verb

**Status**: pending  

Deletion rather than retirement, because an edge written the wrong way round has to stop constraining the graph — a retired edge that still closed a cycle would leave the recovery it exists for impossible.

### Task 2 — Write tests for Delete a dependency

**Status**: pending  

Covers removing a reversed edge and then writing the correct one, plus the control that other edges survive. Drives the actual recovery rather than asserting the row is gone.

## Story 3 — Delete a coverage-story binding

**Status**: pending  
**Blocked by**: —  

### Acceptance Criteria

- A binding attached to the wrong story can be removed, and the count at the place that reads bindings falls by exactly one. `[integration]`
- control — The coverage row itself and its bindings to other stories survive the removal unchanged. `[integration]`

### Task 1 — Add the delete-by-key for a coverage-story binding

**Status**: pending  

The binding has a composite key rather than an id, so this needs a delete-by-key on the shared write helper. Scope is that helper and the one verb using it.

### Task 2 — Write tests for Delete a coverage-story binding

**Status**: pending  

Covers the removal and the count falling by exactly one, plus the control that the coverage row and its other bindings survive.

## Dependencies

- blocks → 05-04
- blocks → 05-07
