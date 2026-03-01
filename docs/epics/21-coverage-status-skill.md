# Coverage Matrix: CPM Status Skill

**Source spec**: docs/specifications/23-spec-cpm-status.md
**Epic**: docs/epics/21-epic-status-skill.md
**Date**: 2026-03-01

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | Artifact inventory scan | Glob and read CPM artifacts across `docs/specifications/`, `docs/epics/`, `docs/discussions/`, `docs/retros/`, `docs/briefs/`, `docs/plans/`. Report what exists with counts and completion status (e.g., "Epic 02: 4/6 stories complete"). | Phase 1 instructions: Glob and read CPM artifacts across `docs/specifications/`, `docs/epics/`, `docs/discussions/`, `docs/retros/`, `docs/briefs/`, `docs/plans/`, reporting what exists with counts and completion status (e.g., "Epic 02: 4/6 stories complete") | Story 1 | `[manual]` | ✓ |
| 2 | Artifact inventory scan | (implicit: handles missing directories) | Phase 1 instructions: Handle missing directories silently (no errors for dirs that don't exist) | Story 1 | `[manual]` | ✓ |
| 3 | Git recent activity summary | Show recent commits with adaptive time window. Group by category (code changes, doc changes, config changes). Highlight commits that touched CPM artifacts. | Phase 2 instructions: Show recent commits grouped by category (code/docs/config), highlight commits that touched CPM artifacts | Story 1 | `[manual]` | ✓ |
| 4 | Current state assessment | Report branch status, uncommitted changes, and in-progress work visible from epic task statuses (stories marked "In Progress"). | Phase 3 instructions: Report current branch and uncommitted changes, show in-progress stories from epic docs | Story 1 | `[manual]` | ✓ |
| 5 | Recommended next steps | Based on project state, suggest concrete CPM actions with copy-pasteable commands (e.g., "Run `/cpm:do docs/epics/02-epic-auth.md` to continue Epic 02"). | Phase 3 instructions: Suggest concrete CPM commands based on project state with copy-pasteable commands | Story 1 | `[manual]` | ✓ |
| 6 | Recommended next steps | (empty/complete edge states) | Phase 3 instructions: On empty project, recommend starting skills (`/cpm:discover`, `/cpm:brief`); on completed project, recommend closing skills (`/cpm:retro`, `/cpm:archive`) | Story 1 | `[manual]` | ✓ |
| 7 | Ephemeral output | Print structured markdown report to stdout. No file saved, no progress file. | Prints to stdout only — no files created or modified, no progress file, explicit "no state management" declaration | Story 1 | `[manual]` | ✓ |
