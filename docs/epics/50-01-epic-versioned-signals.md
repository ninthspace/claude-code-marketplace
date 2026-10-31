# Versioned process signals and the fixed list

**Source spec**: docs/specifications/50-spec-sweep-for-an-open-source-plugin.md  
**Date**: 2026-10-31  
**Status**: Pending  
**Blocked by**: —  
**Lessons**: docs/library/01-library-lessons-learned.md → "A must-NOT stated as an equality is a change detector, and a set comparison needs a floor" (Story 1)

## Signals carry a version; the plugin names its repository
**Story**: 1  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR1, FR7

**Acceptance Criteria**:

- `cpm-next/shared/artifacts.md` **Signals** shows the `process` form with ` — cpm-next {version}` after the parenthesis, says the version is read from the installed plugin's `.claude-plugin/plugin.json`, and says a `project` signal carries none; control: the `project` form shown has no version segment `[manual]`
- `cpm-next/skills/do/SKILL.md` **Signals** says to read the installed version and write it on each `process` signal `[manual]`
- `cpm-next/.claude-plugin/plugin.json` has `"repository": "https://github.com/ninthspace/claude-code-marketplace"`, and `claude plugin validate cpm-next` passes `[manual]`

### Edit the contract, do and the manifest
**Task**: 1.1  
**Description**: Amend `artifacts.md` **Signals**, `do/SKILL.md` **Signals** and `plugin.json`.  
**Status**: Pending

---

## The fixed list
**Story**: 2  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR2

**Acceptance Criteria**:

- `cpm-next/shared/fixed.md` exists with a table whose columns are the cpm-next file and step, the class slug, the version that fixed it, and what changed, and a line saying a release that fixes a `process` failure adds a row `[manual]`
- It holds a seed row for each 0.9.0 to 0.11.0 entry in `cpm-next/README.md` that fixes a failure at a named cpm-next file and step, each citing that entry's version; every seed row's file and step exists in the current skill or agent file `[manual]`
- The contract's **Where things live** table names `shared/fixed.md`, written by the maintainer and read by `library` `[manual]`

### Write the fixed list
**Task**: 2.1  
**Description**: Add `cpm-next/shared/fixed.md` and its row in the contract's table.  
**Status**: Pending

---
