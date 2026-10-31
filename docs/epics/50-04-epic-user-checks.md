# User checks for spec 50

**Source spec**: docs/specifications/50-spec-sweep-for-an-open-source-plugin.md  
**Date**: 2026-10-31  
**Status**: Pending  
**Blocked by**: Epic 50-03-epic-release

These checks are carried out by the user after release; `do` writes each `Evidence` line only from the user's answer.

## Sweep works for someone outside the plugin's repository
**Story**: 1  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR1, FR3, FR4, FR5, FR6

**Acceptance Criteria**:

- In two scratch repositories named `acme-payroll-zx9` and `acme-billing-qq4`, each with an epic holding a `process` signal at `cpm-next/skills/do/SKILL.md` step 4 that names a file `PayrollRunnerZx9.php`, the user runs `/cpm-next:library sweep` from a third scratch repository (not the plugin's). The observation is an issue draft for that group naming the file, step, class, versions and "2 repositories", with neither repository name, nor `PayrollRunnerZx9`, nor any path from them anywhere in it, and no discussion record written `[user]`
- The user answers to keep it as text. The observation is the draft and a `https://github.com/ninthspace/claude-code-marketplace/issues/new` URL, and nothing filed (no new issue in the repository) `[user]`
- With a row added to the installed plugin's `shared/fixed.md` for that file and step at a version later than both signals', the user runs the sweep again. The observation is the group named as fixed, with the version, and not in the draft `[user]`
- In this repository (the plugin's own), the user runs the sweep. The observation is the offer of a discussion record, not an issue draft `[user]`

### Run the checks
**Task**: 1.1  
**Description**: Carried out by the user; `do` writes the `Evidence (user, …)` lines from their answers.  
**Status**: Pending

---
