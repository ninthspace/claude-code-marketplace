# Release 0.18.0

**Source spec**: docs/specifications/56-spec-independent-acceptance-tests.md  
**Date**: 2026-11-11  
**Status**: Pending  
**Blocked by**: Epic 56-01-epic-contract-and-plan, Epic 56-02-epic-test-writer-do-and-audit  
**Amended**: review 13 (docs/reviews/13-review-independent-tests.md) — the docs, versions and maintenance record compared against `1d2b141`, since spec 55 changed them after `0a4e609`; the maintenance record's edits named where they land; the cross-file "stated once" control for every new form, run here after the last edit; floors for each form in the guides; how the tag check counts (2026-11-11)  
**Lessons**: docs/library/01-library-lessons-learned.md → "A fix lands at one place; the same fault stays at its neighbours" (Story 1), docs/library/01-library-lessons-learned.md → "A must-NOT stated as an equality is a change detector, and a set comparison needs a floor" (Story 1), docs/library/01-library-lessons-learned.md → "A control is only a control once you have watched it fail, and read why" (Story 1), docs/library/01-library-lessons-learned.md → "A rule is stated once; every other place refers to it and carries none of its terms" (Story 1), docs/library/01-library-lessons-learned.md → "A criterion's factual claim is checked against the code and its sibling criteria before the epic runs" (build)

**Base.** `{base}` is `0a4e609` for files under `cpm-next/`, and `{docs-base}` is `1d2b141` for `.claude-plugin/marketplace.json`, the root `README.md`, the three HTML guides and `docs/maintenance/README.md`, which spec 55 changed after `{base}`.

## Docs, records and versions
**Story**: 1  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR13, NFR2, NFR3, NFR4

**Acceptance Criteria**:

- `cpm-next/.claude-plugin/plugin.json` and cpm-next's entry in `.claude-plugin/marketplace.json` read `0.18.0`, and `git diff {docs-base} -- .claude-plugin/marketplace.json` shows that one version line changed and no other `"version"` line `[manual]`
- `cpm-next/README.md` gains `(0.18.0)` bullets under **Additions** for the test-writer and the field, **Data Sources** and samples, the identity and conservation criteria, and the runs and audit, plus a Size bullet giving `wc -w` over `plan`, `do`, `test-runs.md` and the auditor at `{base}` and now, and the word count of `test-writer.md`; and an **Upgrading to 0.18.0** note. Floor: every **Additions** bullet at `{base}` is still there `[manual]`
- Every place in the docs that describes the build, the agents or the templates describes the test-writer, the field, the **Data Sources** section and the `before the build` red: the root `README.md`, `cpm-next-training-guide.html`, `cpm-next-onboarding.html` and `cpm-next-presentation.html`. The search that finds those places is `grep -n -i "auditor\|scout\|red pass\|Testing Strategy\|Effort\*\*"` over the four files, each hit read and either updated or accounted for in the `Evidence` line. Floors: each file gains at least one `test-writer` hit; the training guide also gains `Data Sources`, `Independent tests` and `before the build` hits `[manual]`
- `cpm-next/shared/fixed.md` gains rows for `cpm-next/skills/plan/SKILL.md` Epics (`identity-key`) and `cpm-next/skills/do/SKILL.md` The loop (`shared-assumption`), each `0.18.0`, and `git diff {base} -- cpm-next/shared/fixed.md` shows only added lines `[manual]`
- `docs/maintenance/README.md`'s cpm-next record: its "Contract strings a mod may later parse" bullet adds `**Independent tests**` with its states and ` — revised`, and `— before the build`; its "Unknown fields in the mods" bullet adds `**Independent tests**` to the fields that are safe to add, under the same one-line header-block condition as `**Test run**`. Floor: every other bullet of the record at `{docs-base}` is unchanged (`git diff {docs-base} -- docs/maintenance/README.md` touches only those two bullets) `[manual]`
- Every new form is stated once, after the last edit of the spec: for each of `sample due: {`, `{path} {blob}`, `— revised {`, `red: {message} — before the build`, `100 KB` and `one stand-in`, `grep -rlF` over `cpm-next/skills cpm-next/agents cpm-next/shared` lists `cpm-next/shared/artifacts.md` only. Control: the same grep, with one of those strings planted in a copy of `do/SKILL.md` under the scratch directory and that copy added to the paths, lists the copy too `[manual]`
- The three HTML guides pass a tag-balance check with Python's `html.parser`: void elements (`br`, `img`, `meta`, `link`, `input`, `hr`, `col`, `source`, `wbr`) are not pushed, an end tag must match the open tag on top, and mismatches and tags left open are each 0. Control: a copy of a guide with one `</p>` removed gives at least one `[manual]`
- `claude plugin validate cpm-next` and `claude plugin validate .` pass, and `claude plugin test` passes for cpm-next, cpm-next-models, cpm-next-progress and whats-next `[manual]`

### Write docs, records and versions
**Task**: 1.1  
**Description**: Edit the READMEs, the three HTML guides, `fixed.md`, the maintenance record and the version files.  
**Status**: Pending

---
