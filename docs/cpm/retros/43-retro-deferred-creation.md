# Retro: Deferred Creation

**Date**: 2026-08-14  
**Source**: docs/epics/49-01-epic-deferred-creation.md  
**Stories**: 7/7 complete

## Summary

The epic did what it set out to do — an MCP session that answers `initialize`, `ping` and `tools/list` now leaves nothing on disk, and the first `tools/call` creates `.dpm/`, writes the ignore file, and opens the database, in that order. Twelve observations came out of it, and they cluster around one thing: **removing a behaviour costs more than the removal**. Three tasks' worth of code arrived a story early because it could not be deferred past the story whose criteria named it; two existing test suites broke on assumptions nobody had written down; and one acceptance criterion turned out to be unsatisfiable by any database in the codebase.

## Observations

### Scope Surprises

- **Three tasks' code arrived one story before its own story.** The `migrated.ahead` gate had to move in Story 2 rather than Story 5, because once the eager `start()` goes the decision is not knowable at launch. Task 3.2's rebuild was already what `open()` did. Story 4's writer landed in Task 3.1, because Story 3's criteria name `.dpm/.gitignore` *and its position in the open order* — the file is not separable from the order it is written in. The common shape: **a task that removes a call site owns every decision that call site was making**, and a breakdown that splits those decisions across later stories is describing a sequence the code cannot follow. Worth a specific check at breakdown time: for each removal task, list what the removed line decided, and put those decisions in *that* story.

### Criteria Gaps

- **A criterion no database in this codebase could satisfy, in a story that changed no behaviour.** NFR3's criterion asked that an existing database "hashes identically" across a read-only lazy session. `migrate()` calls `createRetirementGuards()` on every open, dropping and recreating twenty-four triggers by design — two consecutive opens of an untouched file give three different digests. The criterion's proxy (file bytes) was stricter than the requirement it mapped to, whose own words are "no migration beyond what `migrate()` already does". It was amended to hash the `dump()` text, with `migrated.applied` empty and `vocabulary.inserted` all zero asserted beside it, because a content hash alone would hold if the writes merely happened to be idempotent. The generalisable form: **when a criterion picks a proxy the requirement did not name, check the proxy against the current system before the story is written** — this one would have failed on the day the spec was drafted.

### Codebase Discoveries

- **Two existing suites encoded launch-time creation as an unstated assumption, and neither said so.** Three `spine-integration.test.js` tests spawned a session with a `ping` and then opened the database the server used to create at launch; they broke with `no such table: document_kind`, a message naming neither creation, nor the fixture, nor this epic. `projection.test.js`'s writer sweep names every writer outside `src/projection/` in an `ALLOWED` set and asserts the allowance is *spent*, so any new writer anywhere under `src/` breaks it. Removing a behaviour breaks whoever was quietly relying on it, and **the failure surfaces in the file least likely to mention it**.
- **`rpc.js` keeps `error.message` as the JSON-RPC code's standard text and puts the actionable detail in `error.data`** — deliberately, so a code's meaning does not depend on its message. A wire-level test matching a refusal on `message` asserts against the string "Invalid params" and passes for any refusal at all. The in-process tests never meet this, because they read the `ToolError` directly.
- **Every entry point under `bin/` reaches its logic through `await import()`**, so every `bin/` static graph is the same three files — including `bin/dpm-merge.js`, which runs `git` on every invocation. The first control written for ENVX3's reach check was taken from there and passed for the wrong reason. **A static-graph guard's control has to be a module in the static graph.**
- **Calling the whole tool surface with empty arguments reaches `publish`**, which regenerates `.dpm/dpm.sql` and the markdown projection. A test that exercises every tool is also running every tool's side effects, and the set-equality assertion written for it had to become containment plus "exactly one `dpm.db`".

### Testing Gaps

- **A floor that is not independent of the thing it bounds is not a floor.** "The registry-derived count" read as one and was not: the template list, the file-database list and the count are all built by `spineTools`, so a registry that collapsed collapsed all three equally and the equality went green over three short lists. Found by planting a two-tool return rather than by reading the criterion, and closed with a second floor taken off the seeded `document_kind` rows — four tools per kind — which `spineTools` does not mediate. **Ask what the floor is derived from, not whether one exists.**
- **A shared helper under a set of sweeps needs its own test, written first.** The comment stripper the three source sweeps rest on would, if it ate a regular-expression literal, delete code the sweeps then report clean — and every one would stay green. Confirmed by mutating `/\*…\*/` to `/…/`: four tests failed, three of them sweeps whose subject was untouched.

### Patterns Worth Reusing

- **`git check-ignore -v` returns the verdict *and* names the file and pattern that produced it.** Reading that provenance back is what stops a machine-level `core.excludesFile` from passing an ignore assertion for the wrong reason — the same class of false green as a test whose two sides both move together, which is why the pattern's *value* is never compared against the constant that writes it.
- **Filter a whole-surface sweep on the error code, not on success.** Story 7 calls every one of 181 advertised tools in one session and looks only for `Method not found`; most calls are made with no arguments and are refused as `Invalid params`, which is a tool that *was* resolved and then declined. Filtering on the code is what makes one session able to exercise the whole surface, and the mutation that renamed one resolved tool was caught by name.
- **When two seams must happen in an order, inject both and record into one event list.** `open()` takes `start` and `writeIgnore` so the order is observable; a test that opened the directory afterwards and found both files would pass whichever order produced them. The mutation that moved the ignore write after the open failed *only* the ordering test — which is the point of having it.

## Recommendations

- **At breakdown, treat every removal task as owning the removed line's decisions.** List them explicitly and place them in that story. Three of this epic's tasks were already done when their story came up, which is harmless but means the breakdown was describing a sequence the code could not follow.
- **Check a criterion's proxy against the current system when the criterion is written.** NFR3's file-hash proxy was unsatisfiable on the day it was drafted, and nothing between the spec and the story would have caught it.
- **Before removing a behaviour, grep the suites for fixtures that consume it** rather than for tests that name it. Both suites that broke here relied on launch-time creation without mentioning creation anywhere.
- **When a check's control is drawn from the same tree it guards, verify the control fails for the right reason.** ENVX3's first control found nothing because the walker is blind to dynamic imports, not because the module was clean.
- **Carry the `audit(inputs) → complaints` shape forward.** Every sweep in Story 6 is tested on a planted input it must complain about, and each mutation was caught by exactly the assertion written for it. That is retro 40's lesson holding two epics later.
