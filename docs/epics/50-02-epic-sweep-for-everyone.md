# Sweep for everyone who installs the plugin

**Source spec**: docs/specifications/50-spec-sweep-for-an-open-source-plugin.md  
**Date**: 2026-10-31  
**Status**: Complete  
**Blocked by**: Epic 50-01-epic-versioned-signals  
**Lessons**: docs/library/01-library-lessons-learned.md → "A must-NOT stated as an equality is a change detector, and a set comparison needs a floor" (Story 1), docs/library/01-library-lessons-learned.md → "A must-NOT stated as an equality is a change detector, and a set comparison needs a floor" (Story 2)

## Fixed groups are left out, and versions shown
**Story**: 1  
**Status**: Complete  
**Audit**: pass (2026-10-31), 2 findings fixed — the last fix was not audited, at the user's decision
**Blocked by**: —  
**Satisfies**: FR3  
**Signal**: definition-in-two-places — project — the leave-out rule was stated per group in the sweep and per signal in the fixed list's opening (`cpm-next/skills/library/SKILL.md` **Sweep**, `cpm-next/shared/fixed.md`, audit round 1)

**Acceptance Criteria**:

- `cpm-next/skills/library/SKILL.md` **Sweep** reads `shared/fixed.md` from the installed plugin and leaves out a group when a row matches its file and step (and its class, when the row names one) and every signal in the group was seen under an earlier version than the row's; it names each such group as fixed, with the version `[manual]`
  - Evidence: `cpm-next/skills/library/SKILL.md` **Sweep**, third paragraph: a row covers a signal when it names its file and placed step (any formatting; several steps each match), its class or `any`, and a higher version, compared as numbers; "A group is left out only when a row covers every signal in it"; each is "named as fixed, with the version of the earliest row covering each signal (the highest of them when they differ)" and listed apart; every signal in a group must be covered by some row, not necessarily the same one; `shared/fixed.md`'s opening names this rule in **Sweep** as the one that decides coverage and states only that Class `any` means any class — red: n/a — manual
- A signal with no version counts as not fixed; control: **Sweep** says a group with any signal seen at or after the fix version, or with no version, is reported `[manual]`
  - Evidence: the same paragraph: "A version that is not plain `major.minor.patch`, a missing version, and a retro observation all count as no version, which no row covers … a group with any other signal is reported, and so is one no row matches" — red: n/a — manual
- The report shows, for each group, the versions its signals were seen under `[manual]`
  - Evidence: **Sweep**'s second paragraph now reads "each group found in two or more repositories with its signals (repository, signal reference, version, what failed) and the versions its signals were seen under" — red: n/a — manual

### Edit Sweep for the fixed list
**Task**: 1.1  
**Description**: Amend `library/SKILL.md` **Sweep**.  
**Status**: Complete

---

## The issue draft outside the plugin's repository
**Story**: 2  
**Status**: Complete  
**Audit**: pass (2026-10-31), 5 findings fixed — the last fix was not audited, at the user's decision; with several reported groups the title names only their number, which departs from FR5's "names the file, the step and the class" to keep project-derived text out
**Blocked by**: Story 1  
**Satisfies**: FR4, FR5, FR6  
**Signal**: instance-not-rule — project — the draft's privacy rule banned names, paths, code and quotes but not project terms, and gave the user no way to change the draft (`cpm-next/skills/library/SKILL.md` **Sweep**, audit round 1)  
**Effort**: high

**Acceptance Criteria**:

- **Sweep** tests whether the current repository is the plugin's own source (its root holds `cpm-next/.claude-plugin/plugin.json` naming `cpm-next`); there it offers the discussion record as before, and anywhere else it offers an issue draft and writes no discussion record `[manual]`
  - Evidence: **Sweep**, fourth paragraph: "tests whether the current repository is the plugin's own source: the git top level holds `cpm-next/.claude-plugin/plugin.json` whose `name` is `cpm-next`"; the fifth keeps the discussion record "In the plugin's own repository"; the sixth opens "Anywhere else it writes no discussion record and offers an issue draft instead" and "With no reported group it offers nothing" — red: n/a — manual
- **Sweep** says the draft holds, for each reported group, the class slug, the cpm-next file and step, a generic one-line description, the versions seen and how many repositories showed it, with a title naming the file, step and class; and that it never holds a repository name or path, a file or symbol from those repositories, code, or signal text quoted from them; control: it says the description is written afresh from the signals, not copied `[manual]`
  - Evidence: **Sweep**, sixth paragraph: each entry holds its class slugs (each one the contract's seeds or `shared/fixed.md` name, none other), "a one-line description of the failure", the versions and "how many repositories showed it"; with one reported group the title names its file and step, and its class when its entry holds exactly one slug; with several it names the number of groups; "The description is generic: written afresh from the signals, never copied from them, and naming nothing of the project or its domain"; "no repository name or path, no file, symbol or term from those repositories, no code and no signal text quoted from them" — red: n/a — manual
- **Sweep** says the draft is shown in full first, and that filing is then one AskUserQuestion call: file it with `gh issue create --repo {owner/name from the installed plugin's repository field} --title … --body-file …`, or keep it as text with `{repository}/issues/new`; control: it says nothing is filed without that yes, and when `gh` is missing or not signed in only the draft and the URL are given `[manual]`
  - Evidence: **Sweep**, seventh paragraph: "shows the draft in full", then "one AskUserQuestion call: file it, keep it as text, or change it" (change shows the revised draft and asks again); "Only the file-it answer files anything"; `gh issue create --repo {owner/name} --title … --body-file …` with owner and name from the installed plugin's `repository` field; keeping it as text gives `{repository}/issues/new`; with `gh` missing or not signed in, or no GitHub field, it "gives what keeping the draft as text gives, with the reason, and asks nothing" (the draft and the URL) — red: n/a — manual

### Edit Sweep for the two branches
**Task**: 2.1  
**Description**: Amend `library/SKILL.md` **Sweep**.  
**Status**: Complete

---
