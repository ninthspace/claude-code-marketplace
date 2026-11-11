# User checks: the tracker during a real run

**Source spec**: docs/specifications/55-spec-tracker-split-view.md  
**Date**: 2026-11-11  
**Status**: Pending  
**Blocked by**: Epic 55-03-epic-release  
**Amended**: review 12 (docs/reviews/12-review-tracker-split-view.md) — the total "rises by 2" after `/progress-tracker`, the test decisions removed afterwards, the model check against the planned model, and the sticky detail on claude.ai (2026-11-11)  
**Lessons**: docs/library/01-library-lessons-learned.md → "A criterion that needs an observation the session cannot make is a `[user]` check" (Story 1)

## The republished tracker during a do run
**Story**: 1  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR1, FR4, FR5, FR10

**Acceptance Criteria**:

- After installing cpm-next-progress 0.9.0 (a push to main, then `/reload-plugins` in an open session of a project with a published tracker), run `/progress-tracker {nn}` for that spec. Proves it: Claude republishes to the same link, writes the rows, and the claude.ai page shows the split view with the table's seven columns and a selected row's detail `[user]`
- On that page in a desktop browser, scroll the table to its last row and select it. Proves it: the detail panel is still in view beside the table, showing that row `[user]`
- Note the page's Needs you total. Add a decision `[{epic} S{n}, question] {text}` to the build-order file for a story in the tracker, and one with no prefix, then run `/progress-tracker` and let Claude write. Proves it: that story's row badge rises by 1, its detail lists the question, the strip lists the unprefixed decision, and the total rises by 2. Then remove both decisions and run `/progress-tracker` again `[user]`
- Before running `/cpm-next:do` on a Pending story in that spec, see its Model cell muted (the planned model). Run the story and open the tracker while it runs. Proves it: the row's Model cell is no longer muted and names the run's model, `/progress-tracker times` shows `({effort}, {model})` for it, and its Time cell shows `{n} min in` rising each minute; once it closes, `took {n} min` `[user]`

---
