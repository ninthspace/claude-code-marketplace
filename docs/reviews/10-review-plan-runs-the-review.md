# Review: Spec 53 epics — plan runs the review, release

**Date**: 2026-11-10  
**Source**: docs/epics/53-01-epic-plan-runs-the-review.md, docs/epics/53-02-epic-release.md  
**Reviewers**: Jordan (pm), Bella (dev), Casey (test)  
**Findings**: 27 (2 critical, 19 warnings, 6 suggestions), after merging duplicates across the three reports

## Summary

Every Must Have is named by a story, the cited lines hold, and the stories touch different files. The design's two gaps are the review record's format and the hand-off of a spec-reaching finding. The contract gives one `**Source**` path and one title, and the existing records use three forms (one path, a comma list, a range), so `status` cannot tell which epics a record covers. Inside a `plan` run, `review`'s walk and `plan`'s own walk would both ask about a spec-reaching finding. The record format also makes `docs/maintenance/README.md` need an entry, which 53-02 said it did not. Within the epics, two greps passed on unchanged text, the order of the run was split across two criteria that read differently, "about to run unattended" had no test, the prefix scope had no members defined, and the onboarding guide was missing from the docs floor.

## Findings

- **[Critical]** 📋 **Jordan** / 🧑‍💻 **Bella** / 🧪 **Casey**: the contract's Review record (`artifacts.md:199-205`) has one `**Source**` path and a one-epic title; records 06, 08 and 09 already use a range or a comma list, so `status` (FR7) cannot tell which epics a several-epic record covers, and the spec puts the contract out of scope  
  → 53-01 Story 2, criteria 1 and 3 (spec FR6, FR7, Scope)
- **[Critical]** 📋 **Jordan** / 🧪 **Casey**: `status` reading the record is a writer-to-reader coupling, so `docs/maintenance/README.md` does need a record; the release story and FR8 said it did not  
  → 53-02 Story 1, criterion 7 (spec FR8)
- **[Warning]** 📋 **Jordan** / 🧑‍💻 **Bella**: "about to run unattended" judges plan's own output, so builders would read it two ways  
  → 53-01 Story 1, criterion 1
- **[Warning]** 📋 **Jordan** / 🧑‍💻 **Bella**: `review`'s walk asks about a spec-reaching finding and recommends `/cpm-next:plan`, then `plan` asks again  
  → 53-01 Story 1, criterion 4
- **[Warning]** 🧪 **Casey** / 📋 **Jordan**: criteria 3 and 4 split the order of the run; whether an item left for now counts as settled, and whether epics amended after the review are reviewed again, are unstated  
  → 53-01 Story 1, criteria 3 and 4
- **[Warning]** 🧑‍💻 **Bella**: settling a spec-reaching finding amends epics that then qualify again, a possible loop  
  → 53-01 Story 1
- **[Warning]** 📋 **Jordan** / 🧑‍💻 **Bella**: nothing says all qualifying epics go in one review call; Story 1 depends on Story 2's scope form with no blocker  
  → 53-01 Stories 1 and 2
- **[Warning]** 🧪 **Casey** / 🧑‍💻 **Bella**: criterion 6's grep and criterion 1's negative pass on unchanged text or one rewording; criterion 3's control restates it  
  → 53-01 Story 1, criteria 1, 3 and 6
- **[Warning]** 🧪 **Casey**: FR2's line when no epic qualifies  
  → 53-01 Story 1, criteria 2 and 5
- **[Warning]** 🧪 **Casey** / 📋 **Jordan**: no criterion for the restated **Next**, the review's `/cpm-next:plan` **Next**, or findings left open  
  → 53-01 Story 1
- **[Warning]** 📋 **Jordan** / 🧪 **Casey** / 🧑‍💻 **Bella**: the prefix scope's members are undefined (Complete, Withdrawn, user-checks epics)  
  → 53-01 Story 2, criterion 1
- **[Warning]** 📋 **Jordan** / 🧑‍💻 **Bella**: `review`'s step 2, lesson check and **Next** still describe one epic  
  → 53-01 Story 2, criterion 2
- **[Warning]** 📋 **Jordan** / 🧑‍💻 **Bella** / 🧪 **Casey**: a record older than the epic's last amendment, or a story-only record, would stop status suggesting a review  
  → 53-01 Story 2, criterion 3
- **[Warning]** 🧪 **Casey** / 🧑‍💻 **Bella** / 📋 **Jordan**: the rule grep is vacuous and misses `large`, which `status` and `review`'s description carry  
  → 53-01 Story 2, criterion 4
- **[Warning]** 🧪 **Casey** / 🧑‍💻 **Bella**: the 0.14.0 commit is a precondition no story names; diffs with no base pass vacuously  
  → both epics
- **[Warning]** 🧪 **Casey**: the history grep lacks `in place of`, `rather than`, `until recently`  
  → 53-01 epic note
- **[Warning]** 📋 **Jordan** / 🧑‍💻 **Bella** / 🧪 **Casey**: the docs floor leaves out onboarding (212, 253, 461-467, 668), the command table, the record template and training 835 and 851  
  → 53-02 Story 1, criterion 2
- **[Warning]** 🧪 **Casey** / 🧑‍💻 **Bella** / 📋 **Jordan**: no check that the docs refer to the rule rather than restate it (training 819 restates it)  
  → 53-02 Story 1
- **[Warning]** 🧑‍💻 **Bella**: the tag-balance script is not in the repo; the check must describe it  
  → 53-02 Story 1, criterion 3
- **[Warning]** 🧪 **Casey**: lessons that bear but are unlisted: "A fix lands at one place" (Story 1), "A criterion's factual claim" (Story 2), "A check that passes" (Story 2), "A rule is stated once" and "A criterion's factual claim" (53-02); "Reach for it before assuming the surface has it" (build, nested Skill call)  
  → both **Lessons** lines
- **[Warning]** 📋 **Jordan**: the challenge pass and the review both run three opus personas on a non-trivial spec; whether the challenge pass stays is undecided  
  → spec, plan **Finishing** / section 3
- **[Suggestion]** 📋 **Jordan** / 🧑‍💻 **Bella** / 🧪 **Casey**: **Done means** does not name the review
- **[Suggestion]** 🧪 **Casey**: **Written** should list the review record
- **[Suggestion]** 📋 **Jordan**: one target phrasing for "optional"
- **[Suggestion]** 🧑‍💻 **Bella**: `status`'s reading list should name `docs/reviews/`
- **[Suggestion]** 🧑‍💻 **Bella**: the cpm-next-models hold passes to `review`'s frontmatter mid-run (both opus/medium today); a maintenance note
- **[Suggestion]** 📋 **Jordan**: a `00-` epic written from a description reaches review with no spec

## Remediation

- Fixed: the "unattended" test → 53-01 Story 1 criterion 1 (the **Next** this run gives is `do all {spec}`)
- Fixed: the double ask → 53-01 Story 1 criterion 4 (the user's yes in `review`'s walk is `plan`'s cue; not asked again)
- Fixed: the order, left-for-now and no re-review → 53-01 Story 1 criterion 3
- Fixed: the loop → 53-01 Story 1 criteria 1 and 3 (once per run; amended epics not sent again)
- Fixed: one call and the blocker → 53-01 Story 1 criterion 1, `**Blocked by**: Story 2`
- Fixed: greps and controls → 53-01 Story 1 criteria 1, 3 and 7; Story 2 criteria 1, 3 and 4
- Fixed: FR2's line → 53-01 Story 1 criterion 2
- Fixed: **Next**, the review's **Next** and open findings, **Written** → 53-01 Story 1 criterion 6
- Fixed: the prefix scope's members → 53-01 Story 2 criterion 1
- Fixed: `review`'s one-epic neighbours → 53-01 Story 2 criterion 2
- Fixed: stale and story-only records, the reading list → 53-01 Story 2 criterion 3
- Fixed: `large` in the rule grep → 53-01 Story 2 criterion 4
- Fixed: the base commit → both epics' **Base** note
- Fixed: the history grep → 53-01 epic note
- Fixed: the docs floor, one phrasing, the docs rule grep, the tag check, the maintenance record → 53-02 Story 1 criteria 2, 3, 4 and 8
- Fixed: the lessons → both **Lessons** lines
- Fixed (Suggestion applied with a fix): **Done means** read and left alone (53-01 Story 1 criterion 8)
- Fixed (user's decision, 2026-11-10): the contract's Review record → spec 53 Scope and FR6 amended; 53-01 Story 2 criterion 1 and task 2.1
- Settled (user's decision, 2026-11-10): keep both the challenge pass and the review → spec 53 Assumptions
- Fixed (in the same plan run): FR8 → spec 53 FR8 names the maintenance record; 53-02 Story 1 criterion 8
- Not acted on: the models-hold note and the `00-` epic → recorded only
