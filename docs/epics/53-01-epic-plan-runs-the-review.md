# Plan runs the review

**Source spec**: docs/specifications/53-spec-plan-runs-the-review.md  
**Date**: 2026-11-10  
**Status**: Pending  
**Blocked by**: —  
**Amended**: review 10 (docs/reviews/10-review-plan-runs-the-review.md) — a named base commit, controls that today's text fails, the full order of the run, one review per run, how a spec-reaching finding passes from review to plan, the "unattended" test, open findings in **Next**, the prefix scope's members, the several-epic neighbours in `review`, a stale or story-only record, wider rule greps with `large` (2026-11-10)  
**Amended**: the user's decision on review 10 — the contract's Review record **Source** and title in Story 2 (2026-11-10)  
**Lessons**: docs/library/01-library-lessons-learned.md → "A rule is stated once; every other place refers to it and carries none of its terms" (Story 1), docs/library/01-library-lessons-learned.md → "A rule is stated once; every other place refers to it and carries none of its terms" (Story 2), docs/library/01-library-lessons-learned.md → "A criterion's factual claim is checked against the code and its sibling criteria before the epic runs" (Story 1), docs/library/01-library-lessons-learned.md → "A criterion's factual claim is checked against the code and its sibling criteria before the epic runs" (Story 2), docs/library/01-library-lessons-learned.md → "A fix lands at one place; the same fault stays at its neighbours" (Story 1), docs/library/01-library-lessons-learned.md → "A fix lands at one place; the same fault stays at its neighbours" (Story 2), docs/library/01-library-lessons-learned.md → "A check that passes may be passing for a reason other than the one you want" (Story 1), docs/library/01-library-lessons-learned.md → "A check that passes may be passing for a reason other than the one you want" (Story 2), docs/library/01-library-lessons-learned.md → "Reach for it before assuming the surface has it" (build)

**Base.** The 0.14.0 release is committed before this epic is built; `{base}` below is that commit (`git log --format=%h -1 --grep="cpm-next 0.14.0"`), and each `Evidence` line cites its hash. Line numbers are at `{base}`. Each control's `Evidence` quotes the passage at `{base}`, or the `grep -c` of the new sentence's key phrase there (0), beside the new sentence. The history check reads the added lines of `git diff {base} -U0` and greps them for `now`, `no longer`, `used to`, `replaced`, `previously`, `instead`, `in place of`, `rather than`, `formerly`, `earlier`, `any more`, `anymore`, `until recently`, `0.14`, `0.15`, `spec 52` and `spec 53`, each hit accounted for.

## Plan sends qualifying epics to review
**Story**: 1  
**Status**: Pending  
**Blocked by**: Story 2 (plan passes the scope form `review` defines)  
**Satisfies**: FR1, FR2, FR3, FR4, FR5, NFR1, NFR3

**Acceptance Criteria**:

- `cpm-next/skills/plan/SKILL.md` **Finishing** runs `/cpm-next:review` through the Skill tool, once per run, on the epics this run wrote or amended that have `Pending` stories and meet the rule, stated there once: an epic is large, touches code the plan found unfamiliar, or the **Next** this run gives is `/cpm-next:do all {spec}`. All qualifying epics go in one call, in the several-epic scope Story 2 adds. Control: `grep -n "cpm-next:review" cpm-next/skills/plan/SKILL.md` gives one hit at `{base}` (line 66, "Suggest `/cpm-next:review {epic}` first"), and after the change each hit is read: none tells the user to run the review for a qualifying epic `[manual]`
- **Finishing** says `plan` names, in one line before the review, each epic it sends and the part of the rule it meets, and each written or amended epic it does not send and why; the line is written whenever the run wrote or amended epics, the review running or not `[manual]`
- **Finishing** gives the run's order in one place: `plan`'s own **Needs you** items (an item left for now counts as settled, and stays listed), then the review, then the review's spec-reaching findings as `plan`'s items, then **Next** restated. Epics amended by settling those findings are not sent to review again. Control: `grep -c "Skill tool" cpm-next/skills/plan/SKILL.md` is 0 at `{base}` `[manual]`
- **Finishing** says how a spec-reaching finding passes from the review to `plan`: `review`'s walk recommends `/cpm-next:plan`; the user's yes there is `plan`'s cue to settle it next, by its own amendment rules, without asking again, updating the finding's Remediation entry; a `Leave it for now` there leaves it open. Control: it says such a finding is not left for a later `/cpm-next:plan` run once the user said yes `[manual]`
- **Finishing** says no review runs when the run stops short of epics, when no written or amended epic qualifies, or when the user's request says not to review; control: the third case is named even when an epic qualifies `[manual]`
- **Finishing** says the restated **Next** is `plan`'s, replacing the review's, and names each epic with a review finding left open, with that finding, beside the `do` command; **Written** lists the review record `[manual]`
- The rule is stated once: `grep -rn -i "unfamiliar" cpm-next/` gives one hit, in **Finishing**'s review sentence (the `Evidence` line cites it), and none in **Next**; the referring passages in `review` and `status` are read beside it and carry none of its terms `[manual]`
- Every claim above is checked against `plan/SKILL.md` and `review/SKILL.md` as Story 2 leaves it, the `Evidence` line citing the line of each: `review`'s **Finishing** still recommends `/cpm-next:plan` for a spec-reaching finding (line 59 at `{base}`), which `plan` takes up; **Done means** (lines 14-21) is read and left alone, since the review is part of **Finishing** `[manual]`
- The added lines of `git diff {base} -U0 -- cpm-next/skills/plan` are read with the history grep, and none records history `[manual]`

### Edit plan's Finishing
**Task**: 1.1  
**Description**: Edit `cpm-next/skills/plan/SKILL.md` **Finishing**.  
**Status**: Pending

---

## Review takes several epics; status reads the record
**Story**: 2  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR6, FR7, NFR1, NFR3

**Acceptance Criteria**:

- `cpm-next/skills/review/SKILL.md`'s scope table (lines 14-19 at `{base}`) gains a row for several epic paths, or a spec's epic prefix (`docs/epics/53`: every `docs/epics/53-*.md` with a `Pending` story, not `Withdrawn` or `Superseded`), reviewed as one scope with one record; `cpm-next/shared/artifacts.md`'s Review record gives **Source** as every epic path in the scope, in full and comma-separated (a prefix expanded, never a range), and a title naming the spec for a several-epic review, with the one-epic and one-story forms kept; floor: the rows for one epic, one story, `all` and nothing are all still there; control: `grep -c -i "prefix\|several" cpm-next/skills/review/SKILL.md` is 0 at `{base}` `[manual]`
- In a several-epic scope, step 1 reads each epic's source spec, step 2 picks three personas for the whole scope and gives every persona every epic, and the lesson check covers each epic's **Lessons** line; **Next** names the `do` scope that covers them (`/cpm-next:do all {spec}` when they are all of one spec's open epics, else each epic). Each of lines 21, 31, 41 and 57 at `{base}` that says "the epic" or `{epic}` is read and changed or accounted for; control: the sentence on two personas for a single story is unchanged `[manual]`
- `cpm-next/skills/status/SKILL.md` **Next** (line 35 at `{base}`) suggests `/cpm-next:review {epic}` before a large epic's first run only when no review record covers it: a record covers an epic when its **Source** names the epic's path (in the form FR6's contract field gives), it reviews the whole epic (not one story), and it is dated on or after the epic's last `**Amended**` line; status's reading list names `docs/reviews/`. Control: `grep -c "docs/reviews" cpm-next/skills/status/SKILL.md` is 0 at `{base}`, and it still suggests the review for a large epic no record covers `[manual]`
- Neither file restates `plan`'s rule: `grep -n -i "unfamiliar\|unattended\|large" cpm-next/skills/review/SKILL.md cpm-next/skills/status/SKILL.md`, each hit read: `status`'s "large epic" refers to its own size test for a suggestion and the description's "large or risky epic" in `review` line 3 are accounted for in the `Evidence` line `[manual]`
- The added lines of `git diff {base} -U0 -- cpm-next/skills/review cpm-next/skills/status` are read with the history grep, and none records history `[manual]`

### Edit review's scope and status's Next
**Task**: 2.1  
**Description**: Edit `cpm-next/skills/review/SKILL.md` (scope table, steps 1-2, **Next**), the contract's Review record and `cpm-next/skills/status/SKILL.md` (**Next**, reading list).  
**Status**: Pending

---
