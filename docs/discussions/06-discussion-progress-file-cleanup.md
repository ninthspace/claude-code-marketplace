# Discussion: CPM Progress File Cleanup

**Date**: 2026-02-22
**Agents**: Jordan, Margot, Bella, Tomas, Ren

## Problem

CPM progress files (`docs/plans/.cpm-progress-{session_id}.md`) are not reliably cleaned up. Cleanup currently only fires through explicit skill exit handling (user types "exit/done/quit"). Multiple common paths bypass this:

1. **`/clear`** — Wipes conversation context but keeps the session alive. Same session ID. Startup hooks don't re-fire. Progress file is orphaned within the same session.
2. **User moves on** — Gets the artifact they wanted and starts a new conversation or closes the terminal. No exit handler fires.
3. **Context compaction** — Skill instructions re-inject but the "we should clean up" state may be lost.
4. **Skill switch** — User invokes a different `/cpm:` skill, which creates its own progress file. The previous one is abandoned.

## Agreed Direction: Two Mechanisms, One UX

### 1. Startup Hook (Cross-Session Cleanup)

When a new session starts, the existing hook infrastructure (which already injects `CPM_SESSION_ID`) should also:

- Glob for all `docs/plans/.cpm-progress-*.md` files.
- Identify files whose session ID in the filename doesn't match the current `CPM_SESSION_ID` — these are candidates from previous sessions.
- Read front-matter from each file (Skill, Topic, Phase) to provide user context.
- Present the user with a prompt listing the found files with enough info to decide.
- Let the user choose: **Remove all / Keep all / Choose individually**.

This catches: terminal closures, new sessions after unclean exits, files left from days ago.

### 2. Skill Init (Within-Session Cleanup)

When any CPM skill initialises, before creating its own progress file:

- Check for an existing `.cpm-progress-{current_session_id}.md`.
- If one exists from a **different skill** than the one starting up, it's an orphan from a `/clear` or skill switch.
- Present it to the user with the same prompt format as the startup hook.
- Same skill, same session = resume (existing behaviour). Different skill, same session = orphan, ask to clean up.

This catches: `/clear` followed by a new skill invocation, switching between CPM skills within a session.

### 3. Unified Prompt Format

Both mechanisms present the same consistent UX:

- Each file listed with: **skill name**, **topic**, **phase**, and labelled as **"this session"** or **"other session"**.
- The current session's file (if applicable) is clearly marked.
- Options: **Remove current only / Remove all / Keep all / Choose individually** (adapted to what's found).
- **No prompt if zero orphans found** — the common case should be zero friction.

### 4. Existing Skill-Level Exit Cleanup Stays

Belt and suspenders. Skills continue to clean up after themselves when they complete normally through the exit flow. The two new mechanisms catch everything that slips through.

## Key Design Decisions

- **No silent deletion.** Always present found files to the user with context before removing. Trust erodes when files disappear without explanation.
- **Concurrent session safety.** Another terminal may have an active progress file. The prompt gives the user enough information (skill, topic, phase) to recognise and protect it.
- **Infrastructure-level, not skill-level.** The cleanup logic lives in hooks and skill init boilerplate, not in individual skill exit handlers. This ensures coverage regardless of how a skill ends.
- **Front-matter is the contract.** Progress files must contain Skill, Topic, and Phase in their header for the cleanup prompt to be useful. This is already the case in all CPM skills.

## Open Questions

- Should there be an age-based bias? (e.g., files older than 24 hours default-highlighted for removal)
- Should the startup hook auto-remove without prompting if the file's Phase indicates completion? (e.g., "Complete" or "Archived")
