# Versioned process signals and the fixed list

**Source spec**: docs/specifications/50-spec-sweep-for-an-open-source-plugin.md  
**Date**: 2026-10-31  
**Status**: Complete  
**Blocked by**: —  
**Lessons**: docs/library/01-library-lessons-learned.md → "A must-NOT stated as an equality is a change detector, and a set comparison needs a floor" (Story 1)

## Signals carry a version; the plugin names its repository
**Story**: 1  
**Status**: Complete  
**Audit**: pass (2026-10-31)  
**Blocked by**: —  
**Satisfies**: FR1, FR7

**Acceptance Criteria**:

- `cpm-next/shared/artifacts.md` **Signals** shows the `process` form with ` — cpm-next {version}` after the parenthesis, says the version is read from the installed plugin's `.claude-plugin/plugin.json`, and says a `project` signal carries none; control: the `project` form shown has no version segment `[manual]`
  - Evidence: `cpm-next/shared/artifacts.md:176` adds `{ — cpm-next {version}}` to the signal form; `:181-182` show a `process` example ending ` — cpm-next 0.11.0` and a `project` example with no version segment; `:185` says a `process` signal carries the version from the installed plugin's `.claude-plugin/plugin.json` and a `project` signal carries none — red: n/a — manual
- `cpm-next/skills/do/SKILL.md` **Signals** says to read the installed version and write it on each `process` signal `[manual]`
  - Evidence: `cpm-next/skills/do/SKILL.md:112` — a `process` signal "ends its description with ` — cpm-next {version}`, the `version` in the installed plugin's `.claude-plugin/plugin.json` (at the plugin root, two levels above this skill's directory); a `project` signal carries no version" — red: n/a — manual
- `cpm-next/.claude-plugin/plugin.json` has `"repository": "https://github.com/ninthspace/claude-code-marketplace"`, and `claude plugin validate cpm-next` passes `[manual]`
  - Evidence: `cpm-next/.claude-plugin/plugin.json` line 5 reads `"repository": "https://github.com/ninthspace/claude-code-marketplace"`; `claude plugin validate cpm-next` — Validation passed — red: n/a — manual

### Edit the contract, do and the manifest
**Task**: 1.1  
**Description**: Amend `artifacts.md` **Signals**, `do/SKILL.md` **Signals** and `plugin.json`.  
**Status**: Complete

---

## The fixed list
**Story**: 2  
**Status**: Complete  
**Audit**: pass (2026-10-31), 2 findings fixed — the last fix was not audited, at the user's decision
**Blocked by**: —  
**Satisfies**: FR2

**Acceptance Criteria**:

- `cpm-next/shared/fixed.md` exists with a table whose columns are the cpm-next file and step, the class slug, the version that fixed it, and what changed, and a line saying a release that fixes a `process` failure adds a row `[manual]`
  - Evidence: `cpm-next/shared/fixed.md` holds a table with the columns "cpm-next file and step", "Class", "Fixed in" and "What changed", and an opening paragraph saying a release that fixes a `process` failure adds a row — red: n/a — manual
- It holds a seed row for each 0.9.0 to 0.11.0 entry in `cpm-next/README.md` that fixes a failure at a named cpm-next file and step, each citing that entry's version; every seed row's file and step exists in the current skill or agent file `[manual]`
  - Evidence: eighteen rows, each citing 0.9.0, 0.10.0 or 0.11.0 and each drawn from a `cpm-next/README.md` entry of that release (red-first evidence and the auditor's reading of it; negative-criterion controls; `[user]` and unprovable criteria and skipped waiting stories; per-run scratch directories and the isolation check; lessons applied and checked; criteria over the rule, in `plan` and `review`; Pivot deferred commands; red passes and the manifest; the suite-free handshake in `do` and the auditor; browser checks said early); every file and step exists (`grep -n` finds `do/SKILL.md` step 3, step 4, `Scratch directories and isolation`, `Audit`, `Finishing`, `Scope and finish line`, `Before the first story`; `plan/SKILL.md` `Epics` and `Lessons`; `review/SKILL.md` `2. Review independently`; `auditor.md` checks 1, 5, 6 and 8, and the small-change paragraph of `do/SKILL.md` Scope and finish line); the opening paragraph says a Class of `any` means any class and how two matching rows combine — red: n/a — manual
- The contract's **Where things live** table names `shared/fixed.md`, written by the maintainer and read by `library` `[manual]`
  - Evidence: `cpm-next/shared/artifacts.md` **Where things live** has the row `| Fixed-in list | `shared/fixed.md` at the plugin root | the maintainer, with each release that fixes a `process` failure; library reads it |` — red: n/a — manual

### Write the fixed list
**Task**: 2.1  
**Description**: Add `cpm-next/shared/fixed.md` and its row in the contract's table.  
**Status**: Complete

---
