# Neighbour version skew

**Number**: 01-01  
**Source spec**: 01  
**Status**: pending — Ships on its own — no schema change, no migration. Builds the verdict shape and the report channel that the stamp then extends.  

## Story 1 — Test scaffolding for a plugin cache layout

**Status**: pending  
**Blocked by**: Story 2, Story 7  

### Acceptance Criteria

- A constructed directory of sibling version directories exists in the suite, and the check reports a verdict against it. `[unit]`
- A test creates a temporary location, writes into it, and asserts it is gone afterwards. `[unit]`
- The running Node satisfies `REQUIRED_NODE`, and `engines.node` equals it. `[unit]`
- The test script invokes only the built-in runner, with no binary resolved from `node_modules`. `[unit]`

### Task 1 — Build a helper that constructs a temporary directory of sibling version directories

**Status**: pending  

The stand-in the neighbour check is pointed at. Addresses the fixture itself, not the check that reads it — and exists so that no test reaches the real plugin cache.

### Task 2 — Build a helper that creates and removes a temporary location

**Status**: pending  

Covers removal on failure as well as on success. A helper that only cleans up on the happy path leaves the next run reading the previous one's directory.

### Task 3 — Assert the project's standing environmental constraints

**Status**: pending  

The Node floor matching `engines.node`, and the test script invoking only the built-in runner. Addresses the assertions, not the constraints — both already hold and the point is that they keep holding.

### Task 4 — Write tests for the scaffolding helpers

**Status**: pending  

Covers the four criteria tagged `unit`. The helpers are themselves test machinery, so they need cover of their own — a fixture builder that silently builds nothing would make every test above it pass for the wrong reason.

## Story 2 — Resolve the running plugin's version and its neighbours

**Status**: pending  
**Blocked by**: Story 3, Story 7  

### Acceptance Criteria

- Resolving from the module's own URL names the directory the module was loaded from. `[unit]`
- The resolver reads no value from `process.env`. `[unit]`
- The check reads only the path it was given. `[unit]`
- The check performs exactly one directory read per invocation. `[unit]`
- No path this spec adds makes an outbound call. `[unit]`
- After a report, the filesystem beneath and beside the plugin root is unchanged. `[integration]`
- must NOT — The check recurses into subdirectories. `[unit]`
- must NOT — The check spawns a process or opens a socket. `[unit]`
- must NOT — The check creates a file or directory anywhere. `[integration]`
- must NOT — Any path a test resolves runs through the user's home directory. `[unit]`

### Task 1 — Resolve the running plugin's directory from the module's own URL

**Status**: pending  

Takes nothing from the process environment. Respects the decision that the host expands its plugin-root placeholder into launch arguments and does not guarantee it as a variable.

### Task 2 — Read the sibling directories, taking the root and the reader as parameters

**Status**: pending  

One read, no recursion, nothing written. The reader is a parameter so the read can be counted and so the path read is the path given — which is what makes the bounded-cost and no-home-directory criteria checkable at all.

### Task 3 — Write tests for resolving the version and its neighbours

**Status**: pending  

Covers the ten criteria tagged `unit` and `integration`, including the four rejections — recursion, process or socket, any write, and any path through the home directory.

## Story 3 — Compare versions and produce a three-state verdict

**Status**: pending  
**Blocked by**: Story 4, Story 5, Story 7  

### Acceptance Criteria

- Given a root holding the running version and a higher-numbered sibling, the check reports a skew naming the higher version. `[unit]`
- Given a root whose siblings are all lower than or equal to the running version, the check reports no skew. `[unit]`
- Given a root whose name does not parse as a version, the check reports could-not-check. `[unit]`
- Given a root with no sibling directories at all, the check reports could-not-check rather than no skew. `[unit]`
- The three states — skew found, no skew, could not check — are distinguishable without parsing message text. `[unit]`
- `dependencies` and `devDependencies` are both empty. `[unit]`
- must NOT — The check reports a skew for a sibling lower than the running version. A reversed comparison satisfies the first criterion on any machine with more than one version installed, so the first criterion alone does not pin the direction. `[unit]`
- must NOT — The check throws for an unreadable or unparseable root. `[unit]`
- must NOT — A check that could not run renders as no skew. `[unit]`

### Task 1 — Compare sibling names as versions using the existing parser

**Status**: pending  

Addresses the direction of the comparison and the unparseable path. Reuses the parser the Node floor check already carries rather than adding a dependency for it.

### Task 2 — Define the three-state verdict

**Status**: pending  

Skew found, no skew, could not check — distinguishable from the value rather than from its message text, so that a reader branching on the state never has to parse prose.

### Task 3 — Write tests for the comparison and the verdict

**Status**: pending  

Covers the nine criteria tagged `unit`, including the rejection of a skew reported for a lower sibling — the case a reversed comparison would otherwise pass.

## Story 4 — Re-evaluate on every report

**Status**: pending  
**Blocked by**: Story 7  

### Acceptance Criteria

- Two consecutive reports against a root that gained a higher sibling between them return different verdicts. `[integration]`
- control — With the check deliberately memoised, the two-consecutive-reports criterion fails, and the failure has been observed and read rather than assumed. `[integration]`

### Task 1 — Evaluate the check at report time rather than at start

**Status**: pending  

Addresses the wiring, not the check. Nothing computed at module load or server start may be reused, because the upgrade this exists to catch lands after both.

### Task 2 — Write tests for re-evaluation on every report

**Status**: pending  

Covers both criteria tagged `integration`. The control is run rather than reasoned about: memoise the check, watch the two-report test fail, and read why before reverting.

## Story 5 — Report the verdict on check_integrity

**Status**: pending  
**Blocked by**: Story 7  

### Acceptance Criteria

- The skew field is present in the response when no skew was found. `[unit]`
- A reported skew contains the running version, the newer version found, and a remedy naming a session restart. `[unit]`
- A directory read that throws produces could-not-check and a successful tool response. `[integration]`
- must NOT — The skew sentence is composed in more than one place. `[unit]`
- must NOT — An error from the check propagates out of the tool handler. `[integration]`
- must NOT — A version skew changes `ok`. The report's `ok` states that the database is internally consistent, and under a skew it still is — the rows are sound and the reader is stale. `[unit]`
- must NOT — A version skew appears in `entries`. That list is derived from the register and held to it by a parity test; a skew there is either a fabricated register entry or a broken derivation. `[unit]`
- control — With the error handling removed, the criterion that a throwing read produces could-not-check fails, and that failure has been observed and read rather than assumed. `[integration]`

### Task 1 — Add the skew field to the integrity response

**Status**: pending  

Beside `entries` and `orphans`, never inside either. Respects the decision that `ok` keeps meaning the data is sound and that the entries list stays derived from the register.

### Task 2 — Compose the skew sentence in one place

**Status**: pending  

One producer, used by every channel that reports a skew. Addresses the wording, not the detection — two channels and two detectors is four chances for the sentence to be written four times and drift.

### Task 3 — Contain failures inside the check

**Status**: pending  

Addresses the error path, not the happy path. A read that throws becomes could-not-check and a successful response; nothing from the check reaches the caller as an error.

### Task 4 — Write tests for reporting the verdict on check_integrity

**Status**: pending  

Covers the eight criteria, including the two rejections that hold the report's shape and the control on error handling — which is run and its failure read, not assumed.

## Story 6 — Record the plugin-cache coupling

**Status**: pending  
**Blocked by**: Story 7  

### Acceptance Criteria

- The maintenance record documents the assumed plugin cache layout and what breaks if the host changes it. `[manual]`
- must NOT — Any file under the skills directory names the maintenance record's path. `[unit]`

### Task 1 — Write the maintenance record for the plugin-cache coupling

**Status**: pending  

What layout is assumed, and what breaks if the host changes it. The coupling is to something we do not own, so the record is the only place it is stated deliberately rather than implied by code.

### Task 2 — Write the test that no skill file names the maintenance record's path

**Status**: pending  

Covers the criterion tagged `unit`. The record's content is judged by reading it; what a test can hold is that no skill pays for a pointer to it on every invocation.

## Story 7 — Verify cross-story integration for Neighbour version skew

**Status**: pending  
**Blocked by**: —  

### Acceptance Criteria

- A `check_integrity` call against a constructed root holding a higher sibling returns a skew field naming both versions, with `ok` still true. `[integration]`
- A `check_integrity` call against a root that is not a version directory returns could-not-check, with `ok` still true. `[integration]`

### Task 1 — Write the end-to-end tests for neighbour skew reporting

**Status**: pending  

A real tool call against a real constructed cache, covering the whole path the per-story tests only cover a link of. Both criteria name the state of `ok`, which is what shows the report's separation holding end to end rather than only in the unit test written against the same assumption.

## Dependencies

- blocks → 01-02
