# Final check across files and release 0.21.0

**Source spec**: docs/specifications/58-spec-plugin-consolidation.md  
**Date**: 2026-11-12  
**Status**: Pending  
**Blocked by**: Epic 58-05-epic-consolidate-skills  
**Amended**: review 15 (docs/reviews/15-review-plugin-consolidation.md) — the checks read from `{pre}/checks/`; mappings by quoted text; the words-cut base named; the maintenance record's real labels and a wider docs search; `{pre}` deleted after the story closes; the guides named; the Blocked by line reduced to 58-05, which follows 58-04 (2026-11-12)  
**Lessons**: docs/library/01-library-lessons-learned.md → "A rule is stated once; every other place refers to it and carries none of its terms" (Story 1), docs/library/01-library-lessons-learned.md → "A fix lands at one place; the same fault stays at its neighbours" (Story 2), docs/library/01-library-lessons-learned.md → "A check that passes may be passing for a reason other than the one you want" (Story 2), docs/library/01-library-lessons-learned.md → "A criterion's factual claim is checked against the code and its sibling criteria before the epic runs" (build)

**Checks.** As 58-03's **Checks**; `{base}` is `479c406` for word counts.

## Every mapping and walk-through over the final text
**Story**: 1  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR9, FR10, NFR1, NFR4

**Acceptance Criteria**:

- Every mapping in `{pre}/checks/`'s inventories is re-checked against the final text of all files together by the text it quotes: each still finds its unit with every condition, or is updated to the text that does; none unmapped. A fresh subagent judges a sample of 30, every cross-file mapping among them. Control: a copy of the final files with one owner sentence removed leaves at least one mapping broken `[manual]`
- All 21 walk-throughs, from `{pre}/checks/cases/`, give the `{pre}` tuple over the final text of all files together (W17 with the moved-place table, its one intended change); control: one walk-through over a copy with one clause dropped from a consolidated file gives a tuple that differs in the field the clause governs `[manual]`
- NFR1: every ceiling is met; the words cut from a `do` run's every-run load (`do`, the contract, `test-runs.md`), from `{pre}` to now, are at least 1,000, and the words moved out of it are given apart; NFR4: 58-02's region script finds every region identical to `{base}`'s but for the `**Amended**` paragraph FR7 extended `[manual]`

### Re-check across files
**Task**: 1.1  
**Description**: Re-run every inventory mapping and walk-through over the final text.  
**Status**: Pending

---

## Docs and version 0.21.0
**Story**: 2  
**Status**: Pending  
**Blocked by**: Story 1  
**Satisfies**: FR12, NFR2

**Acceptance Criteria**:

- `cpm-next/README.md` gains `(0.21.0)` bullets, a Size bullet giving every in-scope file's `wc -w` at `{base}`, at `{pre}` and now (on-demand files listed apart), and an **Upgrading to 0.21.0** note. Floor: every **Additions** bullet at `{base}` is still there `[manual]`
- `docs/maintenance/README.md` records each on-demand file and what reads it, and its bullets that name a moved place name the new file: **claude-in-chrome tool names** (`do` step 3) and **Browser test tool package names** (`do/SKILL.md` step 3) among them, and **The fixed list and the issue draft** notes the moved-place table. The root `README.md`, `cpm-next-training-guide.html`, `cpm-next-onboarding.html` and `cpm-next-presentation.html` do the same, found by `grep -n -i "SKILL.md\|step 3\|Independent tests\|Sweep\|browser\|back-fill\|consolidate\|check 5"` over them, each hit read and updated or accounted for `[manual]`
- The three guides named above pass the tag-balance check, with a control `[manual]`
- `claude plugin validate cpm-next` and `claude plugin validate .` pass with no new warning, and `claude plugin test` passes for the four plugins with at least 177 tests `[manual]`
- `plugin.json` and cpm-next's `marketplace.json` entry read `0.21.0` (one version line changed), the bump being the story's last edit before its audit; `{pre}` is deleted as **Checks** says, after the story closes `[manual]`

### Write docs and version
**Task**: 2.1  
**Description**: Edit the READMEs, maintenance record, guides and version files; delete `{pre}` once the story closes.  
**Status**: Pending

---
