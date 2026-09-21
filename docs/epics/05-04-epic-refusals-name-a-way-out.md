# Refusals that name a way out

**Number**: 05-04  
**Source spec**: 05  
**Status**: pending  

## Why this epic is shaped this way

Four improvements to what a refusal says, and one audit over every refusal the whole spec adds. The audit is why this epic waits on three others: a sweep asserting that every refusal names a route cannot run until the refusals exist.

The scope-id story is the one that needs designing first, and it is larger than it looks. Refusing an id that matches no row means probing it, and probing it means knowing which table the scope points at — a fact the list registry does not currently hold. Deriving it from the schema's foreign keys was considered and rejected: a foreign key names a table and the registry names a list, and the mapping back is not one-to-one, so a derived answer could say which table the id belongs to but not which list would accept it. Naming the list is most of the value, because the incident behind this was a run that read an empty page as a failed write and re-wrote ten tags.

The cost of declaring it rather than deriving it is a second place to keep in step, and the story carries a task that pins the registry against the schema so the two cannot drift silently.

The unaccepted-argument story has evidence from this project's own planning run: the spec above had its first eight writes refused for a missing field, and was told only that the parameters were invalid.

## Story 1 — Name the column and table in a foreign-key failure

**Status**: pending  
**Blocked by**: —  

### Acceptance Criteria

- A write that misses a parent row returns a message naming the column whose value missed and the table that column points at, for a call carrying several ids. `[integration]`
- control — A write whose parent rows all exist succeeds unchanged, so the added handling is shown not to intercept a healthy call. `[integration]`

### Task 1 — Derive the column and its parent table from the constraint failure

**Status**: pending  

Addresses the first criterion. The handler already catches the failure and passes the bare message through; the scope here is deriving which of a call's ids missed.

### Task 2 — Write tests for Name the column and table in a foreign-key failure

**Status**: pending  

Covers the message on a call carrying several ids, and the control that a healthy write is untouched.

## Story 2 — Refuse a scope id that names no row

**Status**: pending  
**Blocked by**: —  

### Acceptance Criteria

- must NOT — A list given a scope id that matches no row returns an empty page. `[integration]`
- control — A list given a scope id naming a real row that holds nothing still returns an empty page, so a scope that is genuinely empty is shown to be distinguishable from one that does not exist. `[integration]`
- Where the id belongs to a different table, the refusal names that table and names the list that takes the id as a scope. `[integration]`
- Every scope in the list registry declares the table it points at, and a declaration that disagrees with the schema is caught by a test rather than by a caller. `[integration]`

### Task 1 — Declare each scope's parent table in the list registry

**Status**: pending  

The declaration only. Every scoped list gains the table its scope points at, which is what lets the refusal name both the table and the list that takes the id.

### Task 2 — Probe the scope id and refuse when it matches nothing

**Status**: pending  

Addresses the rejection and its control. A scope naming a real but empty parent must go on returning an empty page, which is the distinction the whole story exists to draw.

### Task 3 — Name the other table and the list that takes the id

**Status**: pending  

Addresses the third criterion. This is the sentence the incident needed: a run read an empty page as a failed write and re-wrote ten tags.

### Task 4 — Pin the registry declarations against the schema

**Status**: pending  

Addresses the fourth criterion. Nothing derives the declaration from the schema, which is the cost the decision accepted; this test is what stops the two drifting silently.

### Task 5 — Write tests for Refuse a scope id that names no row

**Status**: pending  

Covers the rejection, its control, the refusal's contents and the registry-against-schema check.

## Story 3 — Offer a unique-prefix match

**Status**: pending  
**Blocked by**: —  

### Acceptance Criteria

- Where an id matches no row but is an unambiguous prefix of exactly one, the refusal offers that row. `[integration]`
- must NOT — An id that is a prefix of two or more rows has one of them offered. `[integration]`
- control — A full id that matches a row is resolved exactly as it is today, with no prefix search behind it. `[integration]`

### Task 1 — Add unique-prefix resolution to the refusal path

**Status**: pending  

Addresses all three criteria. The search runs only after an exact match has failed, so a full id never pays for it, and an ambiguous prefix offers nothing rather than guessing.

### Task 2 — Write tests for Offer a unique-prefix match

**Status**: pending  

Covers the suggestion, the rejection of an ambiguous prefix and the control that a full id resolves as before.

## Story 4 — Name the arguments a tool accepts

**Status**: pending  
**Blocked by**: —  

### Acceptance Criteria

- A refusal for an argument a tool does not accept names the arguments it does accept. `[integration]`
- A refusal for a missing required argument names which argument is missing. `[integration]`
- control — A call carrying only valid arguments succeeds unchanged. `[integration]`

### Task 1 — Name the accepted arguments in the schema rejection

**Status**: pending  

Addresses the first criterion. The rejection currently says only that a property is not allowed, which leaves the caller nothing to correct towards.

### Task 2 — Name the missing required argument

**Status**: pending  

Addresses the second criterion. This spec's own first eight writes were refused for a missing label and told only that the parameters were invalid.

### Task 3 — Write tests for Name the arguments a tool accepts

**Status**: pending  

Covers both messages and the control that a valid call is unchanged.

## Story 5 — Verify cross-story integration for Refusals that name a way out

**Status**: pending  
**Blocked by**: Story 1, Story 2, Story 3, Story 4  

### Acceptance Criteria

- Every refusal this spec adds names a requirement, a table, a list, an option or an argument that the caller can act on, and not only the fault that was found. `[unit]`
- control — A refusal message reduced to naming only the fault makes that sweep fail, so the sweep is shown to be reading the messages rather than passing over them. `[unit]`

### Task 1 — Write the sweep over every refusal message this spec adds

**Status**: pending  

Covers both criteria. The sweep is then broken deliberately — one message reduced to naming only the fault — and confirmed to fail, because a contract test that cannot fail is the most confident kind of nothing.

## Dependencies

- blocks → 05-07
