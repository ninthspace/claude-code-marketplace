# library sweep finds process failures across repositories

**Source spec**: docs/specifications/48-spec-learning-at-recurrence.md  
**Date**: 2026-10-30  
**Status**: Complete  
**Blocked by**: Epic 48-04-epic-library-learn  
**Lessons**: docs/library/01-library-lessons-learned.md → "A sweep that reads this repository's own text will read its prose and its planted controls" (Story 1)  
**Amended**: 2026-10-30 — rewritten after review 06 (docs/reviews/06-review-learning-at-recurrence.md)

## sweep reads registered repositories and groups process failures by rule
**Story**: 1  
**Status**: Complete  
**Audit**: pass (2026-10-30), 6 findings fixed  
**Blocked by**: —  
**Satisfies**: FR10, NFR2  
**Effort**: high

**Acceptance Criteria**:

- `cpm-next/skills/library/SKILL.md` adds `sweep`, `sweep add {path}` (storing the resolved path, refusing a duplicate), `sweep remove {path}` and `sweep list` to its argument table, keeping the list at `~/.claude/cpm-next/repos.txt`, one absolute path per line, and creating the directory on the first `add`; a missing or empty list, or a listed path that no longer exists, can't be read or holds none of `docs/epics/`, `docs/archive/epics/`, `docs/quick/` and `docs/retros/`, is reported with how to fix it and the sweep carries on with the rest `[manual]`
  - Evidence: `cpm-next/skills/library/SKILL.md:20-:21` (argument table) and `:46` (**Sweep**) add `sweep`, `sweep add {path}` (storing the symlink-resolved path, the existing parent resolved for a missing one, refusing a duplicate), `sweep remove {path}` (resolving its argument alike) and `sweep list`, keeping the list at `~/.claude/cpm-next/repos.txt`, one absolute path per line, creating the directory on the first add; a missing or empty list is reported with how to add a repository, a path that no longer exists or holds none of `docs/epics/`, `docs/archive/epics/`, `docs/quick/` and `docs/retros/` is reported with `sweep remove {path}` or a corrected path and skipped, an unreadable one is reported with the advice to allow the read, and the sweep carries on — red: n/a — manual
- `sweep` collects `process` signals, as `**Signal**:` field lines at the start of a line in story bodies and quick records, so a template quoted in prose or code is not counted, from each listed repository's `docs/epics/` and `docs/quick/`, and unretired legacy retro observations that name a cpm-next skill or rule; groups them by the cpm-next file and step named, using the slug as a hint and reading to confirm; and reports each group found in two or more repositories with its signals. Control: a group found in one repository only, or in one repository listed twice, is named as not reported, and this repository's `docs/epics/48-*` criterion text yields no signal `[manual]`
  - Evidence: `library/SKILL.md:48` collects `process` signals as `**Signal**:` field lines at the start of a line from `docs/epics/`, `docs/archive/epics/` and `docs/quick/` of each listed repository, plus unretired legacy observations naming a cpm-next skill or rule (a v3 skill counts as its counterpart), places each at the file and step it involves (unplaceable ones listed as unplaced), groups by it with the slug as a hint, reports each group in two or more distinct resolved repositories (`:46` reads each distinct path once and counts distinct paths) and names a one-repository group as not reported. Control: a template quoted in prose or code is not counted: `grep -rE '\*\*Signal\*\*'` over `docs/epics`, `docs/archive/epics` and `docs/quick` matches 12 quoted-template lines and `grep -rE '^\*\*Signal\*\*:'` matches 0, so the sweep counts none from `docs/epics/48-*` — red: n/a — manual
- `sweep` writes no file in any scanned repository except one discussion record `docs/discussions/{nn}-discussion-sweep-{YYYY-MM-DD}.md` in the current repository, on the user's choice, even when the current repository is also listed; the contract's artefact table names `library sweep` as a writer of that record `[manual]`
  - Evidence: `library/SKILL.md:50` writes nothing in any scanned repository and never marks or edits a signal; on the user's choice it writes one discussion record `docs/discussions/{nn}-discussion-sweep-{YYYY-MM-DD}.md` in the current repository even when it is also listed; `cpm-next/shared/artifacts.md:9` names `library sweep` as a writer of the discussion record. The skill names no other write path — red: n/a — manual
- No added sentence names a project, retro, version or earlier behaviour `[manual]`
  - Evidence: added lines read; the history grep returns nothing — red: n/a — manual

### Add the sweep mode
**Task**: 1.1  
**Description**: Edit the argument table and add a Sweep section to `library/SKILL.md`; add `library sweep` to the discussion row of the artefact table in `cpm-next/shared/artifacts.md`.  
**Status**: Complete

---
