# Retro: Script-Backed Completion Promise

**Date**: 2026-07-26
**Source**: docs/epics/44-03-epic-completion-promise.md
**Stories**: 3/3 complete

## Summary

The epic made `cpm:ralph`'s `ALL_EPICS_COMPLETE` conditional on a script's exit code rather than the model's own judgement: `coverage-rollup.sh` gained an opt-in `--verdict` flag, the generated prompt template runs it and branches on the result, and the promise now prints its evidence beside the tag. All ten coverage rows are verified and the full suite is green at 1,093 assertions.

Spec 44 is now complete across its three epics — 16 requirements, 0 untraced, 16 delivered, and 50 of 50 rows marked across three matrices. The tool built by the spec reports `exit 0` on the spec that specified it, which is a pleasant symmetry and, per the epic's own subject matter, aggregation rather than verification.

The epic's findings cluster around one theme: **a document describing a program's behaviour and the program itself are two artefacts, and asserting each separately does not assert that they agree.** That gap appeared three times in three different forms — an architecture decision written against a component's described behaviour, a prompt branching on an exit code, and a test whose mutation was broken rather than narrowed.

## Observations

### Scope Surprises

- **AD4 was unimplementable as written, and reading the 30-line component it depended on would have shown that before the story started.** AD4 says the `<promise>` tag carries the untraced count and requirement total. The ralph-wiggum stop hook compares the tag's contents to the `completion_promise` frontmatter with literal string equality (`[[ "$PROMISE_TEXT" = "$COMPLETION_PROMISE" ]]`), so a tag carrying counts never matches and the loop runs to its iteration cap on a finished epic — the promise would have been unfalsifiable *and* non-functional. The evidence goes on its own line beside the tag instead, which still satisfies what FR8 asks the evidence for. An architecture decision written against a component's *described* behaviour is worth checking against that component's source before building on it.

- **AD4's evidence definition described a scope this epic was not building.** The untraced count and requirement total are spec-scope measurements; this epic built the epic-scope promise, which has no requirement list to compare against. Rather than improvise, the epic recorded the mismatch in the matrix Notes and satisfied the row with the evidence epic scope actually has — rows verified out of rows total, across the matrices named — with the promise line stating which measurement it is carrying so a reader cannot assume it is the discriminating one. A criteria gap named in the artefact is cheaper than a silent reinterpretation.

- **A shipped script's exit code had one meaning because it had had one caller.** 44-01's `coverage-rollup.sh` exits 0 for "the computation completed", which is not a delivery verdict. Three options were weighed and put to the user; the chosen `--verdict` flag left the default path byte-identical, so `cpm:status` and roughly seven existing assertions never moved. This is the same shape retro 23 recorded one epic earlier ("an invariant stated per-X when X has always had one Y"), which is why it was checked for at the epic's start rather than discovered mid-story.

### Codebase Discoveries

- **A documented record layout and an awk field index are different numbering schemes that look identical written down.** The `--verdict` predicate read the record format's own numbering (`ROW`'s verified cell is field 5) straight into `$5`, but awk counts the record *type* as `$1`, so every test sat one field to the left and every verdict came back outstanding. Costless to find and costless to fix, but the trap is structural: the format table in the header and the awk script beneath it are two different coordinate systems on the same line.

- **`{epic_glob}` had been a decorative parenthetical in the prompt template for its whole life.** The moment it became a command argument, it needed a definition — is it a pattern or a resolved list? Step 1a now defines it, `{epic_range}` and `{epic_count}` alongside it, as *the resolved paths, space separated, exactly as they will be passed to a command*. A placeholder that is only ever read by a human tolerates ambiguity; the same placeholder in a command does not.

### Testing Gaps

- **Asserting a script's exit codes and a document's instructions separately does not assert that they agree.** Changing the template's `on 3` to `on 4` — a code the script never returns — left every assertion green: the script still exited 3, the prose still read correctly, and the branch could never fire. The fix extracts the codes the template branches on and compares them to the codes the extracted command actually returned. Any test where a document describes a program's behaviour needs the correspondence asserted, not just the two halves. This is the epic's single most valuable assertion.

- **A mutation that fails *too many* assertions is as uninformative as one that fails none.** The multi-epic control first went in as a `perl -pi -e` whose replacement text contained `$i`, which perl interpolated to empty — the mutated script was syntactically broken rather than behaviourally narrowed, and seven assertions failed, including single-epic ones. It read like a strong control and proved nothing about the multi-epic path. Re-run via `python3` with a literal replace and an assert on the match count, it failed exactly one assertion. Retro 23's "print what the mutation changed" caught it; the missing half of that rule is to *read* what was printed.

- **An unguarded `sed` range is asymmetric, and only one direction fails loudly.** A range matching nothing makes every `assert_contains` over it fail; a range matching a *wider* region than intended passes on text belonging to another section. Three prose slices were unguarded until a `slice_is_bounded` helper gave each an upper bound as well as a lower one. Renaming a heading now fails the guard instead of silently widening the slice to end-of-file.

- **Retro 21's shape reproduced for the fourth time in this spec, and this time it broke an assertion the spec itself had written.** A regression net banned the word `untraced` anywhere in `ralph/SKILL.md` as evidence that `ralph` derives no requirement state — and Story 3's job was to *name* that measurement in order to say `ralph` cannot produce it. The ban caught the caution. The recurrence is not carelessness: a negative assertion over prose is *structurally* prone to this, because the rule and its violation are written in the same vocabulary. The remedy is always the same and should be applied on sight — name the haystack where the string would be an instruction rather than a caution.

### Patterns Worth Reusing

- **A placeholder assertion that fails on the change it anticipates beats a TODO.** 44-02 wrote "cpm:ralph presents no aggregated ✓ yet — 44-03 adds both the site and the label" specifically so that this epic would inherit a complete site list rather than a guess. It fired the moment the site was built and was replaced by the real assertions. Unlike a comment, it cannot be skimmed past.

- **State a number, then assert it against what it measures.** The prompt template's `**Length: N characters**` block fired twice in one epic — 1,875 → 2,635 when the completion clause landed, then → 2,736 when Story 3's clause did. Both times the suite failed until the figure was corrected. A stated measurement that nothing checks decays silently; this one had been allowed to read "around 1100" against an actual 1,477 before the check existed.

- **The operative site is the one the loop reads.** Every FR8 change landed in the prompt template rather than the override table, because the stop hook feeds the template back verbatim each iteration and the loop reads nothing else. The same principle decided where Story 3's aggregation statement goes: moving it from the template into the surrounding prose leaves the suite green *and that is correct*, because prose the loop never reads is a label on something the operator never sees. The override table row is kept as a record, and says so.

- **Two stories in one suite when one story's subject is the other's change.** Story 2's assertions live in `test-ralph-promise.sh` beside Story 1's, because splitting them would have put a third copy of the template extraction in the tree — and that extraction is the AD5-critical part. A re-typed copy of a documented invocation is how spec 43's defect went unnoticed for months.

### Smooth Deliveries

- The `--verdict` flag was verified by hand against real artefacts before any test was written: 44-01 → 0, 44-02 → 0, 44-03 → 3, spec 44 → 3, missing file → 1, no scope → 2, and stdout byte-identical with and without the flag. Every one matched the design. The design question had been put to the user and settled first, which is why implementation had nothing to discover.

## Recommendations

1. **When a spec's architecture decision constrains a component you did not write, read that component's source before writing the story.** AD4's assumption was falsified by 30 lines of shell. Budget the minute.

2. **Any test where a document describes a program's behaviour must assert the correspondence.** Extract what the document says the program returns, run the program, compare. Two separately-correct halves are not a working whole — and this is the failure mode a prose-heavy codebase is most exposed to.

3. **Read what a mutation printed, not just that it printed something.** Retro 23 established printing the change; this epic found the other half. A control that fails a *broad* set of assertions is suspect — the informative result is the one that fails exactly the assertion it targets.

4. **Give every prose slice an upper bound.** `slice_is_bounded` is in `test-ralph-promise.sh`; the pattern is three lines and belongs anywhere a `sed`/`awk` range feeds `assert_contains`.

5. **Apply retro 21's remedy on sight rather than on failure.** Four occurrences in one spec is enough evidence that the trap is structural. Before writing any `assert_not_contains` over prose, ask where the forbidden string would be an *instruction*, and make that region the haystack.

6. **Spec 44 is complete; spec-scope promise for `cpm:ralph` is deferred and recorded as such.** The deferral is stated in `ralph/SKILL.md` at the site, not only in planning docs, so the next reader of the completion line learns what it cannot tell them from the thing itself.
