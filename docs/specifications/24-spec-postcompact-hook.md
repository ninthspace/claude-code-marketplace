# Spec: PostCompact Hook Integration

**Date**: 2026-03-14
**Brief**: N/A (conversation-driven — PostCompact hook newly available in Claude Code)

## Problem Summary

CPM's compaction resilience relies on two mechanisms: skills proactively write structured progress files (`.cpm-progress-{session_id}.md`) after each phase, and `SessionStart (compact)` re-injects the progress file into fresh post-compaction context. If compaction fires mid-phase — between progress file writes — conversational context from that partial phase is lost. The new PostCompact hook provides the `compact_summary` generated during compaction, capturing exactly this gap: in-flight reasoning, partial decisions, and narrative flow that haven't been committed to the progress file yet. Saving and re-injecting this summary alongside the progress file gives post-compaction context a much richer recovery.

## Functional Requirements

### Must Have
- PostCompact hook script (`post-compact.sh`) receives stdin JSON, extracts `session_id` and `compact_summary`, writes summary to `docs/plans/.cpm-compact-summary-{session_id}.md` with a minimal header (source label, timestamp, trigger type)
- `hooks.json` updated with PostCompact event configuration pointing to `post-compact.sh`
- `session-start-compact.sh` updated to inject compact summary file after the progress file when both exist, or inject compact summary alone as fallback when no progress file exists
- Tests for new PostCompact hook added to existing bash test framework (`test-helpers.sh`)
- Stateful SKILL.md files updated to delete `.cpm-compact-summary-{session_id}.md` on successful completion alongside the progress file

### Should Have
- Compact summary file includes header with source, timestamp, and trigger type to distinguish it from the progress file during injection and enable future age-based checks

### Could Have
- Age limit on compact summary injection in SessionStart — skip summaries older than N hours (stale summaries from abandoned sessions)

### Won't Have (this iteration)
- SKILL.md State Management structural changes (existing progress file mechanism is unchanged)
- PreCompact hook (compact_summary from PostCompact supersedes the need)
- Multiple compact summary accumulation (each compaction overwrites the previous summary file)

## Non-Functional Requirements

### Reliability
- If `post-compact.sh` fails or times out, compaction still completes — PostCompact is read-only and cannot block the session
- If the compact summary file is missing or unreadable, `session-start-compact.sh` continues with just the progress file (graceful degradation — same behaviour as today)
- Hook scripts exit cleanly within the 60-second default timeout

### Usability
- Zero user configuration — hooks install with the plugin update, summary capture is automatic
- No visible overhead — PostCompact runs after compaction is already done, user doesn't wait

### Compatibility
- Must work on both macOS (`stat -f %m`) and Linux (`stat -c %Y`) for any file age checks
- `jq` dependency is already established in existing hooks — no new dependencies introduced

## Architecture Decisions

### Compact Summary File Location and Naming
**Choice**: Parallel file in `docs/plans/.cpm-compact-summary-{session_id}.md`
**Rationale**: Same directory and naming convention as the progress file. Both serve compaction resilience, both are keyed by session ID, both are injected by the same SessionStart hook. Co-locating them with parallel naming makes the relationship obvious and cleanup straightforward.
**Alternatives considered**: Subdirectory (`docs/plans/.cpm-compacts/`) — adds structure not needed for one file per session; Append to progress file — muddies structured state data with narrative text, complicates the progress file parser.

### Injection Strategy in SessionStart
**Choice**: Progress file first (structured state), compact summary after (narrative supplement). If no progress file exists, inject compact summary alone as fallback.
**Rationale**: The progress file is the authoritative state — skill, phase, decisions. The compact summary is supplementary narrative. Leading with structured data and following with "here's what was happening in conversation when compaction fired" gives Claude the right priority ordering. The fallback case (no progress file, only summary) handles the edge case where compaction fires before the first progress write.
**Alternatives considered**: Summary first, progress after — risks Claude continuing conversational thread rather than picking up structured phase; Progress only, summary as fallback — wastes the summary when both exist.

### Compact Summary File Format
**Choice**: Minimal header (source label, timestamp, trigger type) before raw `compact_summary` content
**Rationale**: The header distinguishes this from the progress file when both are injected into context. The timestamp enables future age-based staleness checks. Minimal overhead — just three lines of metadata before the verbatim summary.
**Alternatives considered**: Raw text only — no way to distinguish source or judge age when injected.

## Scope

### In Scope
- New `cpm/hooks/post-compact.sh` — PostCompact hook that saves compact summary to disk
- Updated `cpm/hooks/hooks.json` — adds PostCompact event configuration
- Updated `cpm/hooks/session-start-compact.sh` — injects compact summary alongside progress file
- New `cpm/hooks/tests/test-post-compact-hook.sh` — tests for the new hook
- Updated `cpm/hooks/tests/test-compact-hook.sh` — tests for updated SessionStart injection behaviour
- Updated stateful SKILL.md files — cleanup instructions include compact summary deletion
- Updated `docs/plans/01-plan-compaction-resilience.md` — remove "No PostCompact hook exists" constraint
- Plugin version bump

### Out of Scope
- SKILL.md State Management structural changes (existing mechanism is unchanged)
- `session-start.sh` (startup/resume) changes — orphan detection for compact summary files
- PreCompact hook
- Multiple compact summary accumulation

### Deferred
- Compact summary age limit in SessionStart injection
- Orphan detection for compact summary files in startup/resume hook

## Testing Strategy

### Tag Vocabulary
Test approach tags used in this spec:
- `[unit]` — Unit tests targeting individual components in isolation
- `[integration]` — Integration tests exercising boundaries between components
- `[feature]` — Feature/end-to-end tests exercising complete user-facing workflows
- `[manual]` — Manual inspection, observation, or user confirmation
- `[tdd]` — Workflow mode: task follows red-green-refactor loop. Composable with any level tag (e.g. `[tdd] [unit]`). Orthogonal — describes how to work, not what kind of test.

### Acceptance Criteria Coverage

| Requirement | Acceptance Criterion | Test Approach |
|---|---|---|
| PostCompact hook script | Extracts session_id and compact_summary from stdin JSON | `[unit]` |
| PostCompact hook script | Writes summary to .cpm-compact-summary-{session_id}.md | `[unit]` |
| PostCompact hook script | File includes header with source, timestamp, trigger | `[unit]` |
| PostCompact hook script | Handles malformed/empty JSON gracefully (no crash, no file written) | `[unit]` |
| PostCompact hook script | Handles missing compact_summary field (no file written) | `[unit]` |
| hooks.json updated | PostCompact event configured with correct command path | `[manual]` |
| SessionStart updated | Injects compact summary after progress file when both exist | `[unit]` |
| SessionStart updated | Injects compact summary alone when no progress file exists | `[unit]` |
| SessionStart updated | Skips compact summary injection when no summary file exists | `[unit]` |
| SessionStart updated | Summary injection uses clear header/separator | `[unit]` |
| Tests | test-post-compact-hook.sh uses existing test-helpers.sh framework | `[unit]` |
| Tests | Updated test-compact-hook.sh covers new injection behaviour | `[unit]` |
| Tests | All tests pass in run-all-tests.sh | `[unit]` |
| SKILL.md cleanup | Each stateful skill's completion step mentions deleting compact summary file | `[manual]` |

### Integration Boundaries
The key integration boundary is between `post-compact.sh` and `session-start-compact.sh`: the PostCompact hook writes `.cpm-compact-summary-{session_id}.md` to disk, and the SessionStart hook reads and injects it. The file on disk is the integration contract. Tests verify this end-to-end by writing a summary file and running the SessionStart hook to confirm injection.

### Test Infrastructure
The project already has a mature bash test framework (per retro: 38 tests across 3 suites with `test-helpers.sh`). No new test frameworks or infrastructure needed. New tests are added to this existing framework. Per retro recommendation, tests are written incrementally alongside implementation, not deferred to a separate story.

### Unit Testing
Unit testing of individual components is handled at the `cpm:do` task level — each story's acceptance criteria drive test coverage during implementation.
