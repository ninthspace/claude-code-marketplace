# User checks for spec 47

**Source spec**: docs/specifications/47-spec-checks-that-can-fail.md  
**Date**: 2026-10-30  
**Status**: Pending  
**Blocked by**: Epic 47-05-epic-release, Epic 47-07-epic-after-release-fixes  
**Amended**: 2026-10-30 — also blocked by 47-07, whose fixes the release carries

These checks are carried out by the user after release. `do` writes no `Evidence` line for any of them from its own work; it lists them under **Needs you** and writes each line from the user's answer.

## The released rules work in another project
**Story**: 1  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR1, FR3, FR12, FR13

**Acceptance Criteria**:

- The user commits and pushes the release to `main`, then confirms that `.git/plugin-update.log` records the cpm-next update and `claude plugin list` shows cpm-next 0.9.0, and starts a new session in the other project. The observation is the version shown `[user]`
- In another project, the user runs `/cpm-next:do add a test that the {model} list is empty when no {model} exists, asserting an empty collection against an empty collection`. The run either records a red result from a real failing assertion after strengthening the test, or the auditor reports the missing or implausible red as a Warning. The observation is the `Evidence` line and audit verdict in that project's quick record `[user]`
- In a project with a page and no browser test tool, with its local server running, the user runs `do` on a story with a `[browser]` criterion. Its `Evidence` line names a `localhost`, `127.0.0.1` or `.test` URL, the steps, and an excerpt of the page text `[user]`

### Run the three checks
**Task**: 1.1  
**Description**: Carried out by the user; `do` writes the `Evidence (user, …)` lines from their answers.  
**Status**: Pending

---
