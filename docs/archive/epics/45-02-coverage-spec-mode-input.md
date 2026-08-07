# Coverage Matrix: Spec Mode Input

**Source spec**: docs/specifications/45-spec-delivery-autonomy.md
**Epic**: docs/epics/45-02-epic-spec-mode-input.md
**Date**: 2026-07-26

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|---|---|---|---|---|---|
| 1 | FR1 | A spec path is a **fourth input shape** on `cpm:ralph`. Mode detection comes from the path itself; no flag, no new skill. | A path under `docs/specifications/` resolves spec mode; epic paths or a range resolve epic mode; nothing resolves auto-discovery | Story 1 | `[integration]` | ✓ |
| 2 | FR1 (must NOT) | must NOT require a flag to select the mode | must NOT require a flag to select the mode | Story 1 | `[integration]` | ✓ |
| 3 | FR2 | **Empty arguments keep today's meaning**: auto-discover all incomplete epics. Silently promoting that to spec-hunting breaks a working invocation. | Empty arguments still auto-discover all incomplete epics | Story 2 | `[integration]` | ✓ |
| 4 | FR2 (must NOT) | must NOT change the behaviour of any existing documented invocation | must NOT change the behaviour of any existing documented invocation | Story 2 | `[integration]` | ✓ |
| 5 | FR3 | Pre-flight **tolerates zero epics** when a spec path was given. Today Step 1a stops with "No incomplete epics found. Nothing to run." — in spec mode that is the starting state, not a failure. | With a spec path and zero epics on disk, pre-flight proceeds to phase 1 | Story 3 | `[integration]` | ✓ |
| 6 | FR3 (must NOT) | must NOT emit "No incomplete epics found. Nothing to run." when a spec path was given | must NOT emit "No incomplete epics found. Nothing to run." when a spec path was given | Story 3 | `[integration]` | ✓ |
| 7 | FR1, FR2, FR3 (story-originated) | — | Each of the four input shapes reaches its documented pre-flight outcome, with zero epics on disk and with epics present | Story 4 | — | ✓ |

## Notes

**Row 7 is `(story-originated)`** — it is not in spec 45's Acceptance Criteria Coverage table. Rows 1–6 each assert one input shape's behaviour in isolation; the failure this epic is most exposed to is an edit that is correct for the shape it was written for and wrong for one of the other three. Row 7 asserts the four shapes against both disk states — eight combinations — which is a claim no single story's criteria reach.

**Row 6 quotes a message that must survive verbatim in three of four shapes.** "No incomplete epics found. Nothing to run." is `cpm:ralph` Step 1a step 3's exact text today. The must-NOT forbids it only when a spec path was given, so a mode-blind deletion satisfies row 6 while breaking row 3 — which is why row 4's regression net and row 7's combination check both exist.

**Rows 2, 4 and 6 quote the spec's testing-strategy table**, where every `must NOT` line originates. Rows 1, 3 and 5 quote the requirements section, which is authoritative where the two differ.
