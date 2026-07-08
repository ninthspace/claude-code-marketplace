# Coverage Matrix: Safety-Net & Skill Rollout

**Source spec**: docs/specifications/38-spec-stale-progress-prompt-and-cpm-clean.md
**Epic**: docs/epics/38-02-epic-safety-net-rollout.md
**Date**: 2026-07-08

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | FR3 Sentinel | "guarded by a `CPM_SESSION_ID`-keyed sentinel so it fires at most once per session regardless of how many skills run" | "Guard reports `SKIP` when the current session's sentinel already exists"; "must NOT report `RUN` when the current session's sentinel exists" | Story 1 | `[unit]`/`[integration]` | ✓ |
| 2 | FR3 Coverage | "A shared-conventions procedure that every `/cpm:*` skill runs as an early startup step" | "New 'Stale-Progress Check' section in `skill-conventions.md`: consult the guard..."; "Every `/cpm:*` skill's startup includes a 'Follow the shared Stale-Progress Check procedure' reference" | Story 2, Story 3 | `[manual]` | ✓ |
| 3 | FR4 Three-way | "Stale other-session → offered for deletion; fresh other-session → informational only..., never offered for deletion, never silent; current-session → active state as today." | "Presents stale→offer deletion, fresh→informational, current→active state; never deletes without explicit confirmation"; "must NOT offer fresh (parallel-session) files for deletion" | Story 2 | `[manual]` | ✓ |
| 4 | FR6 Confirmation | "the user always sees what is being removed first"; "No code path auto-executes a delete." | "must NOT delete any file without explicit user confirmation" | Story 2 | `[manual]` | ✓ |
| 5 | FR11 Ralph detection | "When an active ralph loop is detected (`.claude/ralph-loop.local.md`), the safety-net is fully suppressed and silent: no prompt, no output, no action." | "Guard reports `SUPPRESS` when `.claude/ralph-loop.local.md` is present, regardless of sentinel state" | Story 1 | `[unit]` (detection gate) | ✓ |
| 6 | FR11 Ralph suppression | "the safety-net is fully suppressed and silent: no prompt, no output, no action" | "The ralph prompt template's *Autonomous Behaviour* override table lists the new Stale-Progress Check gate with 'fully suppressed, no prompt, no action' behaviour" | Story 4 | `[manual]` (suppression) | ✓ |
