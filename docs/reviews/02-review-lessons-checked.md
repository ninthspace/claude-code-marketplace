# Review: Lessons checked against criteria

**Date**: 2026-10-30  
**Source**: docs/epics/47-02-epic-lessons-checked.md  
**Reviewers**: Jordan, Margot, Tomas  
**Findings**: 17 (4 critical, 9 warnings, 4 suggestions)

## Summary

Worth building. No mod parses the new fields: `whats-next/hooks/plan.ts` and `cpm-next-progress/hooks/progress.ts` read only Status, Blocked by, Story and Effort, and no mod reads retros. As written, the epic detected lessons more than it enforced them. The reference form had no stable anchor, the lesson check sat in a list every persona gets, judgement was handed to `scout`, and the grep criterion already passed on the unchanged file. Every Critical and Warning finding was fixed in the Pending stories; none needs the user.

## Findings

- **[Critical]** 🏗️ **Margot**, 📋 **Jordan**, 🔍 **Tomas**: `path#heading` and `retro path` have no stable anchor. Slugs are undefined, amendment headings repeat by date and are removed by `library consolidate`, and retro observations are bullets with no heading  
  → Story 1 criterion 3, Story 3 criterion 3
- **[Critical]** 📋 **Jordan**, 🏗️ **Margot**, 🔍 **Tomas**: deciding which lessons "bear" is a judgement, and `scout` "makes no judgement calls" (`cpm-next/agents/scout.md:3`)  
  → Story 1 criterion 1
- **[Critical]** 🔍 **Tomas**, 🏗️ **Margot**, 📋 **Jordan**: the bullet at `review/SKILL.md:40` is in the list every persona gets (lines 33-40), so extending it there contradicts FR7's one-persona rule  
  → Story 2 criteria 1-2
- **[Critical]** 🔍 **Tomas**, 📋 **Jordan**, 🏗️ **Margot**: `grep -c "retro lesson"` already returns 1 on the unchanged file, so it cannot fail  
  → Story 2 criterion 3
- **[Warning]** 🔍 **Tomas**: naming lessons without reflecting any of them satisfies Story 1  
  → Story 1
- **[Warning]** 📋 **Jordan**: "too large to read whole" has no threshold  
  → Story 1 criterion 1
- **[Warning]** 📋 **Jordan**, 🏗️ **Margot**: build-practice lessons cannot be criteria; forcing them in makes filler, and leaving them out makes review warn every time  
  → Story 1
- **[Warning]** 🔍 **Tomas**: with no `**Lessons**` line, review cannot tell "none bear" from "never checked" (legacy epics, no library)  
  → Story 2
- **[Warning]** 🔍 **Tomas**: there is no rule for conflicting lessons or a superseded library document  
  → Story 1
- **[Warning]** 🔍 **Tomas**: retros are written only when an epic completes, so small changes and story `**Retro**` lines never reach the recurrence rule; a recurrence of an observation retired as no longer true goes unflagged  
  → Story 3 criterion 1
- **[Warning]** 📋 **Jordan**, 🏗️ **Margot**: the **Needs you** item for a recurring library lesson has no handler in `do`'s walk-through (`do/SKILL.md:155-158`), and the fix is a plugin edit outside the project  
  → Story 3 criterion 2
- **[Warning]** 📋 **Jordan**: comparing every retro at Finishing has no bound; `do` reads only retros bearing on the epic's area (`do/SKILL.md:38`)  
  → Story 3
- **[Warning]** 🔍 **Tomas**, 📋 **Jordan**: every story claims NFR2, but no criterion checks it  
  → Stories 1-3
- **[Suggestion]** 📋 **Jordan**: `do`'s small-change criteria never get the lesson rule  
  → Story 3
- **[Suggestion]** 🏗️ **Margot**: this epic has no `**Lessons**` line of its own, though library 01 bears on Story 2's grep  
  → epic header
- **[Suggestion]** 🏗️ **Margot**, 📋 **Jordan**: epics 47-01, 47-02 and 47-04 edit the same paragraphs with no `**Blocked by**` between them  
  → cross-epic
- **[Suggestion]** 🏗️ **Margot**: the contract says library filenames are unnumbered, but this repo's are numbered  
  → contract

## Remediation

- Fixed: unstable anchor → one lesson reference form with three variants (verbatim heading, amendment by its source retro, retro path with the observation's opening words), used by both `**Lessons**` and `**Recurrence**`
- Fixed: scout judging → scout lists candidates when there are more than 20 retro files, and `plan` judges
- Fixed: persona list → the lesson check moves out of the every-persona bullet into an instruction for one persona; no persona is added
- Fixed: grep that cannot fail → controls now grep for `**Lessons**` with a before count of 0, and check that "retro lesson" is gone from the shared bullet list
- Fixed: named but not reflected → each `**Lessons**` entry carries `(Story {N})` or `(build)`, and review checks the named story's criteria
- Fixed: threshold → set at more than 20 retro files
- Fixed: build-practice lessons → `(build)` entries need no criterion
- Fixed: absent line → the lesson persona finds bearing lessons itself when there is no `**Lessons**` line
- Fixed: conflicts → `plan` follows the newer lesson or document and records the choice in Assumptions
- Fixed: recurrence coverage → the check runs whenever `do` writes a retro observation, a story `**Retro**` line or a quick-record observation, including against retired observations; a recurrence of a retired observation is reported under **Found**, since FR16 sends only library-lesson recurrences to **Needs you**
- Fixed: missing handler → the walk-through gives the lesson reference and the plugin file, and leaves the plugin change to the user
- Fixed: unbounded comparison → compared against the library and the retros `do` read at the start
- Fixed: NFR2 → a no-history criterion in each story
- Fixed (with its Warning): the small-change path applies Story 1's rule by reference; the epic has a `**Lessons**` line
- Not acted on: shared paragraphs across epics → `do` builds stories that share files one at a time (`do/SKILL.md`, parallel rule), and the edits are to different sentences
- Not acted on: numbered library filenames → contract drift outside this spec; the reference form quotes the path as it stands
