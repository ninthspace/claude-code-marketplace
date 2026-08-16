# Neighbour version skew

**Number**: 01-01  
**Source spec**: 01  
**Status**: complete — Ships on its own — no schema change, no migration. Builds the verdict shape and the report channel that the stamp then extends.  

## Amendment: story 1's fixture criterion no longer waits on story 3

Story 1's first criterion read "A constructed directory of sibling version directories exists in the suite, **and the check reports a verdict against it**". The second clause names an artefact story 1 cannot have.

**The citation is the edges, not the difficulty.** Story 1 blocks story 2, which blocks story 3, and story 3 is where the verdict is built. A criterion on the story that must run first cannot be satisfied by the output of a story that cannot start until it completes. The two are not simultaneously satisfiable in the order the epic itself fixes.

It is also already covered where it belongs: story 3's criteria exercise the verdict against this same fixture in all three states — a higher sibling yielding a skew, all-lower yielding none, and an unparseable root yielding could-not-check. Leaving the clause on story 1 would have made the same claim twice, once in the story that can prove it and once in the story that cannot.

The second clause now reads "and a test reads its sibling names back from the path the helper returns", which is the fixture verifying itself as a fixture. That matters on its own terms: a builder that silently builds nothing would make every test above it pass for the wrong reason, and reading the names back is what distinguishes the two.

Recorded as an amendment rather than a pivot because it changes one criterion's wording, moves no scope, and leaves every other row in both epics standing.

## Story 1 — Test scaffolding for a plugin cache layout

**Status**: complete  
**Blocked by**: Story 2, Story 7  

### Acceptance Criteria

- A constructed directory of sibling version directories exists in the suite, and a test reads its sibling names back from the path the helper returns. `[unit]`
- A test creates a temporary location, writes into it, and asserts it is gone afterwards. `[unit]`
- The running Node satisfies `REQUIRED_NODE`, and `engines.node` equals it. `[unit]`
- The test script invokes only the built-in runner, with no binary resolved from `node_modules`. `[unit]`

### Task 1 — Build a helper that constructs a temporary directory of sibling version directories

**Status**: complete  

The stand-in the neighbour check is pointed at. Addresses the fixture itself, not the check that reads it — and exists so that no test reaches the real plugin cache.

### Task 2 — Build a helper that creates and removes a temporary location

**Status**: complete — The helper already existed as `ownedDirectory` in tests/support/scratch.js, imported by ten test files and tested by none. Nothing was built; the task's value was discovering that its criterion was unmet and putting the removal under test.  

Covers removal on failure as well as on success. A helper that only cleans up on the happy path leaves the next run reading the previous one's directory.

### Task 3 — Assert the project's standing environmental constraints

**Status**: complete — Both assertions already existed with controls: baseline.test.js:178-188 for the running interpreter against REQUIRED_NODE, server.test.js:92 for engines.node, baseline.test.js:154-174 for the runner and the absence of an install step. Verified and cited rather than duplicated — devDependencies is already asserted empty in four files.  

The Node floor matching `engines.node`, and the test script invoking only the built-in runner. Addresses the assertions, not the constraints — both already hold and the point is that they keep holding.

### Task 4 — Write tests for the scaffolding helpers

**Status**: complete  

Covers the four criteria tagged `unit`. The helpers are themselves test machinery, so they need cover of their own — a fixture builder that silently builds nothing would make every test above it pass for the wrong reason.

### Retro

- The control mutation caught a test that was passing for the wrong reason, and it was the test that looked least likely to.

With `pluginCache` mutated to create no directories, two of the three fixture tests failed as intended. The third — "the running sibling defaults to the last one given" — passed, because it asserted only that the helper composes `join(cache, '0.4.0')`. That is true whether or not anything was ever made. A single `statSync(root).isDirectory()` fixed it, and the mutation then failed all three.

This is the library's "a check that passes may be passing for a reason other than the one you want" arriving in its plainest form: the weak assertion was not a subtle aliasing problem or a vacuous quantifier, it was a test about string composition wearing the name of a test about the filesystem. Nothing in reading it would have shown that. Only running it against a builder that built nothing did.

The removal helper got the same treatment: with the `t.after` cleanup dropped from `scratch.js`, the observing test failed with "the file the previous test wrote was removed", which names the right harm rather than propagating someone else's exception.

- Three of this story's four tasks turned out to be already built, and the one criterion that was genuinely unmet belonged to the task that looked most finished.

`ownedDirectory` has been in `tests/support/scratch.js` since epic 49-03, is imported by ten test files, and had no test of its own. Every suite relying on its cleanup was relying on a reading of the source. The criterion "a test creates a temporary location, writes into it, and asserts it is gone afterwards" was unmet in the most ordinary way there is: the code was right and nothing said so.

The environmental assertions were the opposite — fully covered, with controls, in `baseline.test.js` and `server.test.js`, including a floor control at `baseline.test.js:187` proving the check can say no. `devDependencies` is asserted empty in four separate files. Writing a fifth would have been the reflex, and the task's description had already anticipated the shape of this ("both already hold and the point is that they keep holding") without anticipating that the assertions existed too.

The lesson for the stories ahead: the epic was written from the spec rather than from the tree, so its tasks describe what must be true rather than what must be added. Read the tree before building, and expect the ratio to keep favouring "already there".

## Story 2 — Resolve the running plugin's version and its neighbours

**Status**: complete  
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

**Status**: complete  

Takes nothing from the process environment. Respects the decision that the host expands its plugin-root placeholder into launch arguments and does not guarantee it as a variable.

### Task 2 — Read the sibling directories, taking the root and the reader as parameters

**Status**: complete  

One read, no recursion, nothing written. The reader is a parameter so the read can be counted and so the path read is the path given — which is what makes the bounded-cost and no-home-directory criteria checkable at all.

### Task 3 — Write tests for resolving the version and its neighbours

**Status**: complete  

Covers the ten criteria tagged `unit` and `integration`, including the four rejections — recursion, process or socket, any write, and any path through the home directory.

### Retro

- Four rejections, four mutations, and one of the four was invalid on its first attempt in exactly the way the library warned about.

The write rejection was first mutated by adding a `mkdirSync` call using `join`, which the module does not import. Three tests went red with a ReferenceError — a true verdict naming the wrong harm, and precisely retro 55's "a control that fails by propagating someone else's exception is half a control". Rebuilt using template interpolation instead of `join`, the mutation failed the intended test with "reading the cache changed what is in it", which is the sentence someone reading this at 2am needs.

The other three behaved: recursion surfaced a nested directory the non-recursive read never sees, a doubled read moved the call count off one, and reading the host's placeholder variable made the resolver answer with the planted path. Injecting the reader as a parameter is what made two of those checkable at all — a function reaching for `readdirSync` itself could be described as performing one read but never counted.

The lesson to carry: check that a control mutation compiles into the code path it is aimed at before believing the red it produces. Reading which tests went red is not enough; the failure text has to name the harm the criterion is about.

- This project's own import sweep reads prose, and a test written to make a structural claim about imports failed it twice for reasons that had nothing to do with imports.

`plugin.test.js` walks every file under `dpm/` matching the sequence `from` followed by a quoted string, and treats each hit as a dependency. Its reader is a regex rather than a parser, so it cannot tell an import from a regex literal describing one, or from an ordinary English sentence with a quoted phrase after the word "from". Two things in the new test file tripped it: the pattern `/from '([^']+)'/g` used to extract the module's own imports, which it read as a dependency on a package named `([^`; and a header comment containing a double-quoted phrase downstream of the word, which it read as a dependency named " is a structural fact. ".

Both are false positives, and both failed the entire suite rather than the file. The fix is to assemble any such pattern from fragments and to keep quoted phrases out of prose near that word — recorded as a note in the test file's header, because the next person writing a source-scanning test will hit it in exactly the same way.

Worth stating plainly: the sweep is not wrong to be strict. A bare specifier really is an install step, and this project ships with empty dependency maps precisely so a clone needs nothing. The cost is that its strictness is invisible until a file happens to contain the shape, and nothing about the failure message points at prose.

## Story 3 — Compare versions and produce a three-state verdict

**Status**: complete  
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

**Status**: complete  

Addresses the direction of the comparison and the unparseable path. Reuses the parser the Node floor check already carries rather than adding a dependency for it.

### Task 2 — Define the three-state verdict

**Status**: complete  

Skew found, no skew, could not check — distinguishable from the value rather than from its message text, so that a reader branching on the state never has to parse prose.

### Task 3 — Write tests for the comparison and the verdict

**Status**: complete  

Covers the nine criteria tagged `unit`, including the rejection of a skew reported for a lower sibling — the case a reversed comparison would otherwise pass.

### Retro

- A mutation that reversed nothing still passed: replacing "the highest sibling" with "the first sibling above the running version" left every test green, because the fixture's three directories came back from the filesystem in alphabetical order and that order happened to put 0.10.0 first. The test that was supposed to catch a lexical comparison was passing on an ordering accident rather than on the reduction it was written for. Closing it took a second reading of the same three names through a reader whose order the test chooses. Any assertion over a set the filesystem hands back is an assertion about that filesystem's ordering unless the ordering is supplied.

Found by mutation, not by review — five mutations were run against the verdict and this was the only one that survived.

- Story 2's ENVX4 test asserted the module's import list by deepEqual against exactly three builtins, and story 3 broke it by importing the version parser from a sibling module — a reuse the spec's own AD3 called for. The criterion is about what the module can reach outside this process, and an exact-list assertion cannot tell an outbound dependency from a local one. Rewritten to assert over the builtins only, with everything else required to be a relative path inside the project. A must-NOT stated as an equality is a change detector wearing a rejection's clothes; stating it over the category it is actually about survives the next legitimate change.

The amended test is in tests/neighbour.test.js; the criterion itself was not touched.

## Story 4 — Re-evaluate on every report

**Status**: complete  
**Blocked by**: Story 7  

### Acceptance Criteria

- Two consecutive reports against a root that gained a higher sibling between them return different verdicts. `[integration]`
- control — With the check deliberately memoised, the two-consecutive-reports criterion fails, and the failure has been observed and read rather than assumed. `[integration]`

### Task 1 — Evaluate the check at report time rather than at start

**Status**: complete  

Addresses the wiring, not the check. Nothing computed at module load or server start may be reused, because the upgrade this exists to catch lands after both.

### Task 2 — Write tests for re-evaluation on every report

**Status**: complete  

Covers both criteria tagged `integration`. The control is run rather than reasoned about: memoise the check, watch the two-report test fail, and read why before reverting.

### Retro

- Two things could be cached here and only one of them matters, which the first draft of the entry point got wrong in its own documentation. Hoisting the plugin root to module load is harmless — the running directory is fixed for the process's whole life, and that pinning is the bug being detected, not a thing that can drift. Hoisting the sibling listing is the actual defect, because the upgrade lands after start. A mutation that hoisted the root failed nothing, which is the correct outcome and was initially read as a gap in the tests; the mutation that memoised the verdict failed all three. Worth stating in general: when a claim is 'do not cache X', name which X, because an adjacent value that also looks cacheable will absorb the rule and make it untestable.

The doc comment on currentSkew was corrected rather than a test being contrived for the non-defect.

## Story 5 — Report the verdict on check_integrity

**Status**: complete  
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

**Status**: complete  

Beside `entries` and `orphans`, never inside either. Respects the decision that `ok` keeps meaning the data is sound and that the entries list stays derived from the register.

### Task 2 — Compose the skew sentence in one place

**Status**: complete  

One producer, used by every channel that reports a skew. Addresses the wording, not the detection — two channels and two detectors is four chances for the sentence to be written four times and drift.

### Task 3 — Contain failures inside the check

**Status**: complete  

Addresses the error path, not the happy path. A read that throws becomes could-not-check and a successful response; nothing from the check reaches the caller as an error.

### Task 4 — Write tests for reporting the verdict on check_integrity

**Status**: complete  

Covers the eight criteria, including the two rejections that hold the report's shape and the control on error handling — which is run and its failure read, not assumed.

### Retro

- The containment test passed against a deliberately broken implementation, and the reason was the environment rather than the assertion. Written as `currentSkew(throwingReader)`, it resolved the real plugin root — a working tree named for the checkout, not a version — so the check answered could-not-check on the name and never reached the reader at all. It asserted error containment while exercising a short circuit, and would have gone on doing so forever, because the short circuit is the correct behaviour under `--plugin-dir` and nothing about it looks wrong. Naming a version-shaped root instead makes the read actually happen. The general shape: when a function has an early return, a test injecting a fault downstream of it must arrange an input that gets past it, and running the mutation is the only thing that reveals it did not.

Found by the story's own named control criterion — deleting the try/catch and watching what failed.

- A textual import sweep bit for the second time in this epic, now in src/ rather than tests/. server.test.js scans every source file for the word from followed by a quoted string and reports each hit as an external dependency; a doc comment distinguishing one phrase from another, both quoted, read as an import of a package whose name was a sentence. tests/neighbour.test.js already carried a header note warning the next author, and it was not enough, because the note lives in the file where the trap was previously sprung rather than in the file that does the scanning. The durable fix is either a parser instead of a regex, or a note at the sweep itself — a warning is only read where the reader already is.

Two occurrences now: tests/neighbour.test.js during story 2, src/tools/cross/integrity.js during story 5.

## Story 6 — Record the plugin-cache coupling

**Status**: complete  
**Blocked by**: Story 7  

### Acceptance Criteria

- The maintenance record documents the assumed plugin cache layout and what breaks if the host changes it. `[manual]`
- must NOT — Any file under the skills directory names the maintenance record's path. `[unit]`

### Task 1 — Write the maintenance record for the plugin-cache coupling

**Status**: complete  

What layout is assumed, and what breaks if the host changes it. The coupling is to something we do not own, so the record is the only place it is stated deliberately rather than implied by code.

### Task 2 — Write the test that no skill file names the maintenance record's path

**Status**: complete  

Covers the criterion tagged `unit`. The record's content is judged by reading it; what a test can hold is that no skill pays for a pointer to it on every invocation.

### Retro

- This record is the first in docs/maintenance/README.md whose "What asserts it" section says nothing does, and saying so plainly was the right move rather than a gap to be filled. Every other entry names a test holding both ends of a coupling. Here the coupling is to a layout the harness owns and the suite deliberately never reads — a test that opened the real plugin cache would pass on the author's machine for reasons unrelated to the code. So the section states what the suite actually proves (the check reads a layout of this shape, and fails honestly when it cannot) and states that the assumption itself is checked by a person reading the entry. Recording an absence as an absence is what keeps the file's other entries meaning something; an entry that named a tangentially related test would read as covered.

The file's format was followed otherwise — The record / Why it needs a record / What can break it / What asserts it.

## Story 7 — Verify cross-story integration for Neighbour version skew

**Status**: complete  
**Blocked by**: —  

### Acceptance Criteria

- A `check_integrity` call against a constructed root holding a higher sibling returns a skew field naming both versions, with `ok` still true. `[integration]`
- A `check_integrity` call against a root that is not a version directory returns could-not-check, with `ok` still true. `[integration]`

### Task 1 — Write the end-to-end tests for neighbour skew reporting

**Status**: complete  

A real tool call against a real constructed cache, covering the whole path the per-story tests only cover a link of. Both criteria name the state of `ok`, which is what shows the report's separation holding end to end rather than only in the unit test written against the same assumption.

### Retro

- The cross-story story earned its place, and the mutation that showed it was the cheap one. Wiring the response field to a hardcoded verdict instead of calling the check failed four tests — but two of those four were this story's, and the other two were story 5's stubbed tests only because the stub differed from the constant. Every story-5 test injects the verdict, so between them they assert how the report treats a verdict and never once that the check runs. Reading the parent directory instead of the plugin's own — a resolver bug the unit tests cover thoroughly — failed only the end-to-end test, because it is the only one where the fixture on disk and the code path meet. Stubbed tests and a real one are not the same test at different fidelities: the stub asserts the contract between two parts and the real one asserts the parts are connected, and neither substitutes for the other.

Both mutations run and reverted from a scratchpad copy; the full suite stands at 768 pass, 0 fail.

## Dependencies

- blocks → 01-02
