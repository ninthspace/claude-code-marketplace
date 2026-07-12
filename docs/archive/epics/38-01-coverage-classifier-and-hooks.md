# Coverage Matrix: Classifier & Hook Refactor

**Source spec**: docs/specifications/38-spec-stale-progress-prompt-and-cpm-clean.md
**Epic**: docs/epics/38-01-epic-classifier-and-hooks.md
**Date**: 2026-07-08

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | FR1 Classifier | "classifies each `.cpm-progress-{id}.md` as `CURRENT`, `FRESH` (other session, <3 days), or `STALE` (other session, ≥3 days)" | "Other-session file <3 days classified `FRESH`; ≥3 days classified `STALE`" | Story 1 | `[unit]` | ✓ |
| 2 | FR1 Classifier | "emitting labelled records (path, skill, phase, age)" | "Emits labelled records carrying path, skill, phase, and age for each file" | Story 1 | `[unit]` | ✓ |
| 3 | FR1 Classifier | "Single source of truth for the age + session-ID rules." | "`session-start.sh` orphan output is derived from the helper — no inline duplicate classification remains" | Story 2 | `[integration]` | ✓ |
| 4 | FR7 Threshold | "Staleness threshold = 3 days, as a single named constant defined in the helper (replacing `STALE_HOURS=24`)" | "The 3-day threshold is defined as a single named constant (replacing `STALE_HOURS=24`)"; "Boundary: 3d0h → `STALE`, 2d23h → `FRESH`" | Story 1 | `[unit]` | ✓ |
| 5 | FR9 Robustness | "Cross-platform `stat` (macOS/Linux), graceful skip of malformed/unreadable files, never block session startup or a skill on error." | "Cross-platform `stat`"; "Malformed/unreadable file is skipped; helper still exits cleanly" | Story 1 | `[unit]` | ✓ |
| 6 | FR6 Confirmation | "No code path auto-executes a delete." | "must NOT execute any deletion (the helper never runs `rm`)" | Story 1 | `[unit]` | ✓ |
| 7 | FR2 `/clear` fix | "On `/clear`, other-session/stale files are no longer silently injected as active state." | "On `clear`, other-session/stale files are NOT injected as active state"; "must NOT blanket-`cat` all progress files as active state on `clear`" | Story 3 | `[unit]` | ✓ |
| 8 | FR4 Non-blocking | "BLOCKING behaviour removed." | "Hook output contains no `BLOCKING`/halt language"; "must NOT emit `BLOCKING` language or instruct the session to stop before proceeding" | Story 2 | `[unit]` | ✓ |
| 9 | FR4 Three-way | "Stale other-session → offered for deletion; fresh other-session → informational only ..., never offered for deletion, never silent; current-session → active state as today." | "Stale other-session files are labelled as cleanup candidates; fresh other-session files are labelled informational"; "Fresh/stale distinction is presented to the user appropriately (stale→offer, fresh→informational)" | Story 2 | `[unit]` / `[manual]` | ✓ |
