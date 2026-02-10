# Problem Brief: CPM Compaction Resilience

**Date**: 2026-02-10

## Why

CPM skills run long, multi-phase facilitated conversations (discover: 6 phases, spec: ~5 topics, stories: 6 steps). These are prime candidates for auto-compaction. When compaction fires mid-skill, conversation-only state is lost — which phase we're in, what's been decided, the facilitation thread. The user has to re-explain or gets asked the same questions again.

## Who

CPM plugin users running discover, spec, or stories sessions long enough to trigger auto-compaction. These are the most engaged users — running full planning pipelines for non-trivial work.

## Current State

- Skills are prompt-only (SKILL.md files, no scripts)
- Finished artifacts survive compaction (written to `docs/plans/`, `docs/specifications/`, `docs/stories/`)
- Claude Code tasks survive (persisted in the task system via TaskCreate)
- CLAUDE.md is reloaded fresh post-compaction
- **Mid-skill progress exists only in conversation context** — no on-disk state for: current phase, completed phases, user decisions, facilitation thread
- No hooks are used by the plugin today

## Success Criteria

- **Seamless continuation**: After compaction fires mid-skill, Claude picks up exactly where it left off — same phase, same context, next question — without the user noticing
- No repeated questions for already-completed phases
- No re-orientation preamble ("We were working on...")
- Works for auto-compaction (no custom_instructions) and manual `/compact`

## Constraints

- Plugin can add hook scripts (hooks/ directory with hooks.json) — not limited to prompt-only
- Must handle all three skills: discover, spec, stories
- Focused on compaction resilience only (not broader session start/resume injection)
- PreCompact stdout gets summarised (not preserved verbatim) — so the SessionStart hook is the primary re-injection point
- No PostCompact hook exists — must work within PreCompact + SessionStart (compact) model
- 60-second default timeout per hook

## Scope Boundaries

**In scope:**
- State-writing instructions in all three SKILL.md prompts (write progress after each phase)
- PreCompact hook to guide compaction summary
- SessionStart (compact) hook to re-inject skill state into fresh context
- Plugin hooks.json configuration
- Shell scripts for hook execution

**Out of scope:**
- Broader hook mechanisms (session start from startup/resume, non-compaction triggers)
- Changes to how skills facilitate conversations (the phases themselves stay the same)
- Transcript backup (useful but separate concern)
- "Retain verbatim" markers (not available yet)
