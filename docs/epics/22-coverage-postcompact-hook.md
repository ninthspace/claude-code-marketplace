# Coverage Matrix: PostCompact Hook Integration

**Source spec**: docs/specifications/24-spec-postcompact-hook.md
**Epic**: docs/epics/22-epic-postcompact-hook.md
**Date**: 2026-03-14

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | PostCompact hook script | Extracts session_id and compact_summary from stdin JSON | `post-compact.sh` extracts `session_id` and `compact_summary` from stdin JSON | Story 1 | `[unit]` | ✓ |
| 2 | PostCompact hook script | Writes summary to .cpm-compact-summary-{session_id}.md | Writes summary to `docs/plans/.cpm-compact-summary-{session_id}.md` | Story 1 | `[unit]` | ✓ |
| 3 | PostCompact hook script | File includes header with source, timestamp, trigger | File includes header with source label, timestamp, and trigger type | Story 1 | `[unit]` | ✓ |
| 4 | PostCompact hook script | Handles malformed/empty JSON gracefully (no crash, no file written) | Handles malformed/empty JSON gracefully — no crash, no file written | Story 1 | `[unit]` | ✓ |
| 5 | PostCompact hook script | Handles missing compact_summary field (no file written) | Handles missing `compact_summary` field — no file written | Story 1 | `[unit]` | ✓ |
| 6 | hooks.json updated | PostCompact event configured with correct command path | `hooks.json` includes PostCompact event configured with command `bash ${CLAUDE_PLUGIN_ROOT}/hooks/post-compact.sh` | Story 1 | `[manual]` | ✓ |
| 7 | SessionStart updated | Injects compact summary after progress file when both exist | `session-start-compact.sh` injects compact summary file after progress file when both exist | Story 2 | `[unit]` | ✓ |
| 8 | SessionStart updated | Injects compact summary alone when no progress file exists | Injects compact summary alone as fallback when no progress file exists | Story 2 | `[unit]` | ✓ |
| 9 | SessionStart updated | Skips compact summary injection when no summary file exists | Skips compact summary injection when no summary file exists (existing behaviour preserved) | Story 2 | `[unit]` | ✓ |
| 10 | SessionStart updated | Summary injection uses clear header/separator | Summary injection uses clear header/separator distinguishing it from progress file content | Story 2 | `[unit]` | ✓ |
| 11 | SKILL.md cleanup | Each stateful skill's completion step mentions deleting compact summary file | Each stateful skill's completion step mentions deleting `.cpm-compact-summary-{session_id}.md` alongside the progress file | Story 3 | `[manual]` | ✓ |
