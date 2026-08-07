# Retro: Shared Convention Restructure

**Date**: 2026-07-25
**Source**: docs/epics/41-01-epic-convention-restructure.md
**Stories**: 3/3 complete

## Summary

Epic 41-01 reduced `## HTML Output` from three roles to one, promoted `Artifact Publishing` to a top-level section with a canonical reference line for epic 41-03 to propagate, and added `check_valid_fragment` to the validator library. All 11 coverage rows verified; full suite green throughout. The epic's defining lesson is not about the convention at all — it is that **two of three stories hit the same criteria-design defect**, which makes it a rule rather than an incident.

## Observations

### Criteria Gaps

- **A criterion phrased as a repo-wide grep implicitly claims repo-wide *edit* scope.** Story 1's criterion was `grep -rn "Tier 1\|Tier 2" cpm/ --include="*.md"` returns zero hits; Story 2's must-NOT was *"at any site"*. Both are unsatisfiable within an epic that owns one file, because the sweep reaches files owned by epics 41-02 and 41-04. Story 1's retro predicted the second instance and it arrived one story later. The corrective is at breakdown time, not execution time: **scope the grep to the files the epic owns** (`grep -n … cpm/shared/skill-conventions.md`), and let a separate criterion on the owning epic cover the rest. A repo-wide sweep is a fine *verification* for the last epic in a chain and a bad *criterion* for the first. Both instances were resolvable by an `**Inline change**` breadcrumb, but a criterion that needs amending to be satisfiable was mis-phrased when written — 41-03 and 41-04 each carry more of the same shape and should be re-read before they start.

### Codebase Discoveries

- **The shell test framework reports more passes than tests run whenever a test carries two assertions.** `test_start` increments `TESTS_RUN` once; `test_pass`/`test_fail` increment per assertion. `test-html-template.sh` has reported `22/10` for months and `test-artifact-fragment.sh` initially reported `21/11`. The ratio reads as a broken harness rather than a style choice, and it cost a round of investigation to establish that it was pre-existing rather than newly introduced. Where a function returns both a code and a reason, assert them together in one `test_start` — `assert_fragment_valid` / `assert_fragment_rejects` brought the new suite to an honest `11/11` and removed nine repetitions of the same three-line invoke pattern. Fixing the older suites was left alone deliberately: this epic does not own them.

### Patterns Worth Reusing

- **Reading the changed section end to end catches what structural tests cannot.** Story 2's assertions all passed while two sentences still carried false premises — *"Producing HTML and publishing it are two decisions"* (after the pivot, most publishing produces no HTML) and Availability's *"every local output is unaffected"* (after the pivot, some outputs have no local form to be unaffected). Structural tests assert that a section exists, not that its claims are still true. A prose-carrying change needs one deliberate read of the finished section as its last verification step.

- **A phrase is a hint about where to look, never the verdict** (retro 12, applied). The `Tier 1|Tier 2` sweep returned seven hits; judging each by what its rule *did* rather than deleting on the match is what preserved the export-affordance pattern that Story 41-02.4 depends on. Relocating it into `Artifact Publishing` rather than deleting it was a criterion added at breakdown precisely because the spec's literal reading would have destroyed it.

### Testing Gaps

- **Step 5b found a real fragility, not cosmetics.** Story 1's `sed -n '/Artifact Publishing/,/^## /p'` slice began matching a cross-reference at line 453 once the section was promoted — it passed only because sed restarts the range and a later match happened to cover the right span. A test that passes for the wrong reason is worse than one that fails. Anchoring to `/^## Artifact Publishing/,/^## A Closing Note/` fixed it. When a test slices a document by pattern, anchor the pattern to the heading syntax (`^## `), never to the bare phrase.

## Recommendations

- **Re-read 41-03 and 41-04's criteria before starting them.** Both carry repo-wide grep-shaped criteria. Rescope each to the files its epic owns, or move it to the last epic in the chain where the sweep is genuinely satisfiable.
- **Treat a needed criterion amendment as a planning defect, not an execution one.** Two `**Inline change**` breadcrumbs in one epic is the signal; the fix belongs in `cpm:epics`, where the criterion is written.
- **When a validator returns a code and a reason, assert both under one `test_start`.** Extract a named helper rather than repeating the invoke-and-check triple.
- **Add an explicit end-to-end read of the changed section to the verification step of any prose-restructuring story.** Structural assertions are necessary and insufficient.
- **Leave the pre-existing pass-count inflation in older suites alone until an epic owns them.** It is cosmetic and non-blocking; fixing it opportunistically would spread edits across files outside any epic's boundary — the same defect this retro's main lesson describes.
