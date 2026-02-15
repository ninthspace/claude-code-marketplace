# Discussion: Making the CPM progress file support multiple parallel sessions

**Date**: 2026-02-15
**Agents**: Jordan, Margot, Bella, Tomas, Ren

### Key points so far
- **Usage scenario**: true parallel concurrency — two `cpm:do` runs on different epics, or planning while executing
- **Critical discovery**: Claude Code hooks receive JSON on stdin with `session_id`, `transcript_path`, `source`, etc.

### Architecture Decision: Session ID in filename (CONFIRMED)
- **Filename**: `.cpm-progress-{session_id}.md`
- **Session ID injection**: `session-start.sh` echoes `CPM_SESSION_ID: {id}` into Claude's context on every session start
- **Compaction hook**: Reads `session_id` from stdin, cats exactly `.cpm-progress-{session_id}.md` — precise match. Session ID is STABLE across compaction (verified).
- **Startup/resume hook**: Globs ALL `.cpm-progress-*.md`, presents them with content headers. Does NOT rely on session ID for matching.

### Session ID stability findings
1. **Compaction**: session_id STABLE — same ID before and after. Core scheme works.
2. **Resume** (`--resume`, `--continue`, `/resume`): session_id CHANGES — new UUID generated. Known issue (GitHub #12235/#8069).
3. **Format**: UUID v4, 36 characters (e.g., `00893aaf-19fa-41d2-8238-13269b9b3ca0`)

### Resume handling strategy
- Startup/resume hook injects ALL progress files with delimiters
- Claude matches the right one from its resumed conversation context
- Skill rewrites the matched file with the new session ID on adoption
- Subsequent compactions then work with the new ID

### Orphan cleanup
- No built-in cleanup exists in Claude Code
- Startup hook checks file modification times; flags files >48h as likely stale
- No auto-deletion — user confirms

### Scope of changes
1. Two hook scripts (`session-start.sh`, `session-start-compact.sh`)
2. State Management section in every SKILL.md (14 skills, mechanical change)
3. Session ID echoed into context on every session start
