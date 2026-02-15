# Spec: Parallel Session Support for CPM Progress Files

**Date**: 2026-02-15
**Brief**: docs/discussions/02-discussion-parallel-sessions.md

## Problem Summary

The CPM plugin uses a single hardcoded progress file (`docs/plans/.cpm-progress.md`) for compaction resilience across all 14 skills. This creates a mutual exclusion problem: only one CPM skill can safely run at a time per project, because concurrent sessions overwrite each other's state. Users need to run multiple CPM skills in parallel — e.g., `cpm:do` on two different epics simultaneously, or `cpm:discover` for a new feature while `cpm:do` executes on an existing epic. The solution replaces the single file with session-scoped files using the `session_id` available to hooks via JSON on stdin.

## Functional Requirements

### Must Have

1. **Session-scoped progress files** — Each CPM skill writes its progress file to `docs/plans/.cpm-progress-{session_id}.md` instead of the shared `docs/plans/.cpm-progress.md`. Two concurrent skills in the same project produce separate progress files.

2. **Session ID injection on startup** — `session-start.sh` reads `session_id` from the JSON payload on stdin and echoes `CPM_SESSION_ID: {id}` to stdout, which gets injected into Claude's conversation context. This happens on every session start (startup, resume, clear).

3. **Precise compaction recovery** — `session-start-compact.sh` reads `session_id` from stdin JSON and injects only the matching session's progress file (`docs/plans/.cpm-progress-{session_id}.md`). Also echoes `CPM_SESSION_ID: {id}`. Falls back to injecting all progress files if no match found (graceful degradation).

4. **Multi-file resume injection** — On startup/resume/clear, `session-start.sh` globs all `docs/plans/.cpm-progress-*.md` files and injects each one with clear delimiters and labels. Handles zero progress files gracefully (no output beyond the session ID line).

5. **Session ID adoption on resume** — When a skill is resumed with a new session ID (because `--resume` generates a new UUID), the skill creates a new progress file with the current session ID, copies the content from the matched old file, and deletes the old file only after the new file is confirmed written.

6. **Skill SKILL.md updates** — All 14 skill SKILL.md files updated: State Management section references `CPM_SESSION_ID` from context for the progress filename; includes session ID adoption instructions for the resume scenario.

### Should Have

7. **Orphan detection** — Startup hook identifies progress files with modification time >48 hours and flags them as likely stale with readable context (extracted skill name, phase, and artifact info from the file header).

8. **Readable resume presentation** — When multiple progress files are injected on startup/resume, each file includes an extracted label showing skill name, phase, and working artifact rather than just raw file contents.

9. **Orphan auto-cleanup prompt** — Stale file messages suggest deletion with the file path, providing enough context for the user to decide without needing to understand session IDs.

### Won't Have (this iteration)

- Concurrent writes to the same artifact (e.g., two sessions editing the same epic doc)
- Progress file locking or semaphores
- Session management UI or dashboard
- Cross-project session awareness
- Changes to the progress file internal format (only the filename changes)

## Non-Functional Requirements

### Reliability

- **No data loss on compaction** — The compaction hook must inject the correct session's progress file. A miss means the session loses all context with no recovery. This is the highest-risk failure mode.
- **Graceful degradation** — If stdin JSON parsing fails (e.g., `jq` not installed or JSON malformed), hooks fall back to injecting all progress files rather than injecting nothing.
- **Atomic resume adoption** — When rewriting a progress file with a new session ID (rename), the old file is deleted only after the new file is confirmed written.

### Usability

- **Zero ceremony for the common case** — A single-session user should notice no difference. The session ID is injected automatically; skills use it transparently.
- **Clear stale file messaging** — When orphaned files are detected, the user understands what they are and what they can safely delete without needing to understand session IDs.

### Performance

- **Hook execution time** — Hooks must remain fast (<500ms). Globbing a handful of small markdown files and parsing a few lines of JSON is well within this.

## Architecture Decisions

### Session Discriminator Strategy
**Choice**: Session ID in filename (`.cpm-progress-{session_id}.md`)
**Rationale**: UUID v4 session IDs are guaranteed unique — no collision risk. The compaction hook does an exact file lookup with zero ambiguity. Session IDs are stable across compaction events within the same session (verified).
**Alternatives considered**: Skill+slug in filename (`.cpm-progress-do-authentication.md`) — human-readable but collision risk when running the same skill on the same artifact in two sessions. Subdirectory per session (`.cpm-sessions/{id}/progress.md`) — cleanest isolation but adds directory management overhead.

### Session ID Delivery to Claude
**Choice**: Context injection via hook stdout (`CPM_SESSION_ID: {id}`)
**Rationale**: Lightest-weight approach. No files to manage, no extra reads. Both the startup hook and compaction hook echo this line. Claude reliably extracts structured values from injected context text.
**Alternatives considered**: Breadcrumb file (hook writes session ID to a known file, skill reads it) — more deterministic but creates the same single-file contention problem this spec aims to solve. Also adds a write on every session start and a read on every skill invocation.

### Resume Adoption Mechanism
**Choice**: Skill-level adoption (hooks inject all files, skill matches and renames)
**Rationale**: Keeps hooks simple (no interactive input, no intelligence required). The LLM has full conversation context from the resumed session and can match the correct progress file based on what it was doing. The skill then writes a new file with the current session ID and deletes the old one.
**Alternatives considered**: Hook-level adoption (hook prompts user to pick a file, renames it) — hooks can't do interactive input, they only output text. Not feasible.

## Scope

### In Scope
- Rewrite `session-start.sh` — parse stdin JSON, echo `CPM_SESSION_ID`, glob and inject all progress files with labels, detect and flag orphans
- Rewrite `session-start-compact.sh` — parse stdin JSON, echo `CPM_SESSION_ID`, inject only matching session's file with fallback
- Update State Management section in all 14 SKILL.md files to use `CPM_SESSION_ID` in progress filename
- Add session ID adoption instructions to SKILL.md files for resume scenario
- Add orphan detection and cleanup messaging to `session-start.sh`
- Update `hooks.json` if any structural changes needed
- Create bash test scripts for hook behaviour

### Out of Scope
- Concurrent writes to the same artifact from multiple sessions
- Session management UI, dashboard, or listing commands
- Cross-project session awareness
- Progress file locking or semaphores
- Changes to the progress file internal format

### Deferred
- Human-readable session labels (e.g., `**Label**: do — authentication` in progress files for better stale-file messaging)
- A `/cpm:sessions` skill for listing/managing active sessions

## Testing Strategy

### Tag Vocabulary
Test approach tags used in this spec:
- `[unit]` — Unit tests targeting individual components in isolation
- `[integration]` — Integration tests exercising boundaries between components
- `[manual]` — Manual inspection, observation, or user confirmation

### Acceptance Criteria Coverage

| Requirement | Acceptance Criterion | Test Approach |
|---|---|---|
| 1. Session-scoped progress files | Skills write to `.cpm-progress-{session_id}.md` instead of `.cpm-progress.md` | `[manual]` |
| 1. Session-scoped progress files | Two concurrent skills in the same project produce separate progress files | `[manual]` |
| 2. Session ID injection on startup | `session-start.sh` parses `session_id` from stdin JSON | `[unit]` |
| 2. Session ID injection on startup | Hook echoes `CPM_SESSION_ID: {id}` to stdout | `[unit]` |
| 2. Session ID injection on startup | Claude's context contains `CPM_SESSION_ID` after session start | `[integration]` |
| 3. Precise compaction recovery | `session-start-compact.sh` parses `session_id` from stdin JSON | `[unit]` |
| 3. Precise compaction recovery | Hook outputs only the matching session's progress file | `[unit]` |
| 3. Precise compaction recovery | Hook falls back to injecting all files if no match found | `[unit]` |
| 3. Precise compaction recovery | Post-compaction context contains correct session state | `[integration]` |
| 4. Multi-file resume injection | Startup hook globs all `.cpm-progress-*.md` files | `[unit]` |
| 4. Multi-file resume injection | Each file is output with clear delimiters and labels | `[unit]` |
| 4. Multi-file resume injection | Hook handles zero progress files gracefully (no output) | `[unit]` |
| 5. Session ID adoption on resume | Skill creates new progress file with current session ID | `[manual]` |
| 5. Session ID adoption on resume | Old progress file (previous session ID) is deleted after new file confirmed | `[manual]` |
| 6. SKILL.md updates | All 14 SKILL.md files reference `CPM_SESSION_ID` in State Management | `[manual]` |
| 6. SKILL.md updates | Progress file path uses session ID pattern consistently | `[manual]` |
| 7. Orphan detection | Startup hook identifies files with mtime >48h | `[unit]` |
| 7. Orphan detection | Stale files are flagged with readable context (skill name, phase) | `[unit]` |
| 8. Readable resume presentation | Each injected file includes extracted skill/phase/context as a label | `[unit]` |
| 9. Orphan auto-cleanup prompt | Stale file message suggests deletion with file path | `[manual]` |
| 9. Orphan auto-cleanup prompt | User sees enough context to decide without understanding session IDs | `[manual]` |

### Integration Boundaries

1. **Hook stdin → Hook script** — JSON payload from Claude Code runtime → bash `jq` parsing. Contract: JSON schema with `session_id`, `source`, `hook_event_name` fields.
2. **Hook stdout → Claude context** — Text echoed by hooks injected into Claude's conversation. Contract: `CPM_SESSION_ID: {value}` format that skills depend on.
3. **Skill ↔ Filesystem** — Skills write/read/delete progress files at session-scoped path. Contract: filename pattern `.cpm-progress-{session_id}.md`.
4. **Compaction event → Hook → Correct file** — End-to-end flow from compaction trigger through hook execution to correct state recovery. Highest-risk boundary.

### Test Infrastructure

A `tests/` directory in the plugin containing bash test scripts. Each script pipes mock JSON to hook scripts and asserts stdout output. No external framework required — pure bash with assertion functions. Test scripts cover:
- JSON parsing (valid input, missing fields, malformed JSON)
- File globbing (zero files, one file, multiple files)
- Session ID matching (exact match, no match/fallback)
- Orphan detection (fresh files, stale files, mixed)
- Output formatting (delimiters, labels, session ID line)

### Unit Testing
Unit testing of individual components is handled at the `cpm:do` task level — each story's acceptance criteria drive test coverage during implementation.
