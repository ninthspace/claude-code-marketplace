# Review: Spec 54 — epics

**Date**: 2026-11-10  
**Source**: docs/epics/54-01-epic-challenge-record.md, docs/epics/54-02-epic-release.md  
**Reviewers**: Jordan (pm), Bella (dev), Casey (test)  
**Findings**: 30 (1 critical, 22 warnings, 7 suggestions), after merging duplicates across the three reports; 0 decided at challenge

## Summary

The personas were picked by spec 54's own rule: the challenge used `architect` and `qa`, so none was reused, and each persona was handed a copy of the spec without its **Challenge** section. No finding repeated the challenge's one `Rejected` decision, so nothing was decided at challenge. Three findings reached the spec: a rejection the user never saw could still be settled, a rejection the user confirmed left no trace, and a reopened finding could be fixed in the epic against a recorded rejection; the user settled all three (2026-11-10). Two facts in the epics were wrong (the roster has no `perspective` field; the contract lists eight seed slugs), and several criteria had greps that pass on unchanged text, negatives with no floor, or a missing mechanism (how the personas get the copy).

## Findings

- **[Critical]** 🧑‍💻 **Bella** / 📋 **Jordan** / 🧪 **Casey**: the roster has no `perspective` field; its entries carry `name`, `displayName`, `icon`, `role`, `personality` and `communicationStyle` (`cpm-next/agents/roster.yaml:9-15`)  
  → 54-01 Story 3, criterion 1 (spec FR3)
- **[Warning]** 📋 **Jordan**: `plan` lists only the rejections "worth the user's check", so one it left out can be settled without the user seeing it  
  → 54-01 Story 2, criterion 2; Story 3, criterion 3 (spec FR2, FR4, AD3)
- **[Warning]** 📋 **Jordan** / 🧑‍💻 **Bella**: a rejection the user confirmed leaves no mark, so a Critical repeat returns at every review, and a reopened finding could be fixed against a user-seen decision  
  → 54-01 Story 2, criterion 3; Story 3, criterion 3 (spec FR1, FR4)
- **[Warning]** 📋 **Jordan** / 🧑‍💻 **Bella**: a reopened Warning fixed in the epic leaves the spec's bullet `Rejected`; the superseded mark needs an `**Amended**` line a spec new this run does not have  
  → 54-01 Stories 1, 2 and 3 (spec FR1, FR2, FR4)
- **[Warning]** 📋 **Jordan** / 🧑‍💻 **Bella** / 🧪 **Casey**: the seed list holds eight slugs, not seven  
  → 54-01 Story 1, criterion 3
- **[Warning]** 🧑‍💻 **Bella** / 📋 **Jordan** / 🧪 **Casey**: "the specs with the section removed" has no mechanism: personas read files, and each epic's **Source spec** points at the full spec  
  → 54-01 Story 3, criterion 2 (spec FR5)
- **[Warning]** 🧑‍💻 **Bella**: step 3's "keep only the findings that would change what gets built" drops a repeat before it can be listed and counted  
  → 54-01 Story 3, criterion 3 (spec FR4)
- **[Warning]** 📋 **Jordan** / 🧑‍💻 **Bella**: a Critical repeat is both weighed as any finding and listed under **Needs you**; whether it is fixed is open; whose severity counts is open  
  → 54-01 Story 3, criterion 3
- **[Warning]** 📋 **Jordan** / 🧑‍💻 **Bella** / 🧪 **Casey**: the reuse form's `{names}` could be display names or roster `name`s  
  → 54-01 Story 1, criterion 2; Story 3, criterion 1
- **[Warning]** 📋 **Jordan**: how a decided finding sits in **Findings** and the count line was undefined  
  → 54-01 Story 1, criterion 2
- **[Warning]** 📋 **Jordan**: a finding partly acted on had no criterion  
  → 54-01 Story 1, criterion 1
- **[Warning]** 📋 **Jordan** / 🧑‍💻 **Bella** / 🧪 **Casey**: Story 3 reads `plan`'s review paragraph that Story 2 edits, with no blocker  
  → 54-01 Story 3
- **[Warning]** 🧪 **Casey**: Story 2 criterion 2's and Story 3 criterion 2's `grep -c "Challenge"` controls pass once the sibling criterion adds the word  
  → 54-01 Story 2, criterion 2; Story 3, criterion 2
- **[Warning]** 🧪 **Casey**: Story 1 criterion 4 contradicts criterion 1 and has no floor; Story 3 criterion 6 and Story 2 criterion 4 pass with zero hits  
  → 54-01 Stories 1, 2 and 3
- **[Warning]** 🧪 **Casey**: nothing keeps `review`'s settling rule out of `plan`  
  → 54-01 Story 2
- **[Warning]** 🧪 **Casey**: a reopened finding's Remediation entry (in place of, or beside, its other entry) was undefined  
  → 54-01 Stories 1 and 3
- **[Warning]** 🧪 **Casey** / 📋 **Jordan**: Story 3's "controls" are floors, and the "changed since" checks are not controls  
  → 54-01 Stories 1 to 3
- **[Warning]** 📋 **Jordan** / 🧑‍💻 **Bella** / 🧪 **Casey**: 54-02's docs grep misses review's "What it reads", "What it writes", finish line and "What it asks you", the seed list copy (training guide 648) and onboarding's review bullet  
  → 54-02 Story 1, criterion 2
- **[Warning]** 📋 **Jordan** / 🧑‍💻 **Bella** / 🧪 **Casey**: 54-02 criterion 3 banned the outcome's name, which criterion 1 requires the README to use  
  → 54-02 Story 1, criteria 1 and 3
- **[Warning]** 📋 **Jordan** / 🧪 **Casey**: the tag check's control was a baseline on one file  
  → 54-02 Story 1, criterion 4
- **[Warning]** 🧪 **Casey**: lessons bearing but unlisted: "A control is only a control once you have watched it fail" (54-02), "A must-NOT … needs a floor" (54-01 Stories 1 and 3), "A criterion's factual claim" (54-01 Story 1)  
  → both **Lessons** lines
- **[Warning]** 📋 **Jordan**: a fix-not-carried-through neighbour of `plan`'s challenge sentence (the walk at line 68) was unnamed  
  → 54-01 Story 2
- **[Warning]** 🧑‍💻 **Bella**: a `Does not hold` repeat had no rule  
  → 54-01 Story 3, criterion 3
- **[Suggestion]** 📋 **Jordan** / 🧪 **Casey**: `grep -w` for the history grep
- **[Suggestion]** 🧪 **Casey**: positive greps for each form
- **[Suggestion]** 📋 **Jordan**: a `fixed.md` row for `plan`'s challenge step
- **[Suggestion]** 🧪 **Casey**: no `fixed.md` row removed; the maintenance record notes the parser
- **[Suggestion]** 🧑‍💻 **Bella**: the spec's parser assumption is anchored at the line start
- **[Suggestion]** 📋 **Jordan**: the maintenance record names the forms by reference
- **[Suggestion]** 🧪 **Casey**: cite line 72 by its opening words

## Remediation

- Fixed (user's decision, 2026-11-10, through `/cpm-next:plan`): every rejection under **Needs you**; the confirmed mark, decided whatever the severity; a reopened fix against a rejection routed to the spec → spec 54 FR1, FR2, FR4 amended; 54-01 Stories 1 to 3
- Fixed: `role` and `personality` → spec FR3; 54-01 Story 3 criterion 1
- Fixed: the superseded mark with its own date → spec FR1; 54-01 Story 1 criterion 1
- Fixed: eight seed slugs → 54-01 Story 1 criterion 3
- Fixed: the copy handed to the personas → spec FR5; 54-01 Story 3 criterion 2
- Fixed: settling before the keep-only filter, the persona's severity, a Critical left unfixed, `Does not hold` repeats → spec FR4; 54-01 Story 3 criterion 3
- Fixed: roster `name` values in the reuse form; the decided finding in **Findings** and the count; the reopened finding's single entry; one bullet per part → spec FR1, FR3, FR4; 54-01 Story 1 criteria 1 and 2
- Fixed: Story 3 blocked by Story 2 → 54-01 Story 3
- Fixed: controls, floors and positive greps → 54-01 Stories 1 to 3 and the **Base** note; 54-02 criterion 4
- Fixed: `review`'s rules kept out of `plan`; line 68 named; line 72 by its opening words → 54-01 Story 2 criteria 3 and 4
- Fixed: the docs floor, the settling-conditions grep → 54-02 criteria 2 and 3
- Fixed: the lessons → both **Lessons** lines
- Fixed (Suggestions applied with fixes): `grep -w`, no `fixed.md` row removed, the maintenance record by reference with the parser note, the spec's parser assumption
- Not acted on: a `fixed.md` row for `plan`'s challenge step → recorded only; the failure this release fixes is review repeating a decision
