# Script-Backed Completion Promise

**Source spec**: docs/specifications/44-spec-coverage-rollup.md
**Date**: 2026-07-26
**Status**: Complete
**Blocked by**: Epic 44-01-epic-coverage-rollup-script
**Retro applied**: 23 · testing gaps · Applied — a test that runs a command extracted from a document goes vacuous when the extraction stops matching. Story 1 extracts the prompt template and the script invocation from `ralph/SKILL.md`; the suite asserts each extraction is non-empty *before* anything that depends on it.
**Retro applied**: 23 · testing gaps · Applied — every mutation run in this epic prints what it changed before the suite runs. A no-op mutation reads exactly like a missing control.
**Retro applied**: 23 · testing gaps · Applied — before any `assert_not_contains` over prose, check whether the text has a legitimate reason to contain the forbidden string. The promise site will quote the phrasing it rules out.
**Retro applied**: 23 · patterns worth reusing · Applied — the suite states which of its assertions are oracles and which are regression nets, and the coverage matrix records what verified each row.
**Retro applied**: 23 · patterns worth reusing · Applied — Story 3 inherits `test-aggregation-labelling.sh`'s inventory: the promise site is a new `✓`-bearing site, so the inventory's counts change and a human must classify it.
**Retro applied**: 23 · codebase discoveries · Applied — read the cross-site rule against the existing wording first. `cpm:ralph`'s current promise is a bare tag, which is the wording that has been believed longest.
**Retro applied**: 23 · scope surprises · Applied — an invariant stated per-X when X has always had one Y hides its real subject. Checked before starting: `coverage-rollup.sh`'s exit code has one meaning today because it has had one caller. See *The `--verdict` flag* in the Notes.

## Make the epic-mode promise script-backed
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: FR8, NFR5, AD4

**Retro**: [Scope surprise] AD4 says the promise tag carries its evidence. It cannot: `stop-hook.sh` compares the tag's contents to the `completion_promise` frontmatter with literal string equality, so a tag carrying counts never matches and the loop runs to its iteration cap on a finished epic. The evidence goes beside the tag instead. An architecture decision written against a component's *described* behaviour is worth checking against the component's source before building on it — the hook is 30 lines and reading it took a minute.

**Retro**: [Testing gap] Asserting a script's exit codes and a document's instructions separately does not assert that they agree. Changing the template's `on 3` to `on 4` — a code the script never returns — left every assertion green: the script still exited 3, the prose still read correctly, and the branch could never fire. The fix extracts the codes the template branches on and compares them to the codes the extracted command actually returned. Any test where a document describes a program's behaviour needs the correspondence asserted, not just the two halves.

**Retro**: [Testing gap] A pairing predicate matched the template's *prohibition* instead of its instruction. `output ALL_EPICS_COMPLETE` also appears in "never output ALL_EPICS_COMPLETE without having run that command", so a template that had lost its emit instruction entirely still satisfied the pair. Narrowed to the affirmative branch including its trailing semicolon. Retro 21's shape, for the third time in this spec: a rule and its violation share their tokens.

**Retro**: [Codebase discovery] The verdict awk read the record format's own field numbering straight into `$1..$5`, but awk counts the record *type* as field 1, so every test sat one field to the left and every verdict came back outstanding. A documented record layout and an awk field index are different numbering schemes that look identical when written down.

**Inline change**: `cpm/skills/ralph/SKILL.md` gained pre-flight step **1f, Roll-Up Script Resolution** — not in the original task list. The template needs an absolute path to the script, and writing `${CLAUDE_PLUGIN_ROOT}` into it would rebuild spec 43's defect: the prompt is fed back as a plain user turn rather than run inside a skill, so the variable is not guaranteed to be set and an unset one expands to a bare `/hooks/lib/coverage-rollup.sh`. Resolving at assembly time keeps the prompt self-contained, which is what every other `{...}` placeholder already does.

**Inline change**: `cpm/skills/ralph/SKILL.md`'s `**Length:**` figure went 1,875 → 2,635 characters, with the surrounding prose noting that the suite fired on this change. The correction was planned work (Task 1.2), not a surprise; recorded here because the number is a maintained fact rather than a derived one.

**Acceptance Criteria**:

- `ralph`'s promise text and the script invocation land together in one assertion, so neither can ship alone [integration]
- The emitted promise carries its evidence, so a fabricated promise is distinguishable from an earned one in the log [integration]
- The instruction to run the script and emit the tag only on a passing exit code appears in `ralph`'s generated prompt template, not only in its override table [integration]
- `cpm:ralph` calls the script; it does not reimplement the union, the matching, or the state derivation [integration]
- The prompt template's stated `**Length: N characters**` figure matches the template's actual length after the change [integration]

### Add the delivery verdict to `coverage-rollup.sh` behind a `--verdict` flag
**Task**: 1.4
**Description**: Runs first, before 1.1 — the prompt template's exit-code gate is meaningless until an exit code carries the verdict. Added during execution; see *The `--verdict` flag* in the Notes for the decision and its alternatives. Default exit semantics are unchanged, so nothing epic 44-01 shipped moves.
**Status**: Complete

### Add the script invocation and exit-code gate to `ralph`'s generated prompt template
**Task**: 1.1
**Description**: Covers criteria 1–3. The template is the only operative site: the stop hook feeds that single line back verbatim each iteration and the loop never reads the override table (retro 21). A table-only change documents a behaviour the loop does not have.
**Status**: Complete

### Add the matching override-table row and correct the stated prompt length
**Task**: 1.2
**Description**: Covers criterion 5. The figure is stated and the suite compares it to the template line's real length, so any later edit fails until the figure is corrected.
**Status**: Complete

### Write tests for Make the epic-mode promise script-backed
**Task**: 1.3
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. One assertion binds the promise text and the script invocation together so neither can ship alone; the length comparison's negative control runs the identical extract-and-compare against a mutated fixture, never against the real template.
**Status**: Complete

---

## Preserve existing invocations
**Story**: 2
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: FR9

**Retro**: [Testing gap] A mutation that fails *too many* assertions is as uninformative as one that fails none. The control for multi-epic handling first went in as a `perl -pi -e` whose replacement text contained `$i`, which perl interpolated to empty — the mutated script was syntactically broken rather than behaviourally narrowed, and seven assertions failed including the single-epic ones. It read like a strong control and proved nothing about the multi-epic path. Re-run through `python3` with a literal string replace and an assert on the match count, it failed exactly one assertion, which is the result that carries information. Retro 23's "print what the mutation changed" caught it; the fix is to also *read* what was printed.

**Retro**: [Testing gap] Story 1's prose slices were unguarded, and an unguarded `sed` range is asymmetric: a range matching nothing fails loudly, but one matching a *wider* region than intended passes on text belonging to another section. Story 2 added an upper bound as well as a lower one and applied it to all three slices; renaming the `## Process` heading now fails the Input slice's guard instead of silently widening it to end-of-file.

**Inline change**: `cpm/hooks/tests/test-ralph-promise.sh`'s Step 5b refactoring pass reached into Story 1's already-verified assertions — three inline `sed -n '/…/,/…/p'` slices became one `section()` helper with a `slice_is_bounded()` guard, and the duplicated 1f slice was hoisted to a single variable. Recorded because the pass modified verified code rather than only the code Story 2 added; the assertions' subjects are unchanged and the suite was re-run in full.

**Acceptance Criteria**:

- `cpm:ralph` with empty arguments still auto-discovers incomplete epics [integration]
- must NOT change the behaviour of any existing documented invocation [integration]

### Assert every existing input shape behaves as documented
**Task**: 2.1
**Description**: Empty arguments, an epic range, and explicit epic paths. Scoped to behaviour that already exists — this story adds nothing, it fences what Story 1 could break.
**Status**: Complete

### Write tests for Preserve existing invocations
**Task**: 2.2
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. Placed in `test-ralph-promise.sh` beside Story 1's rather than in a new file — Story 2's subject *is* Story 1's change, and a separate file would put a third copy of the template extraction in the tree.
**Status**: Complete

---

## Label epic-mode aggregation as aggregation, not verification
**Story**: 3
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: FR7, FR8

**Retro**: [Testing gap] Retro 21's shape for the fourth time in this spec, and the first time it broke an assertion written *by this spec*. `test-ralph-promise.sh` banned the word `untraced` anywhere in `ralph/SKILL.md` as evidence that `ralph` derives no requirement state — and Story 3's whole job was to *name* that measurement in order to say `ralph` cannot produce it. The ban caught the caution. Narrowed to what the net is actually for: the operative template carries none of the vocabulary, and every mention elsewhere must be a statement of what epic scope cannot do. Worth noting the pattern is not "we keep making the same mistake" — it is that a negative assertion over prose is *structurally* prone to this, and the remedy is always the same: name the haystack where the string would be an instruction.

**Retro**: [Patterns worth reusing] 44-02 wrote a deliberately temporary assertion — "cpm:ralph presents no aggregated ✓ yet — 44-03 adds both the site and the label" — designed to fail the day this story landed, so the successor epic inherited a complete site list rather than a guess. It fired exactly as intended and was replaced by the real site's assertions. A placeholder that fails on the change it anticipates is more useful than a TODO, because it cannot be skimmed past.

**Inline change**: `cpm/hooks/tests/test-ralph-promise.sh`'s NFR5 regression net "ralph names no requirement-state vocabulary of its own" was split into two narrower assertions. Recorded because it changed an assertion Story 1's gate had already verified; the subject is unchanged and the replacement is strictly more specific about where the vocabulary may and may not appear.

**Acceptance Criteria**:

- Every site presenting aggregated `✓` also states that aggregation is not verification [integration]
- The promise site states that epic mode's promise is aggregation and that only spec mode's would carry the discriminating measurement [integration]

### Add the aggregation statement at the promise site
**Task**: 3.1
**Description**: Covers both criteria. A read of the site rather than a grep, for the reason retro 21 gives: both the correct and the incorrect phrasing contain any token an assertion would look for. The `**Length:**` figure moved 2,635 → 2,736 and the suite fired again, as designed.
**Status**: Complete

### Write tests for Label epic-mode aggregation as aggregation, not verification
**Task**: 3.2
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. `test-aggregation-labelling.sh`'s inventory gains `ralph:1` (total 11 → 12) and its placeholder assertion is replaced by the real site's.
**Status**: Complete

---

## Notes

**The `--verdict` flag** (decided at the start of execution, 2026-07-26). AD4 says the script's exit code decides and the model emits the promise only on zero. The script epic 44-01 shipped exits zero to mean *the computation completed* — every input read, every record emitted — which is not a delivery verdict, and 44-01 recorded the gap explicitly rather than guessing at it. Three options were weighed: change the exit code globally, leave the script alone and let `ralph`'s prompt derive the verdict from the records, or add an opt-in flag. **Chosen: a `--verdict` flag.** Default behaviour is byte-identical to what 44-01 shipped, so `cpm:status` and every existing assertion are untouched; `--verdict` opts in to a third code — `0` all delivered, `3` computed cleanly but work outstanding, `1` could not read, `2` usage. `cpm:ralph` passes it and gates on zero. Rejected: the global change, because it edits a shipped script, breaks about seven assertions, and would make Phase 3b's "on a non-zero exit, stop" instruction abort on an honest report of incomplete work; and the prompt-derives-it option, because putting the state judgement back in the model is exactly the discretion AD4 narrows away and sits against NFR5.

**AD4's evidence definition does not fit the mode being built.** AD4 names the tag's evidence as *the untraced count and requirement total* — both spec-scope measurements. This epic builds the **epic-mode** promise, and epic scope has no requirement list, which is why FR8 says epic mode's promise is aggregation and only spec mode's would carry the discriminating measurement. Row 3 is therefore satisfied by the evidence epic scope *has*: rows verified out of rows total, across the matrices named. The tag says which measurement it is carrying, so a reader is not left to assume it is the untraced one. This is a criteria gap in the spec rather than a licence to improvise — recorded here so 44-03's gate reads it as a deliberate reading of AD4, not a drift from it.

**Story 1's criterion 5 is not in the spec.** It is retro 21's *state a number, then assert it against what it measures*, applied to a constraint epic 43-02 already installed: `ralph`'s prompt template carries a `**Length: N characters**` block that the suite checks against the real template length. Adding the script invocation will break that check, and it should — the criterion makes correcting the figure part of the story rather than a surprise in the suite.

**FR7's other site is in epic 44-02**, on the `cpm:status` phase and the stakeholder artifact. The verbatim criterion appears in both epics' matrices. Whichever of the two finishes second is the one whose gate can honestly check "every site"; because the criterion text is identical in both, the second gate re-reads the set rather than trusting the first.

**No integration testing story.** Story 1's paired assertion — promise text and script invocation in one place, so neither can ship alone — *is* the cross-component check, and it is the spec's own criterion rather than an invention.
