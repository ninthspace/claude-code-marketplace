# Retro: Autonomous Change Resolution

**Date**: 2026-07-26
**Source**: docs/epics/43-02-epic-autonomous-change-resolution.md
**Stories**: 5/5 complete

## Summary

The epic gave `cpm:do` a way to resolve a change moment without a human in the room — three dispositions, a citable-contradiction guard on the only one that can rewrite an acceptance criterion, and a `**Pivot deferred**` breadcrumb for whatever the amendment could not reach — then wired it through `cpm:ralph`'s override table and generated prompt. All nineteen coverage rows are verified and the hook suite runs 32 files green.

The epic's own defect pattern is the most useful thing it produced. Every one of the five defects found was a **conditional rule restated as an unconditional one**, and every one was caught by a story gate's end-to-end read while the structural assertions were green. That is not a coincidence about this epic; it is what a token-presence proxy can and cannot see.

## Observations

### Scope Surprises

- **One conditional rule, three sites, three identical errors.** `**Pivot deferred**` is written per *unreached* artefact, so an amendment citing a conflicting criterion in the same epic writes none. `do:64`, `do` Step 8's amendments block, and `ralph`'s override row each stated it as something every amendment leaves — written across three stories, by three different routes, each caught only by that story's read. A memorable field name reads as a guarantee, and downstream sites inherit the guarantee rather than the condition. When a rule is conditional, the condition has to travel with the name at every site that mentions it; naming it alone is what propagates the error.

### Criteria Gaps

- **A criterion named a consumer that does not consume.** Story 2's criterion 3 asserted that `cpm:status` still parses `**Retro applied**` and `**Inline change**`. It reads neither, and `**Retro applied**` is read by no skill at all — it is written by `cpm:do` and `cpm:ralph` and never scanned back. Spec NFR7 names no consumer, so the false claim entered in the epic's paraphrase and would have been "verified" by a test asserting behaviour nothing exhibits. Confirm a named consumer actually consumes the field *when writing the criterion*, not when writing its test — by then the criterion is what the test is derived from.

### Codebase Discoveries

- **`awk -v` applies escape processing to its value.** A regex passed that way arrives with `\*\*` collapsed to `**` and matches nothing; 20 of 22 assertions failed during a refactoring pass for a reason invisible in the regex itself. Routing patterns through `ENVIRON[...]` avoids the class entirely and is now the shape used for all SKILL.md slicing in this repo's suites.
- **Only `ralph`'s prompt template is operative.** The stop hook feeds that single line back verbatim each iteration; the loop never reads the override table, which is maintainer documentation. Anything that must change loop behaviour has to land in the template — a table-only change documents a behaviour the loop does not have, and reads as done.

### Testing Gaps

- **Structural assertions confirm words exist, never that a condition was honoured.** All five defects in this epic were found by an end-to-end read at a story gate, each time with the suite already green — because both the correct and the incorrect phrasing contain the token being asserted. Where a rule is conditional, there is no proxy; the read is the oracle. Retro 17's read-in-place practice has now paid at five consecutive gates and should be treated as load-bearing rather than diligent.
- **A negative control that shares no code path with its assertion is decoration.** The first control written for the prompt-length assertion checked that the real template is not 1,100 characters. It passed, it was labelled a control, and it controlled nothing. The replacement runs the identical extract-and-compare against a fixture whose stated figure has been mutated. On review the first form reads exactly like rigour, which is what makes it worth naming.
- **Presence and agreement fail differently.** Story 5's four-site paired assertion guards against a partial landing and is no guard at all against a partial understanding: all four sites were present, all suites green, and two of them contradicted each other. A cross-site epic needs both checks, and only one of them can be automated.
- **A must-NOT phrased against a token constrains the prose, not just the behaviour.** The `AskUserQuestion` must-NOT was initially unsatisfiable as written, because the first draft used the token in an explanatory clause that no honest grep can tell apart from an instruction to present one. Rewording to "a question posed mid-run" preserved the explanation and made the assertion a true structural proxy.

### Patterns Worth Reusing

- **State a number, then assert it against what it measures.** `ralph`'s prompt budget had read "around 1100" against an actual 1,477 for months. The fix that cannot rot: state the figure, and have the suite extract it and compare it to the template line's real length, so any edit fails until the figure is corrected. Two lines of test, and it applies anywhere a document states a number about its own content.
- **Extract the documented command and run it verbatim.** Carried from 43-01 and used again here: a re-typed copy in a test is how a documented invocation drifted from the real one through months of a green suite.

## Recommendations

- Treat the end-to-end read at each story gate as a required step with a named output, not a diligence habit — it produced every defect this epic found, at five gates out of five.
- When defining a field whose presence is conditional, write the condition into the field's own definition sentence and check every existing mention of the name against it before the story closes. Three sites in this epic needed that check and none got it until a read caught them.
- Audit new negative controls for shared code path with the assertion they guard. A control that cannot fail when the assertion is broken should be deleted rather than kept.
- Apply the state-it-and-assert-it pattern to the other self-describing numbers in this repo's skill files before they drift the way the prompt budget did.
- Epic 43-03 inherits all of the above; it is the remaining epic on spec 43 and now unblocked.
