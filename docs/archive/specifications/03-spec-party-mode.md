# Spec: CPM Party Mode

**Date**: 2026-02-10
**Inspiration**: [BMAD-METHOD Party Mode](https://github.com/bmad-code-org/BMAD-METHOD)

## Problem Summary

CPM facilitates planning through a structured pipeline (discover → spec → stories → do), but all facilitation comes from a single AI perspective. This means trade-offs, blind spots, and alternative viewpoints only surface if the user thinks to raise them. Inspired by BMAD-METHOD's "party mode," we want to bring multi-perspective responses into CPM — both as a standalone discussion skill and as enhanced facilitation within existing planning skills. The core idea: the LLM role-plays as multiple specialist personas (architect, PM, UX designer, etc.) who respond in character, build on each other's points, and constructively disagree — surfacing richer analysis than a single viewpoint.

## Functional Requirements

### Must Have
- Standalone `/cpm:party` skill that launches a multi-persona discussion session
- Agent roster of ~6-8 named software planning personas, each with a distinct name, icon, role description, personality, and communication style
- Default personalities that naturally reflect each agent's professional role
- Orchestrated turn structure: 2-3 agents respond per user message, selected by topic relevance
- Clear visual formatting: each agent's contribution prefixed with icon + bold name
- Agents reference, build on, and constructively disagree with each other's points
- Exit mechanism: user can end party mode gracefully at any time
- Topic/context seeding: party mode accepts a topic description, file path, or URL as starting context
- Discussion summary on exit: structured summary of key points, agreements, and open questions when party mode ends
- Party-to-pipeline handoff: from a party discussion, user can transition into discover/spec/stories with discussion context carried forward as input

### Should Have
- Multi-perspective mode in `/cpm:discover`: at Why and Constraints phases, agents weigh in with diverse viewpoints before the user answers
- Multi-perspective mode in `/cpm:spec`: at Architecture Decisions and Scope Boundary sections, agents present competing trade-offs
- Intelligent agent selection: orchestrator picks agents based on topic relevance, not rotation. Named agents respond when directly addressed
- Compaction resilience: party mode writes state to `.cpm-progress.md`, leveraging existing hook system

### Could Have
- Custom agent rosters: users create `docs/agents/roster.yaml` in their project to override the default roster with custom personas

### Won't Have (this iteration)
- 19+ agents (BMAD scale) — keeping roster focused at ~6-8
- Historical or archetypal personas (no Steve Jobs, Leonardo da Vinci)
- Creative/brainstorming-specific personas (BMAD's CIS module)
- Changes to `/cpm:stories` or `/cpm:do` — multi-perspective isn't needed in task breakdown or execution
- Multi-LLM orchestration — this is single-context persona switching
- Automated testing of persona quality or consistency

## Non-Functional Requirements

### Usability
- Multi-agent responses must be visually scannable — icon + bold name prefix per agent, clear separation between contributions
- Maximum 2-3 agents per turn to avoid overwhelming the user
- Disagreement should be constructive and substantive, not artificial conflict

### Consistency
- Party mode must feel like a natural CPM skill, not a bolted-on feature
- Same state management pattern (`.cpm-progress.md` + hooks)
- Same file conventions (`docs/` directory structure)

### Maintainability
- Agent roster defined as structured YAML data, not hardcoded in prompt text
- Skill follows CPM's existing SKILL.md conventions

## Architecture Decisions

### Agent Roster Format
**Choice**: YAML file with named personas
**Rationale**: Human-readable, supports multi-line personality descriptions, easy to edit. Better than CSV for rich persona data.
**Alternatives considered**: CSV (BMAD's approach — awkward for multi-line content), JSON (more verbose), embedded in prompt (no separation of data and logic)

### Roster Location & Customisation
**Choice**: Default roster at `agents/roster.yaml` in the plugin directory (read-only, overwritten on updates). Project override at `docs/agents/roster.yaml` (user-owned, survives updates). Skill checks project first, falls back to plugin default. Full replacement, no merge logic.
**Rationale**: Plugin files are replaced on update, so user edits there are lost. Project-local override is simple and predictable.
**Alternatives considered**: Merge user customisations with defaults (complex, error-prone), CLI arguments per session (too cumbersome)

### Skill Structure
**Choice**: Single `SKILL.md` with inline orchestration instructions, referencing the roster YAML
**Rationale**: Follows existing CPM pattern. Party mode is a conversation loop, not a phased pipeline — multi-file steps would add unnecessary complexity.
**Alternatives considered**: Multi-step workflow files like BMAD (overkill for a conversation loop), separate orchestrator agent (over-engineering)

### Integration with Existing Skills
**Choice**: Add a "Perspectives" instruction block to discover and spec SKILL.md files, activated at specific phases/sections
**Rationale**: Lightweight — a few paragraphs of instruction at designated decision points. No new files or infrastructure needed.
**Alternatives considered**: Separate include files (file management overhead), always-on party mode in planning (too noisy)

### State Management
**Choice**: Extend existing `.cpm-progress.md` pattern. Party mode writes topic, active agents, and discussion highlights. Existing hooks handle compaction resilience without modification.
**Rationale**: Zero new infrastructure — the hook system already works.
**Alternatives considered**: Separate state file (unnecessary), no state tracking (risky for long discussions)

## Scope

### In Scope
- New `/cpm:party` skill (SKILL.md + orchestration logic)
- Default agent roster YAML (~6-8 software planning personas with names and personalities)
- Project-level roster override (`docs/agents/roster.yaml`)
- Multi-perspective enhancements to `/cpm:discover` (Why, Constraints phases)
- Multi-perspective enhancements to `/cpm:spec` (Architecture, Scope sections)
- Discussion summary on exit
- Party-to-pipeline handoff (party → discover/spec/stories)
- Compaction resilience via existing state management
- Plugin version bump to 1.3.0

### Out of Scope
- Changes to `/cpm:stories` or `/cpm:do`
- Multi-LLM distributed agent orchestration
- Creative, brainstorming, or historical personas
- Automated persona quality testing

### Deferred
- Per-agent YAML files instead of single roster (only if roster grows significantly beyond ~8)
