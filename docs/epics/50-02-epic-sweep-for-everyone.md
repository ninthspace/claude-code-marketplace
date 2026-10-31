# Sweep for everyone who installs the plugin

**Source spec**: docs/specifications/50-spec-sweep-for-an-open-source-plugin.md  
**Date**: 2026-10-31  
**Status**: Pending  
**Blocked by**: Epic 50-01-epic-versioned-signals  
**Lessons**: docs/library/01-library-lessons-learned.md → "A must-NOT stated as an equality is a change detector, and a set comparison needs a floor" (Story 1), docs/library/01-library-lessons-learned.md → "A must-NOT stated as an equality is a change detector, and a set comparison needs a floor" (Story 2)

## Fixed groups are left out, and versions shown
**Story**: 1  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR3

**Acceptance Criteria**:

- `cpm-next/skills/library/SKILL.md` **Sweep** reads `shared/fixed.md` from the installed plugin and leaves out a group when a row matches its file and step (and its class, when the row names one) and every signal in the group was seen under an earlier version than the row's; it names each such group as fixed, with the version `[manual]`
- A signal with no version counts as not fixed; control: **Sweep** says a group with any signal seen at or after the fix version, or with no version, is reported `[manual]`
- The report shows, for each group, the versions its signals were seen under `[manual]`

### Edit Sweep for the fixed list
**Task**: 1.1  
**Description**: Amend `library/SKILL.md` **Sweep**.  
**Status**: Pending

---

## The issue draft outside the plugin's repository
**Story**: 2  
**Status**: Pending  
**Blocked by**: Story 1  
**Satisfies**: FR4, FR5, FR6  
**Effort**: high

**Acceptance Criteria**:

- **Sweep** tests whether the current repository is the plugin's own source (its root holds `cpm-next/.claude-plugin/plugin.json` naming `cpm-next`); there it offers the discussion record as before, and anywhere else it offers an issue draft and writes no discussion record `[manual]`
- **Sweep** says the draft holds, for each reported group, the class slug, the cpm-next file and step, a generic one-line description, the versions seen and how many repositories showed it, with a title naming the file, step and class; and that it never holds a repository name or path, a file or symbol from those repositories, code, or signal text quoted from them; control: it says the description is written afresh from the signals, not copied `[manual]`
- **Sweep** says the draft is shown in full first, and that filing is then one AskUserQuestion call: file it with `gh issue create --repo {owner/name from the installed plugin's repository field} --title … --body-file …`, or keep it as text with `{repository}/issues/new`; control: it says nothing is filed without that yes, and when `gh` is missing or not signed in only the draft and the URL are given `[manual]`

### Edit Sweep for the two branches
**Task**: 2.1  
**Description**: Amend `library/SKILL.md` **Sweep**.  
**Status**: Pending

---
