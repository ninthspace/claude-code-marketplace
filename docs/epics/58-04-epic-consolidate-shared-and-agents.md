# Consolidate the contract, test-runs and the agents

**Source spec**: docs/specifications/58-spec-plugin-consolidation.md  
**Date**: 2026-11-12  
**Status**: Pending  
**Blocked by**: Epic 58-03-epic-consolidate-do  
**Amended**: review 15 (docs/reviews/15-review-plugin-consolidation.md) — 58-03's **Checks** apply; key-phrase greps with floors and controls; the `**Test run**` mapping owned by the contract and checked by the region script; long paragraphs listed by script; W7's control needs a defect only the moved checks catch; a validate warning that already exists allowed; a ceiling miss is a `Not met` (2026-11-12)  
**Lessons**: docs/library/01-library-lessons-learned.md → "A rule is stated once; every other place refers to it and carries none of its terms" (Story 1), docs/library/01-library-lessons-learned.md → "A rule is stated once; every other place refers to it and carries none of its terms" (Story 2), docs/library/01-library-lessons-learned.md → "A rule is stated once; every other place refers to it and carries none of its terms" (Story 3), docs/library/01-library-lessons-learned.md → "A control is only a control once you have watched it fail, and read why" (Story 1), docs/library/01-library-lessons-learned.md → "A control is only a control once you have watched it fail, and read why" (Story 2), docs/library/01-library-lessons-learned.md → "A control is only a control once you have watched it fail, and read why" (Story 3), docs/library/01-library-lessons-learned.md → "Reach for it before assuming the surface has it" (Story 3), docs/library/01-library-lessons-learned.md → "A fix lands at one place; the same fault stays at its neighbours" (build), docs/library/04-library-model-specific-accommodations.md → "A delegated finding is spot-checked in the file before it is acted on" (build)

**Checks.** As 58-03's **Checks**, which define `{pre}`, the walk-throughs, the inventory, the history check and the protected labels. Each story's "lines over 150 words" are listed by the script in `{pre}/checks/` and either become bullets or are named with why they stay; a ceiling miss is a `Not met`, never a reason to cut a rule.

## The contract
**Story**: 1  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR9, NFR1, NFR3, NFR4  
**Effort**: high

**Acceptance Criteria**:

- In `artifacts.md`, each rule a skill or `test-runs.md` owns is referred to, not restated; the evidence paragraph's `n/a` fit and the **Signals** section become parallel bullets, outside the regions NFR4 protects; the contract keeps the `**Test run**` mapping's form, which `test-runs.md` refers to. The inventory maps every rule unit of `{pre}`'s contract, none unmapped, with a dropped-condition control in a changed passage `[manual]`
- NFR4: 58-02's region script, rerun from `{pre}/checks/`, finds every region non-empty and identical between `{pre}` and the new contract `[manual]`
- The rules the contract owns are stated only there (waiting on the user, the blocked mark, `existing`, the signal forms and marks), each by a key-phrase grep over `cpm-next/skills cpm-next/agents cpm-next/shared`, FR9's exceptions excluded by name; floor: each grep hits the contract once; control: one phrase planted in a copy of `do/SKILL.md` is found `[manual]`
- The walk-throughs that read the contract (W1, W14, W16, W18–W21) give the same tuple over `{pre}` and the new text; control: W14 over a copy with the "test whose body the story changed" condition dropped gives a tuple that differs in its audits field `[manual]`
- `wc -w`: `artifacts.md` ≤ 3,450; the added lines are read with the history check, and none records history `[manual]`

### Consolidate the contract
**Task**: 1.1  
**Description**: Edit `cpm-next/shared/artifacts.md`, with the inventory and walk-throughs.  
**Status**: Pending

---

## test-runs.md
**Story**: 2  
**Status**: Pending  
**Blocked by**: Story 1  
**Satisfies**: FR9, NFR1, NFR3, NFR4  
**Effort**: high

**Acceptance Criteria**:

- In `test-runs.md`, repeated definitions are stated once: the fix rerun (**When the run is full**), the order-dependent rule (**A failing targeted run**), the `**Test run**` mapping (by reference to the contract), and the failure-sorting pointers (**An open story's independent tests**); **The deferred full run** becomes parallel bullets under its bold labels (**A pass**, **A failure**, **Every regression**, **A second failure**, **A batch**), which stay. The inventory maps every rule unit of `{pre}`'s file, none unmapped, with a dropped-condition control in **The deferred full run** `[manual]`
- NFR4: the region script finds the `**Test run**` mapping's region in `test-runs.md` non-empty and identical to `{pre}`'s, or the contract's when this story moves it there `[manual]`
- Key-phrase greps for the fix rerun's definition and the order-dependent rule hit `test-runs.md` once each; control: one planted in a copy of `do/SKILL.md` is found `[manual]`
- The walk-throughs that read `test-runs.md` (W1–W4, W8, W11, W13) give the same tuple over `{pre}` and the new text; control: W3 over a copy with one clause dropped from **Every regression** gives a tuple that differs in its fields-written field `[manual]`
- `wc -w`: `test-runs.md` ≤ 1,950; the added lines are read with the history check, and none records history `[manual]`

### Consolidate test-runs.md
**Task**: 2.1  
**Description**: Edit `cpm-next/shared/test-runs.md`, with the inventory and walk-throughs.  
**Status**: Pending

---

## The auditor and the test-writer
**Story**: 3  
**Status**: Pending  
**Blocked by**: Story 2  
**Satisfies**: FR9, FR10, NFR1, NFR2, NFR3  
**Effort**: high

**Acceptance Criteria**:

- `cpm-next/shared/auditor-independent-tests.md` holds the auditor's independent-test checks, `skipped — test-writer unavailable` is not a finding among them; `auditor.md` check 5 keeps a pointer saying to read it, from the contract's directory, whenever the story has an `**Independent tests**` line other than `skipped`, and to read it again if it is not in context; check numbers 1–8 and every heading another file names are unchanged. `claude plugin validate cpm-next` passes with no new warning, and `cpm-next/agents/` holds only `auditor.md`, `scout.md`, `test-writer.md` and `roster.yaml` `[manual]`
- In `auditor.md` and `test-writer.md`, a rule `do`, the contract or `test-runs.md` owns is referred to, not restated; "run no tests" is stated once in `auditor.md`, with checks 6 and 8 keeping their pointers (a key-phrase grep: one hit, a planted copy found); check 5 and **What you are given** become parallel bullets; 58-01's FR3 table, rebuilt over the new `auditor.md`, still pairs every `do` **Audit** item. The inventory maps every rule unit of `{pre}`'s two files, none unmapped, with a dropped-condition control in check 5 `[manual]`
- The walk-throughs that read the auditor or test-writer (W1, W3–W7, W13, W14) give the same tuple over `{pre}` and the new text. W7's case holds a stale `before the build` red on a revised file, which only the moved checks reject; control: W7 over a copy with check 5's pointer removed gives a tuple missing that finding `[manual]`
- `wc -w`: `auditor.md` ≤ 1,700 and `test-writer.md` ≤ 950; the added lines, the new file among them, are read with the history check, and none records history `[manual]`

### Consolidate the auditor and test-writer
**Task**: 3.1  
**Description**: Write `shared/auditor-independent-tests.md`; edit `agents/auditor.md` and `agents/test-writer.md`, with the inventory and walk-throughs.  
**Status**: Pending

---
