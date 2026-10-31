# User checks for spec 50

**Source spec**: docs/specifications/50-spec-sweep-for-an-open-source-plugin.md  
**Date**: 2026-10-31  
**Status**: Complete  
**Blocked by**: Epic 50-03-epic-release

These checks are carried out by the user after release; `do` writes each `Evidence` line only from the user's answer.

## Sweep works for someone outside the plugin's repository
**Story**: 1  
**Status**: Complete  
**Audit**: pass (2026-10-31), 1 finding fixed  
**Blocked by**: —  
**Satisfies**: FR1, FR3, FR4, FR5, FR6

**Acceptance Criteria**:

- In two scratch repositories named `acme-payroll-zx9` and `acme-billing-qq4`, each with an epic holding a `process` signal at `cpm-next/skills/do/SKILL.md` step 4 that names a file `PayrollRunnerZx9.php`, the user runs `/cpm-next:library sweep` from a third scratch repository (not the plugin's). The observation is an issue draft for that group naming the file, step, class, versions and "2 repositories", with neither repository name, nor `PayrollRunnerZx9`, nor any path from them anywhere in it, and no discussion record written `[user]`
  - Evidence (user, 2026-10-31): from a session in a third scratch repository, after `sweep add` of both, `/cpm-next:library sweep` reported "The sweep of 2 repositories found the same check-cannot-fail problem in cpm-next's do step 4 in both" and showed a draft titled "do step 4: check-cannot-fail seen in 2 repositories" with `cpm-next/skills/do/SKILL.md` step 4, Class `check-cannot-fail`, Failure (a generic sentence), Versions seen cpm-next 0.11.0 and Repositories showing it 2; it held no repository name, no `PayrollRunnerZx9` and no path, and the skill said it wrote no files (screenshot); afterwards `third-scratch` held only `docs/epics/`, no `docs/discussions/`, and `git status` there was empty (checked by the lead) — red: n/a — user
- The user answers to keep it as text. The observation is the draft and a `https://github.com/ninthspace/claude-code-marketplace/issues/new` URL, and nothing filed (no new issue in the repository) `[user]`
  - Evidence (user, 2026-10-31): chose "Keep as text"; the skill replied "I filed nothing. You can post the draft as an issue at https://github.com/ninthspace/claude-code-marketplace/issues/new" followed by the title and body (screenshot); `gh issue list` on the repository shows no issue created today — red: n/a — user
- With a row added to the installed plugin's `shared/fixed.md` for that file and step at a version later than both signals', the user runs the sweep again. The observation is the group named as fixed, with the version, and not in the draft `[user]`
  - Evidence (user, 2026-10-31): with the row ``| `cpm-next/skills/do/SKILL.md` step 4 | check-cannot-fail | 0.11.5 | scratch row for the user check |`` saved in the installed `shared/fixed.md` (a first run before the file was saved still reported the group, which was the unsaved edit, not the plugin), the sweep reported "Reported: none" and "Fixed in 0.11.5: cpm-next/skills/do/SKILL.md step 4, class check-cannot-fail, seen in both repositories under cpm-next 0.11.0", and "No group is reported, so I offered no issue draft and no discussion record" (screenshot) — red: n/a — user
- In this repository (the plugin's own), the user runs the sweep. The observation is the offer of a discussion record, not an issue draft `[user]`
  - Evidence (user, 2026-10-31): in a session started in `~/Work/git/claude-code-marketplace`, with the scratch row removed, `/cpm-next:library sweep` reported "1 reported group: do/SKILL.md step 4, check-cannot-fail, seen at cpm-next 0.11.0 in acme-payroll-zx9 and acme-billing-qq4 (no fixed.md row covers 0.11.0)" and asked "Write the discussion record docs/discussions/24-discussion-sweep-2026-10-31.md for /cpm-next:plan?" with Write it / Don't write, and offered no issue draft (screenshot) — red: n/a — user

### Run the checks
**Task**: 1.1  
**Description**: Carried out by the user; `do` writes the `Evidence (user, …)` lines from their answers.  
**Status**: Complete

---
