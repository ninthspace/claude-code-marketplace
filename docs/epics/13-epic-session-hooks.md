# Session-Scoped Hook Infrastructure

**Source spec**: docs/specifications/17-spec-parallel-sessions.md
**Date**: 2026-02-15
**Status**: Complete
**Blocked by**: —

## Rewrite compaction hook for session-scoped recovery
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: Req 2 (Session ID injection on startup), Req 3 (Precise compaction recovery)

**Acceptance Criteria**:
- `session-start-compact.sh` parses `session_id` from stdin JSON `[unit]`
- Hook echoes `CPM_SESSION_ID: {id}` to stdout `[unit]`
- Hook outputs only the matching session's progress file `[unit]`
- Hook falls back to injecting all `.cpm-progress-*.md` files if no match found `[unit]`
- Post-compaction context contains correct session state `[integration]`

### Rewrite `session-start-compact.sh` to parse stdin JSON
**Task**: 1.1
**Description**: Read `session_id` using `jq`, construct session-scoped file path, cat the matching file. Echo `CPM_SESSION_ID: {id}` to stdout.
**Status**: Complete

### Add fallback logic for no-match and parse failures
**Task**: 1.2
**Description**: Glob all `.cpm-progress-*.md` when exact match not found or JSON parsing fails, ensuring graceful degradation.
**Status**: Complete

### Write tests for "Rewrite compaction hook for session-scoped recovery"
**Task**: 1.3
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`.
**Status**: Complete

**Retro**: [Smooth delivery] Compaction hook and fallback logic were simple enough to implement together in one task; test infrastructure (test-helpers.sh) is reusable across remaining stories.

---

## Rewrite startup/resume hook for multi-session support
**Story**: 2
**Status**: Complete
**Blocked by**: —
**Satisfies**: Req 2 (Session ID injection on startup), Req 4 (Multi-file resume injection), Req 8 (Readable resume presentation)

**Acceptance Criteria**:
- `session-start.sh` parses `session_id` from stdin JSON `[unit]`
- Hook echoes `CPM_SESSION_ID: {id}` to stdout `[unit]`
- Hook globs all `.cpm-progress-*.md` files and injects each with clear delimiters `[unit]`
- Each injected file includes extracted skill/phase/context as a label `[unit]`
- Hook handles zero progress files gracefully (only session ID line output) `[unit]`

### Rewrite `session-start.sh` to parse stdin JSON and echo session ID
**Task**: 2.1
**Description**: Read `session_id` using `jq`, echo `CPM_SESSION_ID: {id}` as first output line.
**Status**: Complete

### Add multi-file injection with labels
**Task**: 2.2
**Description**: Glob `.cpm-progress-*.md`, extract skill/phase from each file's header, output each with delimiters and a readable label.
**Status**: Complete

### Handle zero-file case
**Task**: 2.3
**Description**: When no progress files exist, output only the `CPM_SESSION_ID` line and exit cleanly.
**Status**: Complete

### Write tests for "Rewrite startup/resume hook for multi-session support"
**Task**: 2.4
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`.
**Status**: Complete

**Retro**: [Smooth delivery] Startup hook implementation and tests completed in one pass; label extraction from file headers works well for readable presentation.

---

## Add orphan detection and cleanup messaging
**Story**: 3
**Status**: Complete
**Blocked by**: Story 2
**Satisfies**: Req 7 (Orphan detection), Req 9 (Orphan auto-cleanup prompt)

**Acceptance Criteria**:
- Startup hook identifies files with mtime >48h `[unit]`
- Stale files are flagged with readable context (skill name, phase) `[unit]`
- Stale file message suggests deletion with file path `[manual]`
- User sees enough context to decide without understanding session IDs `[manual]`

### Add orphan detection to `session-start.sh`
**Task**: 3.1
**Description**: Check mtime of each globbed progress file; flag those >48h old.
**Status**: Complete

### Format stale file messaging
**Task**: 3.2
**Description**: Extract skill name and phase from stale files; present readable cleanup suggestion with file path.
**Status**: Complete

### Write tests for "Add orphan detection and cleanup messaging"
**Task**: 3.3
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`.
**Status**: Complete

**Retro**: [Smooth delivery] Orphan detection integrated cleanly into the existing startup hook loop; stale files are excluded from active injection which avoids confusing the LLM with outdated state.

---

## Create hook test suite
**Story**: 4
**Status**: Complete
**Blocked by**: Story 1, Story 2, Story 3
**Satisfies**: Spec Testing Strategy — test infrastructure

**Acceptance Criteria**:
- `tests/` directory exists in plugin with bash test scripts `[manual]`
- Tests cover JSON parsing (valid input, missing fields, malformed JSON) `[unit]`
- Tests cover file globbing (zero, one, multiple files) `[unit]`
- Tests cover session ID matching (exact match, no match/fallback) `[unit]`
- Tests cover orphan detection (fresh files, stale files, mixed) `[unit]`
- Tests cover output formatting (delimiters, labels, session ID line) `[unit]`

### Create test infrastructure
**Task**: 4.1
**Description**: Set up `tests/` directory with a bash test runner and assertion helpers.
**Status**: Complete

### Write JSON parsing tests
**Task**: 4.2
**Description**: Valid input, missing `session_id` field, malformed JSON, empty stdin.
**Status**: Complete

### Write file globbing and matching tests
**Task**: 4.3
**Description**: Zero files, one file, multiple files, exact session match, no match fallback.
**Status**: Complete

### Write orphan detection tests
**Task**: 4.4
**Description**: Fresh files, stale files (>48h), mixed ages.
**Status**: Complete

### Write output formatting tests
**Task**: 4.5
**Description**: Delimiter format, label extraction, session ID line presence.
**Status**: Complete

**Retro**: [Pattern worth reusing] Building tests incrementally alongside each story (rather than as a separate final step) resulted in all 38 tests being written and passing before Story 4 was even hydrated. The test suite story became pure verification.

## Lessons

### Smooth Deliveries
- Story 1: Compaction hook and fallback logic were simple enough to implement together; test infrastructure is reusable across stories
- Story 3: Orphan detection integrated cleanly into the existing startup hook loop

### Patterns Worth Reusing
- Story 4: Building tests incrementally alongside each story (rather than as a separate final step) resulted in all 38 tests being written and passing before the test suite story was even hydrated
