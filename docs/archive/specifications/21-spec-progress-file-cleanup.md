# Spec: Progress File Cleanup

**Date**: 2026-02-22
**Brief**: docs/discussions/06-discussion-progress-file-cleanup.md

## Problem Summary

CPM progress files (`docs/plans/.cpm-progress-{session_id}.md`) are only cleaned up when a skill completes normally through its exit flow. Two common paths bypass this: (1) the user closes the terminal or moves on without completing the skill, leaving the file from an old session ID; (2) the user runs `/clear` followed by non-CPM work, leaving the file on disk until the next session catches it. Skill switch within a session overwrites the file at the same path (same session ID) and is not an orphan scenario. The existing startup hook detects stale files (>48h old) and warns users, but does not prompt for cleanup of recent orphans from other sessions.

## Functional Requirements

### Must Have
- Startup hook detects and prompts for orphaned progress files from other session IDs, regardless of file age
- All cleanup is user-initiated — files are never deleted without the user seeing what's being removed
- The cleanup prompt provides enough context per file (skill name, phase, age) for the user to recognise and protect files from an active session in another terminal
- Orphan files and stale files use a consistent output structure (skill, phase, age) for the LLM to present to the user
- Files include an age indicator in the output, with files older than 24h visually distinguished from fresher ones
- Each orphan file is listed as a separate block with its own file path, enabling the LLM to present individual file choices

### Should Have
(none)

### Could Have
(none)

### Won't Have (this iteration)
- Skill init cleanup — skill switch within a session overwrites the progress file at the same path; no separate cleanup mechanism is needed
- Auto-remove completed files — not all skills have detectable completion states; user prompt with age hints is sufficient

## Non-Functional Requirements

### Reliability
The cleanup prompt must not block session startup if something goes wrong (e.g., malformed progress file, permission error on stat). Skip the file gracefully and continue.

### Usability
The cleanup output should be scannable — a user with 3 orphaned files should immediately understand what they are and which to remove. Target under 5 seconds to parse the prompt.

### Compatibility
Must work on both macOS and Linux. The existing hooks already handle this with dual `stat` calls (`stat -f %m` for macOS, `stat -c %Y` for Linux).

## Architecture Decisions

### Cleanup Prompt Origin
**Choice**: Enhanced hook output — the startup hook outputs structured text into the LLM context, and the LLM interprets it to present cleanup options to the user.
**Rationale**: Hooks output text and cannot interactively prompt. The LLM-as-interpreter pattern is already established and gives users a richer experience (AskUserQuestion with context) than a raw terminal prompt.
**Alternatives considered**: Hook-level interactive prompt (rejected — hooks receive JSON on stdin, cannot interactively prompt users).

### Orphan Detection Method
**Choice**: Session ID matching — extract the session ID from each progress file's filename and compare against the current `CPM_SESSION_ID`. Files from other sessions are orphan candidates.
**Rationale**: The session ID is already embedded in the filename (`.cpm-progress-{session_id}.md`). This gives a precise signal — "this file belongs to a different session" — rather than guessing based on file age alone. Age thresholds cannot distinguish between a 2-hour-old file from the current session (active) and a 2-hour-old file from a closed session (orphan).
**Alternatives considered**: Age thresholds only (rejected — cannot distinguish same-age files from different sessions).

### Output Format
**Choice**: Human-readable text blocks, consistent with existing hook output style.
**Rationale**: The LLM is the consumer. Clear, labelled text works well for LLM comprehension and is consistent with the existing codebase. Adding JSON/YAML would increase shell script complexity for no real gain.
**Alternatives considered**: Structured data (JSON/YAML) — rejected for consistency and simplicity.

### Integration Approach
**Choice**: Modify `session-start.sh` in-place rather than extracting cleanup logic to a separate helper script.
**Rationale**: The hook is currently 82 lines and will grow to ~120-130 lines. The existing stale detection is already in this file — orphan detection extends it, not a new responsibility. The test suite already calls `session-start.sh` directly. A helper script would add indirection for modest complexity reduction.
**Alternatives considered**: Separate cleanup helper script sourced by the hook (rejected — adds indirection, complicates test setup).

## Scope

### In Scope
- Modify `session-start.sh` to detect orphaned progress files via session ID matching
- Add session ID extraction from filenames (basename + sed)
- Add age-based visual hints in the cleanup output (age labelling for all files, stale markers for >24h)
- Output per-file information so the LLM can present individual file choices
- Extend existing test suites (`test-startup-hook.sh` and/or `test-orphan-detection.sh`) with new tests
- Keep existing stale (>48h) detection as part of the broader orphan classification

### Out of Scope
- Skill init cleanup (within-session, overwrite is correct behaviour)
- Auto-remove completed files
- Changes to individual SKILL.md files
- Changes to progress file format or front-matter schema
- Interactive hook prompts

### Deferred
- Compaction hook alignment (review after implementation)
- Age-based default selection in the cleanup prompt

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
| Orphan detection | Hook output includes orphan file details when files from other session IDs exist | `[unit]` |
| Orphan detection | Hook output does NOT flag files matching the current session ID as orphans | `[unit]` |
| Orphan detection | When no orphan files exist, no cleanup guidance is output | `[unit]` |
| No silent deletion | Hook output presents file info for user decision — never includes auto-executing delete commands | `[unit]` |
| No silent deletion | Output includes file paths so the LLM can act on user's deletion choice | `[unit]` |
| Concurrent session safety | Each orphan file's output includes skill name, phase, and age | `[unit]` |
| Concurrent session safety | Files from another active session are presented with the same info — user decides | `[unit]` |
| Unified prompt format | Orphan files and stale files use the same output structure | `[unit]` |
| Age-based visual hints | Files older than 24h include an age indicator in the output | `[unit]` |
| Age-based visual hints | Files younger than 24h include age but without a stale marker | `[unit]` |
| Per-file selection | Each orphan file is listed as a separate block with its own file path | `[unit]` |

### Integration Boundaries
Two integration boundaries exist, both adequately covered by unit tests:
- **Hook → LLM context**: The hook outputs text injected into the LLM's context window. The contract is the output format — clear, labelled text blocks that the LLM can interpret and present to the user.
- **Hook → filesystem**: The hook reads progress files from `docs/plans/`, extracts session IDs from filenames, and reads metadata from file headers. Both operations are covered by unit tests with temp directory fixtures.

### Test Infrastructure
None required. The project has a mature bash test framework (`test-helpers.sh`) with 44 existing tests across 3 suites, fixture helpers (`create_progress_file`, `make_stale`, `setup_project_dir`), and a test runner (`run-all-tests.sh`). New tests should extend the existing `test-orphan-detection.sh` and/or `test-startup-hook.sh` suites.

Per retro recommendation: tests should be written incrementally during implementation stories, not deferred to a separate testing story.

### Unit Testing
Unit testing of individual components is handled at the `cpm:do` task level — each story's acceptance criteria drive test coverage during implementation.
