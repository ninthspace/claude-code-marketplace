# Coverage Matrix: /cpm:clean Command

**Source spec**: docs/specifications/38-spec-stale-progress-prompt-and-cpm-clean.md
**Epic**: docs/epics/38-03-epic-cpm-clean-command.md
**Date**: 2026-07-08

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | FR5 `/cpm:clean` | "Exhaustive, on-demand: lists all progress + compact-summary files with age + session label" | "Lists all `.cpm-progress-*.md` and `.cpm-compact-summary-*.md` files with age and session label (via the classifier's list-all mode)" | Story 1 | `[manual]` | |
| 2 | FR5 `/cpm:clean` | "deletes only files the user names; no sentinel, no staleness filter" | "Deletes only files the user explicitly names"; "must NOT apply a staleness filter or sentinel — exhaustive, on-demand listing every time" | Story 1 | `[manual]` | |
| 3 | FR6 Confirmation | "the user always sees what is being removed first" | "must NOT delete any file the user did not name" | Story 1 | `[manual]` | |
| 4 | FR8 Companions | "Compact-summary companions (`.cpm-compact-summary-{id}.md`) are handled alongside their progress files (listed/cleaned together)." | "Compact-summary companion files are listed alongside their progress file" | Story 1 | `[manual]` | |
