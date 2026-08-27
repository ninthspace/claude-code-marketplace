# The reference on every document row

**Number**: 03-01  
**Source spec**: 03  
**Status**: complete  

## What a new tool and a new output field each touch

NFR4 asks for the registration sites to be enumerated before the work rather than discovered during it, because retro 02 recorded a new table costing five registrations where the plan predicted one. Walked before Story 2 wrote anything, the answer is that **the two are different sets, and only one of them is expensive**.

**A new tool touches five sites**, all of them derived sweeps that fail loudly:

- `src/tools/index.js` — the registry itself, which every other check reads rather than restating.
- `tests/parity.test.js` — `NO_CREATE_TOOL`, where a table with no create tool needs a stated exemption.
- `tests/parity-integration.test.js` — `UNPROJECTED`, twice: once for the reason, once for the closure holding that set equal to parity's.
- `tests/conformance.test.js` — AD10's seam, which compares each tool's `inputSchema` against the live DDL.
- `tests/fixtures/tool-surface.js` — the fixture seam, where a creator is registered per entity.

**A new *output field* touches none of them**, and that is the finding worth carrying. Every site above reads a *declaration* — a tool's `table`, `reads`, `writes`, `inputSchema` — or a *column*. A field a handler adds to what it returns is neither: `reference` is derived, no table has it, and no schema declares it. So the four sweeps passed unchanged, and `prose-columns.js`'s classification never saw it.

What an additive field does break is an assertion that states a claim over a **whole row**, because such an assertion fails on any addition whatever the addition was for. Across 837 tests there was exactly one — `tests/tools.test.js:163`, the create-to-read round-trip, comparing two whole rows with neither side a literal. It is now stated over the columns the create returned, and `tests/support/document-equality.js` holds the set empty from here.

The asymmetry is worth stating plainly: the derived sweeps are excellent at catching a *structural* addition and blind to a *presentational* one, and nothing about the first kind of coverage implies the second.

## Story 4 — The environment the work assumes

**Status**: complete  
**Blocked by**: —  

### Acceptance Criteria

- The running Node satisfies `REQUIRED_NODE` in `dpm/src/server/node-floor.js`, and `engines.node` in `dpm/package.json` equals it. `[unit]`
- `npm test` from `dpm/` invokes `node --test` and resolves no test-runner binary from `node_modules`. `[unit]`
- `dpm/src` and `dpm/skills` are present in the working tree, and `.git/hooks/pre-commit` resolves to `dpm/hooks/pre-commit` in that same tree rather than to a path under the plugin cache. `[integration]`
- Every test builds its planning data from `dpm/tests/support/planning-database.js`, and no test opens this project's `.dpm/dpm.db`. `[unit]`
- The suite can create a writable scratch directory, publish a fixture corpus into it, and read the rendered files back. `[integration]`
- `dpm/package.json` declares empty `dependencies` and empty `devDependencies` after this work. `[unit]`
- The suite runs to completion with no `node_modules` directory present. `[unit]`
- The whole suite runs to completion from a local `npm test`, and the repository has no `.github/workflows` directory. `[unit]`
- The suite runs to completion with the plugin cache directory absent or read-only. `[unit]`
- The suite runs against a database at the schema version the installed release targets, and no tool this work adds requires a column that version lacks. `[unit]`
- Every tool this work adds answers correctly against a database whose `docs/` tree has never been published. `[integration]`

### Task 1 — Add a writable-scratch-tree helper the suite can publish into

**Status**: complete  

ENVR5's affordance: creates a scratch directory, publishes a fixture corpus into it, and removes it afterwards. Epic 03-04's published-tree scan uses the same helper, so it is built once here rather than twice.

### Task 2 — Write tests for The environment the work assumes

**Status**: complete  

The eleven criteria: the Node floor and its declaration, the runner, the working tree and its hook symlink, fixture test data, the scratch tree, the empty dependency lists, and the five restrictions. None is `target` — every one is a claim about the machine this work happens on.

### Retro

- A sweep that reads the suite's own sources will find its own planted controls, and this story hit it twice more — once on `plugins/cache` and once on a `join(import.meta.dirname, …, '.dpm', 'dpm.db')` literal written as the control for the very rule that forbids it. Story 2 hit it once on `identifierOf`, and Story 3 hit it hard enough to build `withoutStrings()` for. Three stories, three separate rediscoveries, and the same two wrong answers were available every time: exempt the file by name, or drop the control.

The right answer is now settled enough to name. **Assemble the forbidden string rather than writing it** — `['plugins', 'cache'].join('/')` — because it keeps the control real, keeps the file inside the sweep's own corpus, and costs one line. An exemption by name would go on hiding a genuine breach planted in that file afterwards, which is exactly the file most likely to contain one.

The first two drafts of both new sweeps also failed for the *other* reason worth recording: the reading was too loose, not too tight. `/from ['"]…['"]/` matched an import quoted inside a string; `/\.dpm\/dpm\.db/` matched six suite files that each build a scratch database a line after saying so. `sweeps.js`'s `importSpecifiers` had already solved the first by anchoring at `^\s*import`, and the second wanted the distinction the criterion actually draws — *anchored at the project* rather than *named as a string*. A sweep whose first run reports offenders is usually reading the wrong thing, and the fix is a narrower reading, not an allow-list.

## Story 1 — A fixture that can tell the derivations apart

**Status**: complete  
**Blocked by**: Story 2  

### Acceptance Criteria

- control — The fixture contains a `coverage_matrix` under an epic under a spec, so a derivation taking the document's own `sequence` rather than its epic's produces a different answer and the comparison fails. Without that row the two derivations agree and the criterion above verifies nothing. `[integration]`
- The fixture holds a document with no root-numbered ancestor, `numbering = 'none'` — one of each — so the unnameable cases have rows to be observed against. `[integration]`

### Task 1 — Add a coverage matrix under an epic under a spec to the planning fixture

**Status**: complete  

The two-deep chain only. Existing fixture rows are not reshaped — this adds the one shape that separates a derivation taking the document's own sequence from one taking its epic's.

### Task 2 — Add the two unnameable documents to the fixture

**Status**: complete  

A `numbering = 'none'` row and a child with no root-numbered ancestor. These exist to be unnameable rather than to be read by the rest of the suite, so nothing else should come to depend on them.

### Task 3 — Write tests for A fixture that can tell the derivations apart

**Status**: complete  

Covers both of this story's criteria, both tagged `integration`.

### Retro

- Neither unnameable shape is reachable from the seeded vocabulary, and the schema is what makes them unreachable rather than an oversight in the fixtures. All fourteen seeded kinds are `root` or `child`, and `document.numbering` is pinned to its kind's by the composite foreign key `(kind, numbering) REFERENCES document_kind(kind, numbering)` — so no seeded kind can carry a `numbering = 'none'` row. The same pinning rules out a child with no root-numbered ancestor: every child kind's allowed parents in `KIND_PARENTS` are root-numbered, so the chain always terminates at a number. The fixture therefore registers two kinds of its own (`scratch`, `scratch_leaf`) through the seam. FR3 is about a case a project can only reach by restoring or hand-writing a row, which is worth knowing before the tests for it are read as covering something the seeds produce.

The control was run by removing the implementation rather than reasoning about it: `chain[rootIndex - 1]` replaced with `document` in `identifierOf`, the file copied to the scratchpad first and copied back after. Two of the three tests failed with `actual: '47-01', expected: '47-03'` — the mutation ran, and the message named the harm. The epic sitting at sequence 3 rather than 1 is the whole of what makes that visible; on a chain where both are 1 the criterion verifies nothing, which is what its `control` polarity was recording.

## Story 2 — The reference on every document row

**Status**: complete  
**Blocked by**: —  

### Acceptance Criteria

- Every tool in the built registry whose name begins `list_` or `read_` and whose returned rows are `document` rows carries a `reference` field on each row. The set of such tools is enumerated from the registry itself, never from a written list of tool names. `[integration]`
- must NOT — The check must not invoke `defineTool` directly. It calls the registered handlers against a real database, so a wrapper that works in isolation but was never wired to any tool fails. `[integration]`
- For every document in a fixture corpus, the `reference` a tool returns equals the identifier embedded in that document's `pathOf` filename. `[integration]`
- must NOT — The expected value must not be recomputed by calling `identifierOf` in the check. An assertion comparing the wrapper's answer against the function the wrapper calls has two outcomes that produce the same observed value, and it passes forever. `[integration]`
- A `numbering = 'none'` document, and a child-numbered document with no root-numbered ancestor, each come back with `reference` set to null and the call returns normally. `[integration]`
- must NOT — A list containing one unnameable document among nameable ones must not lose rows or raise. Every row comes back, and only the unnameable one carries null. `[integration]`
- The statement count for a fifty-row list is the same against a ten-document corpus and a two-hundred-document one. `[integration]`

### Task 1 — Give `defineTool` a database handle and a document-rows declaration

**Status**: complete  

The registration seam only — what registration passes in, and what a descriptor must declare to opt in. No attachment logic in this task.

### Task 2 — Attach the reference in the handler wrapper, for both return shapes

**Status**: complete  

A single row and an `{items: [...]}` page, beside `withoutBody` which already understands the same two. Calls `identifiers(db)`; it does not re-derive the numbering rule.

### Task 3 — Declare document rows on every tool that returns them

**Status**: complete  

Addresses which tools opt in. The set is enumerated from the registry rather than from a written list of tool names, so a tool added later is not silently outside it.

### Task 4 — Compute the identifier map once per call

**Status**: complete  

Addresses the bound rather than correctness. A per-row lookup would satisfy every other criterion in this story and fail this one.

### Task 5 — Write tests for The reference on every document row

**Status**: complete  

Covers all seven criteria, every one tagged `integration` — including both must-NOTs and the comparison against `pathOf` rather than against `identifierOf`.

### Retro

- The additive field cost exactly one assertion in 837, and it is the one the spec predicted. `tools.test.js:163` deep-equals a created row against the same row read back, and the read now carries `reference` — so the failure is Story 3's task 3 arriving early rather than a defect here. NFR4 named this shape from retro 02's five-registrations finding, and the count came out at one because the derived sweeps read declarations rather than row shapes: `parity`, `parity-integration`, `conformance` and `prose-columns` all pass unchanged, because a returned field is not a column and none of them looks at what a handler returns.

Two things the seam made visible that a per-tool attachment would not have.

**`table` does not answer "does this tool return document rows".** It names the table a tool reads or writes, and the two questions come apart the moment a tool reads `document` and returns a count, a preview or a search hit. So `documentRows` is declared and the check enumerates by `table === 'document'` instead — the check and the mechanism read different columns, which is what makes a tool that forgot the declaration fail rather than exclude itself.

**The unnameable rows needed a second parentage to be checkable at all.** `scratch_leaf` was allowed under `spec` as well as under `scratch`, because otherwise every unnameable row is the only row of its kind and "a list must not lose rows when one row among them cannot be named" has no list to be checked against. The criterion is about a mixed list, and a fixture of segregated lists satisfies its words while testing nothing.

Both controls were run by removing the implementation. `withReference` returning its input unchanged failed four of the six tests, naming `read_adr` and a spec expected at `01`. The wrapper switched to a per-row lookup failed only the bound test, at 51 statements against 200 documents versus 10 against 10 — the assertion message had predicted the 51 before it was seen, which is the difference between a control and a coincidence. Both restored from a scratchpad copy.

## Story 3 — The suite survives an additive field

**Status**: complete  
**Blocked by**: —  

### Acceptance Criteria

- Every test asserting a returned document row by deep-equality against a literal is enumerated from the suite source, and the resulting list is empty. Such an assertion breaks on any additive field, which is what makes it the shape worth finding rather than a style preference. `[unit]`

### Task 1 — Enumerate the registration sites a new tool and a new output field touch

**Status**: complete  

The tool registry, the conformance suite, the parity suite and its spent-checked exemptions, the tools suite, and the fixture tool surface. The enumeration is this task's deliverable; changing those sites is the other stories' work.

### Task 2 — Write a check that finds document-row deep-equality assertions in the suite

**Status**: complete  

Reads the suite source. Scoped to document rows: `plugin-stamp.test.js` deep-equals a non-document row and is correct to, so a check that flagged it would be reporting the wrong thing.

### Task 3 — Resolve whatever the check finds

**Status**: complete  

Each instance updated deliberately rather than suppressed. An exemption added here would make the check pass while the assertion it was written to find is still there.

### Retro

- The sweep found its own control and reported the suite permanently dirty, and the fix was the difference between reading code and reading text. `reference-additive.test.js` plants two whole-row equalities as string literals so the reading can be watched failing; the reading walks every file under `tests/`, so it found the plants and returned two findings that were not assertions at all. The tempting repair — exempt that file by name — would have gone on hiding a genuine finding in it forever. Emptying every string literal before scanning, quotes kept so the parentheses stay balanced, says the actual rule instead: an assertion quoted inside a string is not an assertion.

Two calibrations decided whether the check meant anything, and both were found by running it rather than by writing it.

**Scoping by what a transform does, not by whether one is present.** The first pass flagged `call.list_epic({ready: true}).items.map((row) => row.id)` because the binding mentioned a document tool. `map`, `reduce` and `Object.keys` project — an equality over what comes out names the field it means, which is the shape the check is asking for. `filter`, `sort`, `slice` and `find` narrow a set and what comes out is still whole rows, so they stay in scope. A rule reading "does this line contain a transform" gets that exactly backwards.

**Recognising the row by the schema's own columns.** `plugin-stamp.test.js` deep-equals `[{singleton: 1, version: '0.4.0'}]` and is right to; a check flagging it would be argued with rather than acted on. Requiring `id` plus two more columns of the live `document` table separates the two without a list of allowed files, and the columns are read from `PRAGMA table_info` rather than written down.

The finding that mattered was not a literal at all: `tools.test.js:163` compared a read against a create, both whole rows, neither side written out. A check recognising only literals — which is what the criterion's own wording suggests — would have missed the single assertion this epic broke.

## Dependencies

- blocks → 03-02

## Retro Applied

- 02 · Codebase Discoveries · applied — Budget the derived-sweep registrations, not just the change site. Story 3 enumerates every exact-column-set assertion in the suite before Story 2 adds the field, and the sweep covers the derived suites (parity, parity-integration, prose-columns, schema) rather than only the tool modules.
- 01 · Patterns Worth Reusing · applied — A rejection asserted by enumeration fires on the first legitimate change. Where this epic updates an assertion broken by the additive field, it is restated over the category the assertion is about rather than re-pinned to a new exact list.
- 03 · Testing Gaps · applied — Build the fixture from the model, enumerating the vocabulary. Story 1's fixture covers the numbering vocabulary — root, child, none and the no-root-ancestor case — rather than only the two rows the criteria name.
- 04 · Testing Gaps · applied — Run the control by removing the implementation, not by reasoning about it. Story 1's control criterion is proved by planting the wrong derivation and watching the comparison fail; the mutated file is copied to the scratchpad first and copied back, never reverted with git.
