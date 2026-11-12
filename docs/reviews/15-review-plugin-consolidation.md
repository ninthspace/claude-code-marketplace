# Review: Consolidate cpm-next — epics

**Date**: 2026-11-12  
**Source**: docs/epics/58-01-epic-correctness.md, docs/epics/58-02-epic-release-0-20.md, docs/epics/58-03-epic-consolidate-do.md, docs/epics/58-04-epic-consolidate-shared-and-agents.md, docs/epics/58-05-epic-consolidate-skills.md, docs/epics/58-06-epic-final-check-and-release-0-21.md  
**Reviewers**: Jordan (pm), Bella (dev), Casey (test)  
**Findings**: 52 (6 critical, 34 warnings, 12 suggestions), after merging duplicates across the three reports; 0 decided at challenge

## Summary

The personas were picked outside the challenge's `architect` and `qa`, each given a copy of the spec without its **Challenge** section; no finding repeated its one `Rejected` decision. All three found the same three Criticals: "validate passes with no warning" fails today (the plugin has no icon), the inventories and constructed cases lived in a session's run directory where 58-06 cannot find them, and the `fixed.md` sweep check could not fail. Two more Criticals were expected outcomes the old text does not give. Most Warnings are proof that could pass without the change (walk-throughs with no before control, greps with no floor, a noisy comparison with no rule), places a fix left at its neighbours, and moved places the sweep table did not map. Several findings reach the spec, and one is a release decision.

## Findings

- **[Critical]** 📋 **Jordan** / 🧑‍💻 **Bella** / 🔍 **Casey**: "`claude plugin validate cpm-next` passes with no warning" is already false (`ICON_MISSING`) → 58-03 Story 1, 58-04 Story 3
- **[Critical]** 📋 **Jordan** / 🧑‍💻 **Bella** / 🔍 **Casey**: inventories, case texts and reports in the session run directory (`do/SKILL.md:111`) are gone when 58-06 re-checks them → 58-03 to 58-06 Base
- **[Critical]** 📋 **Jordan** / 🧑‍💻 **Bella** / 🔍 **Casey**: the planted-corpus sweep leaves out no group whatever `fixed.md` holds, and its control is reported under both tables (`library/SKILL.md:48,50`) → 58-01 Story 5
- **[Critical]** 📋 **Jordan** / 🧑‍💻 **Bella** / 🔍 **Casey**: the revised-file walk-through expects "rejected" over `{base}`, which accepts the stale red (`auditor.md:24`, `do/SKILL.md:91`) → 58-01 Story 2
- **[Critical]** 🧑‍💻 **Bella**: a resumed `fix due` story cannot know which reds to retake, and whether its whole-story audit's `fix needed` blocks (`test-runs.md:79`) or takes rounds (`do:99`) is unstated → spec FR2
- **[Critical]** 🧑‍💻 **Bella**: the "resumed story with round records" kind's scope needs the fix's files, which no record holds (`do:101`) → spec FR3
- **[Warning]** 📋 **Jordan**: one ceiling miss or noisy walk-through blocks the straight chain 58-03 → 58-06 → 58-03 to 58-05
- **[Warning]** 📋 **Jordan**: a `do all 58` run goes from 58-02 into 58-03 with 0.20.0 never committed or used (AD1) → release decision
- **[Warning]** 🧑‍💻 **Bella**: the order-dependent Warning cannot be read from a line rewritten every run (`artifacts.md:181`) → spec FR5
- **[Warning]** 🧑‍💻 **Bella**: the baseline result an `existing` test needs is stored nowhere a resumed run can read → spec FR5
- **[Warning]** 🧑‍💻 **Bella** / 🔍 **Casey**: FR4's "no code changes while audits run" is unguarded: the lead fixes one story while another's audit runs tests; `do:132` is a fourth statement → 58-01 Story 1
- **[Warning]** 🧑‍💻 **Bella** / 🔍 **Casey**: `review` writes story-level `**Amended**` lines, which FR7's split leaves unplaced; the maintenance record's date bullet goes stale → 58-01 Story 4, spec FR7
- **[Warning]** 📋 **Jordan** / 🧑‍💻 **Bella** / 🔍 **Casey**: the moved-place table maps partly moved places mechanically and leaves out the browser probe, parallel clause, **Finishing** item and **Back-fill**/**Consolidate** → 58-05 Story 1, spec FR11
- **[Warning]** 📋 **Jordan** / 🧑‍💻 **Bella**: renaming the `shared-assumption` row drops signals at **The loop** → 58-01 Story 5, 58-05 Story 1
- **[Warning]** 📋 **Jordan** / 🧑‍💻 **Bella** / 🔍 **Casey**: walk-through comparison has no fixed tuple, normalisation or noise rule; controls pass on any difference; subagents not limited to named paths → every walk-through criterion
- **[Warning]** 🔍 **Casey**: the builder judges its own mappings and controls → the inventory criteria
- **[Warning]** 📋 **Jordan** / 🧑‍💻 **Bella** / 🔍 **Casey**: `{pre}` written before 58-02's audit goes stale; its 11 files unlisted → 58-02, 58-03
- **[Warning]** 🧑‍💻 **Bella** / 🔍 **Casey**: the history check's `diff {pre}/{file}` is empty for new files → 58-03 to 58-05
- **[Warning]** 🧑‍💻 **Bella** / 🔍 **Casey**: pointers missing at step 4 and step 5; step 3's `[user]` bullet refers to the moved `[browser]` bullet; the parallel clause's pointer would be longer than it → 58-03 Story 1
- **[Warning]** 📋 **Jordan** / 🧑‍💻 **Bella** / 🔍 **Casey**: the >150-word paragraph lists are partial; the self-check and manifest exceptions unbounded → 58-03 to 58-05
- **[Warning]** 🔍 **Casey**: labels other files name are not protected in 58-03 → 58-03
- **[Warning]** 🔍 **Casey**: W16 missing from 58-03 Story 2 → 58-03 Story 2
- **[Warning]** 🔍 **Casey**: key-phrase greps missing or without floors in 58-03 Story 2, 58-04 and 58-05 → those stories
- **[Warning]** 🔍 **Casey** / 🧑‍💻 **Bella**: FR1's walk-through inputs unnamed, one of three cases walked, old wording outside the skills; FR2, FR6 and FR7 walk-throughs have no before control → 58-01
- **[Warning]** 🧑‍💻 **Bella**: the `existing` grep hits `test-runs.md:60`, a different rule; `grep -c` over directories needs `-r` → 58-01 Story 2
- **[Warning]** 🧑‍💻 **Bella** / 🔍 **Casey**: FR6 left the old run rule at `do:29`, `do:55` and `auditor.md:24`; its snapshot criterion already holds at base → 58-01 Story 3
- **[Warning]** 📋 **Jordan** / 🧑‍💻 **Bella** / 🔍 **Casey**: 58-02's docs grep misses FR5–FR8's terms and the maintenance record → 58-02
- **[Warning]** 📋 **Jordan** / 🧑‍💻 **Bella** / 🔍 **Casey**: NFR4's regions have no extraction, no control and miss `test-runs.md`'s mapping → 58-02, 58-04, 58-06
- **[Warning]** 📋 **Jordan** / 🧑‍💻 **Bella** / 🔍 **Casey**: 58-06's maintenance labels do not exist; its grep misses browser and consolidate; `{pre}` deleted before the audit → 58-06 Story 2
- **[Warning]** 🔍 **Casey**: 58-04's W7 control changes nothing unless the case holds a defect only the moved checks catch → 58-04 Story 3
- **[Warning]** 🔍 **Casey**: lessons bearing but not listed (instance-not-rule, set floors, rule stated once, the spot-check lesson) → **Lessons** lines
- **[Warning]** 🧑‍💻 **Bella**: a lesson path wrong (`02`, not `01`) → 58-05
- **[Warning]** 🧑‍💻 **Bella**: 58-05's stories share W16's input; `fixed.md`'s ceiling unchecked before 58-06 → 58-05
- **[Suggestion]** 📋 **Jordan**: redundant Blocked by lines (58-06 on 58-04; 58-01 Story 4 on Story 2)
- **[Suggestion]** 📋 **Jordan**: ~146 walk-throughs; compute each `{pre}` tuple once
- **[Suggestion]** 📋 **Jordan**: 58-05 Story 1 at high effort
- **[Suggestion]** 📋 **Jordan**: deleting `{pre}` is the run's own scratch, not "deleting data"
- **[Suggestion]** 🧑‍💻 **Bella**: write `{pre}` with Bash `cp`
- **[Suggestion]** 🧑‍💻 **Bella**: the quick-record scoped-round directory name
- **[Suggestion]** 🧑‍💻 **Bella**: the words-cut base; the version bump is not the last edit
- **[Suggestion]** 🧑‍💻 **Bella**: every place `fixed.md` names still resolves after bullets
- **[Suggestion]** 🧑‍💻 **Bella**: "paragraph" references found by grep
- **[Suggestion]** 🧑‍💻 **Bella**: walk-throughs read files that do not exist yet (W7, W18)
- **[Suggestion]** 🔍 **Casey**: decide whether FR1–FR7 get `fixed.md` rows
- **[Suggestion]** 🔍 **Casey**: NFR1's "a miss is a `Not met`" in every consolidation epic

## Remediation

- Fixed: "no new warning" → 58-03 Story 1, 58-04 Story 3, 58-05 Story 1
- Fixed: checks kept in `{pre}/checks/`, `{pre}` written at 58-03's start with `cp` and checked against 58-02's close, its 11 files listed → 58-03 **Checks**, 58-02 Story 1
- Fixed: the sweep corpus rebuilt with groups that must be left out, a floor and a row-removal control; the `shared-assumption` row names both places; `fixed.md`'s ceiling → 58-01 Story 5
- Fixed: the revised-file walk-through's expected outcomes, with an unrevised-file case → 58-01 Story 2
- Fixed: walk-through inputs named, FR1's second case, before-text controls for FR1, FR4, FR6 and FR7 → 58-01
- Fixed: FR4's audit-fix rule and `do:132` → 58-01 Story 1 (beyond the spec's FR4; see Needs you)
- Fixed: FR6's neighbours and **A pass** → 58-01 Story 3
- Fixed: the `existing` grep narrowed, with `-r` → 58-01 Story 2
- Fixed: `review`'s story-level `**Amended**` lines and the maintenance record → 58-01 Story 4 (beyond the spec's FR7; see Needs you)
- Fixed: the docs grep widened and run over the maintenance record; the region script with a control and `test-runs.md` → 58-02
- Fixed: a fixed tuple, a noise rule, `{pre}` tuples computed once, path-limited subagents, mappings judged by a fresh agent, `diff -N` → 58-03 **Checks**
- Fixed: every point of use's pointer, step 3's `[user]` bullet, long paragraphs by script, the exceptions bounded, labels protected, W16, key-phrase greps with floors → 58-03 to 58-05
- Fixed: W7's case holds a stale red only the moved checks catch → 58-04 Story 3
- Fixed: the moved-place table completed, partly moved places placed by text → 58-05 Story 1 (beyond the spec's FR11; see Needs you)
- Fixed: lessons added and the lesson path corrected; 58-05 Story 2 after Story 1; 58-05 Story 1 at high effort → **Lessons** lines, 58-05
- Fixed: 58-06's maintenance labels, wider grep, words-cut base, `{pre}` deleted after close → 58-06
- Fixed (Suggestions applied with fixes): `cp`, words-cut base, `fixed.md` places resolve, "paragraph" grep, W7 reading `auditor.md` until moved, 58-06's Blocked by
- Fixed (user's decision, 2026-11-12, through `/cpm-next:plan`): FR2 retakes every red and blocks on `fix needed`; FR3's resumed kind a whole-story audit; FR5 drops the order-dependent Warning and passes baseline results when held; FR4's audit-fix rule; FR7's story-level `**Amended**`; FR10's parallel clause kept; FR11's partly moved places; the Testing Strategy's `{pre}/checks/` → spec amended; 58-01 Story 2, 58-03 Story 1
- Fixed (user's decision, 2026-11-12): two runs, 0.20.0 committed and used before consolidation → 58-02 and 58-03 **Runs**, spec Assumptions
- Not acted on: the remaining Suggestions (FR1–FR7 `fixed.md` rows, the redundant 58-01 Story 4 Blocked by, the quick-record directory name) → recorded only
