# Spec-Scoped Coverage Presentation

**Source spec**: docs/specifications/44-spec-coverage-rollup.md
**Date**: 2026-07-26
**Status**: Complete
**Blocked by**: Epic 44-01-epic-coverage-rollup-script
**Retro applied**: 21 · codebase discoveries · Applied — carried forward from this session's gate on epic 44-01, where the same five observations were dispositioned for the same spec's work. Story 3's sweep is a read of each site, never a grep: both the correct and the incorrect phrasing of the aggregation statement contain any token an assertion would look for.
**Retro applied**: 21 · testing gaps · Applied — carried forward; every negative control runs the identical code path against a mutated fixture, and each states what it would catch.
**Retro applied**: 19 · testing gaps · Applied — carried forward; expected values are read from the spec and the script's records at run time, never pinned.
**Retro applied**: 20 · testing gaps · Applied — carried forward; fixtures build under `TEST_TMPDIR` per call.
**Retro applied**: 20 · patterns worth reusing · Applied — carried forward; assertions are stated as relationships that hold by construction rather than as counts.
**Retro applied**: 44-01 · testing gaps · Applied — an assertion phrased against a column the output does not carry holds whatever the code does, and reads as a perfectly good test. Every assertion here names something the script's records or the skill file actually contain.
**Retro applied**: 44-01 · criteria gaps · Applied — 44-01's untraced detection was scoped to whichever section the first parser happened to read. Story 1's rendering states which requirement records it covers rather than inheriting the script's scope silently.

## Add the spec-scoped phase to `cpm:status`
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: FR6, NFR5, AD5

**Retro**: [Testing gap] An assertion that runs a command *extracted from a document* goes vacuous the moment the extraction stops matching — `bash -c ""` exits 0 and emits nothing, so "it produced records" and "it exited zero" both hold for a skill that invokes nothing at all. Mutating the invocation to the `$CLAUDE_PROJECT_DIR` form left three assertions passing for that reason. The fix is one assertion, stated *before* the ones that depend on it, that the extraction is non-empty. Any test whose input is grepped out of a file needs this.

**Retro**: [Testing gap] A mutation that reports no failures may not have been applied. `perl -0pi -e 's/^### Phase 3b:.*?^### Phase 4://'` deleted nothing — with `-0` the file is one record and `^` matches only its start without `/m` — and the green run read exactly like a missing control. Every mutation here now prints a count of what it changed before the suite runs.

**Retro**: [Patterns worth reusing] The suite states, in its header, which of its assertions are oracles and which are regression nets. For a deliverable that is prose a model follows, most `assert_contains` calls on the prose can only catch a rule being *dropped* — they cannot tell an honoured rule from a quoted one. Naming that in the file keeps a later reader from mistaking the green run for a quality verdict, and it is where the criteria that genuinely have oracles get their weight.

**Acceptance Criteria**:

- The invocation extracted verbatim from `status/SKILL.md` produces records when run with `CLAUDE_PROJECT_DIR` unset [integration]
- Output is organised by the spec's MoSCoW headings, with untraced requirements before delivered ones [integration]
- Each requirement is presented with its verbatim text from the spec [integration]
- `cpm:status` calls the script; it does not reimplement the union, the matching, or the state derivation [integration]
- must NOT change `cpm:status`'s existing project-wide view [integration]

### Add the spec-scoped phase section to `cpm/skills/status/SKILL.md`
**Task**: 1.1
**Description**: Documents the invocation and where the phase sits relative to the existing project view. The invocation as written here is what the test extracts, so it is the artefact rather than a description of one.
**Status**: Complete

### Render requirements under the spec's MoSCoW headings, untraced first
**Task**: 1.2
**Description**: Covers criteria 2 and 3. Order is the requirement: the reader's question is "what did I ask for that isn't there", so untraced comes before delivered.
**Status**: Complete

### Write tests for Add the spec-scoped phase to `cpm:status`
**Task**: 1.3
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. The invocation is extracted from `status/SKILL.md` and run verbatim (AD5); a re-typed copy is the defect spec 43 spent an epic on.
**Status**: Complete

---

## Publish the stakeholder artifact
**Story**: 2
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: FR11

**Retro**: [Scope surprise] The repo's artifact-publishing invariant was written as *one canonical line per publishing **skill***, with a hand-maintained roster count. `status` now has two publishable outputs — the project-wide picture and the spec coverage page — which are separately requested, separately confirmed, and published to separate URLs. The invariant's real subject was always the **output**, not the skill; conflating them only worked while every skill had one. Three suites encoded the conflation and had to be re-stated (see the inline changes below). Worth checking whether any other skill is heading for a second output before the next one lands.

**Retro**: [Codebase discovery] `test-status-artifact-pivot.sh`'s "Phase 4 carries the canonical reference line byte-identically" counted matches across the **whole file** while asserting a claim about the Phase 4 slice — it had a `$PHASE4` variable in scope and did not use it. It passed for eight months because there was exactly one site anywhere in the file, so the file-wide count and the slice count were the same number. A second site elsewhere in the file made it fail while pointing at a section that had not changed. Assertions naming a section should be counted within that section's slice even when the file-wide answer happens to agree today.

**Inline change**: `cpm/hooks/tests/test-reference-line-propagation.sh` — the per-skill expectation became a per-skill `sites_expected` lookup (`status` = 2, everything else 1) and `EXPECTED_SITES` went 11 → 12. The byte-identity property the suite exists for is untouched; only the arity changed. `EXPECTED_SITES` stays a literal rather than a sum over the lookup — deriving it from the roster it guards would make it agree with itself.

**Inline change**: `cpm/hooks/tests/test-skill-artifact-guidance.sh` — the adjacency check took `head -1` on both the reference lines and the guidance sentences, so with two sites one site's sentence could stand in for the other's. It now requires *every* reference line to have a guidance sentence two lines below it.

**Inline change**: `cpm/hooks/tests/test-status-artifact-pivot.sh` — the Phase 4 reference-line count is now taken within the `$PHASE4` slice, which is what the assertion always claimed. Verified by mutation: removing Phase 4's line while leaving Phase 3b's now fails this suite, where the file-wide count would have passed.

**Acceptance Criteria**:

- The stakeholder artifact is published through the existing shared **Artifact Publishing** procedure, with no second publishing path [integration]
- The artifact renders the same records the spec-scoped phase renders, organised by the spec's MoSCoW structure, with untraced requirements first [integration]
- Publishing is separately confirmed and never the default [integration]

### Add the artifact guidance to `status/SKILL.md`, referencing the shared procedure
**Task**: 2.1
**Description**: Covers all three criteria. What earns the artifact its place: the requirement text a stakeholder used survives to a `✓` only in the matrices' verbatim column, and no single document currently spans them.
**Status**: Complete

### Write tests for Publish the stakeholder artifact
**Task**: 2.2
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`.
**Status**: Complete

---

## Label aggregation as aggregation, not verification, at every site
**Story**: 3
**Status**: Complete
**Blocked by**: Story 1, Story 2
**Satisfies**: FR7

**Retro**: [Testing gap] Retro 21's finding reproduced itself inside the test written to guard against it. An assertion that the misleading phrasing was *absent* from `cpm:do`'s summary item failed, because the item quotes that phrasing deliberately — in the sentence telling a model not to use it. The warning and the mistake are the same bytes. The fix was to narrow the haystack to the region where the phrasing would be an instruction (the format examples) rather than a caution. Any `assert_not_contains` over prose needs this check: is there a legitimate reason the text would contain the thing being forbidden?

**Retro**: [Codebase discovery] The sweep found the worst-phrased site was not in the new work: `cpm:do`'s batch summary reported "Coverage matrix: 9/9 requirements verified" — a count of marks `cpm:do` itself had just placed, phrased as an outcome someone else confirmed. FR7 was drafted with `cpm:status` and `cpm:ralph` in mind. A cross-site rule is worth reading against the *existing* sites before the new ones, because the existing wording is the wording that has been believed for longest.

**Inline change**: `cpm/skills/do/SKILL.md` Step 8 item 4 — the verification summary now states that the count is aggregation rather than verification, names `cpm:do` as the placer of every mark it counts, and its example strings changed from "9/9 requirements verified" to "9 of 9 rows marked verified by this run". Changing the examples is part of the fix, not decoration: the example is the part a model copies.

**Acceptance Criteria**:

- Every site presenting aggregated `✓` also states that aggregation is not verification [integration]
- A stakeholder reading the output does not take a wall of green as independent confirmation [manual] — whether a page reads as a claim is judgement, not structure

### Sweep every site presenting aggregated `✓` and add the statement
**Task**: 3.1
**Description**: The sweep is a read of each site in turn, not a grep. Both the correct and the incorrect phrasing contain the tokens an assertion would look for (retro 21), so the read is the oracle and the test only guards against a site losing the statement later.
**Status**: Complete

### Write tests for Label aggregation as aggregation, not verification, at every site
**Task**: 3.2
**Description**: Write automated tests covering the story's acceptance criterion tagged `[integration]`.
**Status**: Complete

---

## Notes

**Story 3 runs last on purpose.** FR7 is a cross-site rule, and retro 21's scope surprise was exactly this shape — a conditional rule stated at three sites and wrong at all three, because each site was written independently. Making the labelling its own story after both sites exist means one read covers the set rather than three reads covering one site each.

**FR7's other site is in epic 44-03**, where the completion promise carries aggregated evidence. The verbatim criterion appears in both epics' matrices. Whichever of the two finishes second is the one whose gate can honestly check "every site"; because the criterion text is identical in both, the second gate re-reads the set rather than trusting the first.

**A must-NOT was drafted and dropped**: *"must NOT state or imply that a `✓` is independent evidence"*. It is unassertable for the reason retro 21 names — an explanatory clause containing the words is indistinguishable by grep from a claim making them. The `[manual]` criterion carries that judgement instead.

**No integration testing story.** Story 3 already reads both sites Stories 1 and 2 produce; a separate integration story would repeat it.
