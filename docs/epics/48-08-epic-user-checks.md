# User checks for spec 48

**Source spec**: docs/specifications/48-spec-learning-at-recurrence.md  
**Date**: 2026-10-30  
**Status**: Pending  
**Blocked by**: Epic 48-02-epic-signals-in-do, Epic 48-05-epic-library-sweep, Epic 48-07-epic-release  
**Lessons**: docs/library/01-library-lessons-learned.md → "A must-NOT stated as an equality is a change detector, and a set comparison needs a floor" (Story 1)  
**Amended**: 2026-10-30 — rewritten after review 06 (docs/reviews/06-review-learning-at-recurrence.md)

These checks are carried out by the user after release; `do` writes each `Evidence` line only from the user's answer.

## Learning at recurrence works in an installed release
**Story**: 1  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR1, FR3, FR4, FR7, FR10, FR11

**Acceptance Criteria**:

- The user pushes the release, restarts, and confirms `claude plugin list` shows cpm-next 0.10.0. The observation is the version shown `[user]`
- In a scratch repository with no `docs/library/`, the user writes two one-story epics, A and B, each with a criterion the code cannot meet (for example "`config/app.php` sets `timezone` to `Mars/Olympus`" in a repository with no such file), and runs `/cpm-next:do` on A, then on B. The observation is a `**Signal**` on each blocked story, B's with a ` — recurs:` suffix citing A's signal, a promotion candidate under **Needs you** at the end of B's run, and no file written to `docs/retros/` `[user]`
- The user answers yes to that candidate. The observation is `docs/library/lessons-learned.md` created with an entry carrying `**Class**` equal to the signal's slug and `**Source**` naming both signals, and both signals marked ` — promoted` `[user]`
- In the same repository, the user hand-writes in epic C a signal with the same slug and a one-line failure about something unrelated (for example "a migration was run against production"), then writes epic D with a criterion that fails for an unrelated reason (a test that asserts `1 === 2`) and runs `/cpm-next:do` on D. The observation is that D's blocked story carries a `**Signal**` and that it has no ` — recurs:` suffix citing C `[user]`
- In a second scratch repository, the user repeats the A and B steps and answers no. The observation is both signals marked ` — declined`; a further `/cpm-next:do` run on B raises no candidate `[user]`
- With three scratch repositories (two each holding a `process` signal naming `cpm-next/skills/do/SKILL.md` step 4, one holding a `process` signal naming step 3) and one path that does not exist, all added with `/cpm-next:library sweep add`, the user runs `/cpm-next:library sweep`. The observation is one group reported with the two step-4 signals, the step-3 signal named as not reported, the missing path reported, and `git status` clean in all three repositories `[user]`

### Run the checks
**Task**: 1.1  
**Description**: Carried out by the user; `do` writes the `Evidence (user, …)` lines from their answers.  
**Status**: Pending

---
