# Spec: CPM Compaction Resilience

**Date**: 2026-02-10
**Brief**: docs/plans/cpm-compaction-resilience.md

## Problem Summary

CPM skills (discover, spec, stories) run multi-phase facilitated conversations where mid-skill state — current phase, user decisions, facilitation progress — exists only in conversation context. When auto-compaction fires, this state is lost. The solution adds on-disk state tracking and plugin hooks to re-inject state post-compaction (and on session start/resume), enabling seamless continuation.

## Functional Requirements

### Must Have
- Skills write progress to `docs/plans/.cpm-progress.md` after each phase/section/step completes
- State file captures: active skill name, current phase number/name, summary of each completed phase's decisions, output target path, next expected action
- Plugin ships `hooks/hooks.json` with PreCompact and SessionStart hooks
- SessionStart (compact) hook re-injects full state file into fresh post-compaction context
- SessionStart (startup/resume) hook re-injects state file when returning to a project with an incomplete CPM session — Claude offers to continue or discard
- Skills delete state file on successful completion (final artifact written)

### Should Have
- PreCompact hook outputs summary guidance to help compaction preserve CPM context
- State file includes enough detail per completed phase that Claude can continue without asking the user to repeat anything

### Could Have
- PreCompact hook backs up transcript before compaction

### Won't Have (this iteration)
- "Retain verbatim" markers (platform doesn't support this yet)
- State file versioning or format migration
- UI for viewing/managing state
- Transcript backup

## Non-Functional Requirements

### Reliability
- If state file is missing or unreadable, skills work normally (just without compaction resilience)
- Hook scripts exit cleanly within 60-second timeout
- Partial state writes don't break the skill flow

### Usability
- Zero user configuration — hooks install with the plugin, state-writing is in the skill prompts
- No visible overhead — state writing is a natural part of the phase transitions

## Architecture Decisions

### State File Format
**Choice**: Markdown
**Rationale**: Primary consumer is Claude (via hook injection into context). Markdown is native to the context window and human-readable for debugging.
**Alternatives considered**: JSON (structured, parseable with jq, but noisier in context and needs transformation); Hybrid with YAML frontmatter (unnecessary complexity for the use case)

### State File Content Structure
**Choice**: Skill name + phase number + completed phase summaries + next action
**Rationale**: Summaries of user answers (not transcripts) keep the file compact while providing enough context for seamless continuation. The "next action" field tells Claude exactly where to pick up.
**Alternatives considered**: Full transcript (too large, defeats the purpose); Phase names only without summaries (not enough for seamless continuation)

### State File Location
**Choice**: `docs/plans/.cpm-progress.md` (dotfile in the plans directory)
**Rationale**: Sits alongside planning artifacts. Dotfile prefix hides it from normal listings. Ties state to where CPM outputs live.
**Alternatives considered**: `.claude/cpm-progress.md` (conventional but disconnects state from planning artifacts)

### Hook Architecture
**Choice**: Three shell scripts — `pre-compact.sh`, `session-start-compact.sh`, `session-start.sh` — configured via `hooks/hooks.json` in the plugin
**Rationale**: Plugin hooks install automatically. Separate scripts per trigger keep logic simple. `${CLAUDE_PLUGIN_ROOT}` resolves script paths; `$CLAUDE_PROJECT_DIR` resolves the state file.
**Alternatives considered**: Single script with event routing (adds complexity for no benefit)

## Scope

### In Scope
- State-writing instructions added to all three SKILL.md prompts (discover, spec, stories)
- State file at `docs/plans/.cpm-progress.md`
- `hooks/hooks.json` with PreCompact, SessionStart (compact), and SessionStart (startup/resume) configurations
- `hooks/pre-compact.sh` — summary guidance for compaction
- `hooks/session-start-compact.sh` — state re-injection after compaction
- `hooks/session-start.sh` — state re-injection on startup/resume (with offer to continue or discard)
- State file cleanup on skill completion
- Updated plugin.json (version bump)

### Out of Scope
- Transcript backup
- State file versioning or format migration
- "Retain verbatim" markers
- UI for viewing/managing state

### Deferred
- PreCompact transcript backup
