# Consolidate plan, review, library and status

**Source spec**: docs/specifications/58-spec-plugin-consolidation.md  
**Date**: 2026-11-12  
**Status**: Pending  
**Blocked by**: Epic 58-04-epic-consolidate-shared-and-agents  
**Amended**: review 15 (docs/reviews/15-review-plugin-consolidation.md) — 58-03's **Checks** apply; library's pointers in FR10's form with validate and a one-place check; the moved-place table complete, with a rule for partly moved places; the `shared-assumption` row keeps its old place; key-phrase greps, an inventory control and the `fixed.md` ceiling; "paragraph" references found by grep; every place `fixed.md` names still resolves; Story 2 after Story 1; the lesson path corrected; Story 1 at high effort (2026-11-12)  
**Lessons**: docs/library/01-library-lessons-learned.md → "A rule is stated once; every other place refers to it and carries none of its terms" (Story 1), docs/library/01-library-lessons-learned.md → "A rule is stated once; every other place refers to it and carries none of its terms" (Story 2), docs/library/01-library-lessons-learned.md → "A control is only a control once you have watched it fail, and read why" (Story 1), docs/library/01-library-lessons-learned.md → "A control is only a control once you have watched it fail, and read why" (Story 2), docs/library/02-library-planning-time-lessons.md → "Read what iterates a set before adding a member to it" (Story 1), docs/library/01-library-lessons-learned.md → "A rule is checked over every case its requirement covers, not the one in front of you" (Story 1), docs/library/01-library-lessons-learned.md → "A fix lands at one place; the same fault stays at its neighbours" (build), docs/library/04-library-model-specific-accommodations.md → "A delegated finding is spot-checked in the file before it is acted on" (build)

**Checks.** As 58-03's **Checks**. Each story's lines over 150 words are listed by the script and either become bullets or are named with why they stay; a ceiling miss is a `Not met`, never a reason to cut a rule.

## library loads its rare actions on demand, and the sweep follows moved sections
**Story**: 1  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR9, FR10, FR11, NFR1, NFR3  
**Effort**: high

**Acceptance Criteria**:

- `cpm-next/skills/library/sweep.md` holds **Sweep** and `library/consolidate.md` holds **Back-fill** and **Consolidate**; the scope table's rows for those arguments, and each other point of use, name the file and say to read it again if it is not in context; **Legacy retros**, which **Learn** needs, stays in `SKILL.md`. Each moved unit is in exactly one file (control: one planted in both is reported twice); `claude plugin validate cpm-next` passes with no new warning `[manual]`
- `sweep.md` holds a table of moved places: `do/SKILL.md` **Independent tests** → `do/independent-tests.md`; `do/SKILL.md` **Before the first story**, step 3, the parallel rules and **Finishing** (their `[browser]` parts) → `do/browser.md`; `library/SKILL.md` **Sweep** → `library/sweep.md`; **Back-fill** and **Consolidate** → `library/consolidate.md`; `agents/auditor.md` check 5 (its independent-test checks) → `shared/auditor-independent-tests.md`. A signal at a wholly moved place is placed at the new one; at a partly moved place it is placed by its text, as **Sweep** places a signal that names no step, before grouping and before reading `fixed.md`. `fixed.md`'s `shared-assumption` row names `do/SKILL.md` **The loop**, **Independent tests** and `do/independent-tests.md`; its header names `library/sweep.md`. W17, run by a fresh subagent: a planted signal at `do/SKILL.md` **Independent tests** groups with one at `do/independent-tests.md`, a browser signal at step 3 is placed at `do/browser.md` and a non-browser step-3 signal stays at step 3, and the row covers the first two; control: the same corpus with the table removed gives separate groups `[manual]`
- The inventory maps every rule unit of `{pre}`'s `library/SKILL.md`, none unmapped, with a dropped-condition control in **Learn**; a key-phrase grep for the signal-line definition hits one place in each file that defines it, a planted copy found; W16–W18 give the same tuple over `{pre}` and the new text (W17 with the moved-place table added to the before text, its one intended change) `[manual]`
- `wc -w`: `library/SKILL.md` ≤ 1,350 and `fixed.md` ≤ 400; the added lines, the two new files among them, are read with the history check, and none records history `[manual]`

### Split library
**Task**: 1.1  
**Description**: Write `library/sweep.md` and `library/consolidate.md`; edit `library/SKILL.md` and `shared/fixed.md`.  
**Status**: Pending

---

## plan, review and status
**Story**: 2  
**Status**: Pending  
**Blocked by**: Story 1  
**Satisfies**: FR9, NFR1, NFR3

**Acceptance Criteria**:

- In `plan`, `review` and `status`, each rule the contract owns is referred to, not restated; `plan`'s **Epics** and **Story fields** become bullets under those bold labels, and every reference to them as a paragraph (`grep -rn "paragraph"` over `cpm-next/skills cpm-next/agents cpm-next/shared`, each hit read: `do`'s small-change paragraph and `test-writer.md`'s inputs among them) reads "section"; `review` step 3 becomes bullets. FR9's exceptions stay word for word, by `diff` against `{pre}`: `review`'s persona checklist and `status`'s waiting-on-the-user test `[manual]`
- Every place a `fixed.md` row names (`plan` **Epics** and **Lessons**, `review` **2. Review independently** and **3. Weigh and fix**, and the others) still resolves to a heading or bold label in the new text, each checked by grep `[manual]`
- The inventory maps every rule unit of `{pre}`'s three files, none unmapped, with a dropped-condition control in `plan`'s **Epics**; key-phrase greps for the amendment rule and the `**Lessons**` form hit the contract once, a planted copy found `[manual]`
- W19–W21 give the same tuple over `{pre}` and the new text (W21 run on Haiku); control: W19 over a copy with the user-checks epic's "blocked by nothing that holds one" dropped gives a tuple that differs in its fields-written field `[manual]`
- `wc -w`: `plan` ≤ 2,150, `review` ≤ 1,450, `status` ≤ 900; the added lines are read with the history check, and none records history `[manual]`

### Consolidate plan, review and status
**Task**: 2.1  
**Description**: Edit `plan/SKILL.md`, `review/SKILL.md`, `status/SKILL.md` and the "paragraph" references, with the inventory and walk-throughs.  
**Status**: Pending

---
