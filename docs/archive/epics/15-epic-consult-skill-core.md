# Consult Skill Core

**Source spec**: docs/specifications/18-spec-consult-skill.md
**Date**: 2026-02-19
**Status**: Complete
**Blocked by**: —

## Create core conversation loop and agent selection
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: Agent selection on entry, One-to-one conversation loop, Roster loading, Exit with discussion record, Pipeline handoff on exit

**Acceptance Criteria**:
- User invokes `/cpm:consult Margot` → Margot is selected and responds first `[manual]`
- User invokes `/cpm:consult` with no argument → prompted to pick an agent `[manual]`
- User invokes `/cpm:consult architect` (by role) → correct agent selected `[manual]`
- With one active agent, only that agent responds each turn `[manual]`
- Responses are in character with agent's personality and communication style `[manual]`
- Loads from `docs/agents/roster.yaml` if present, else plugin default `[manual]`
- If neither roster exists, skill stops with error message `[manual]`
- On exit, record saved to `docs/discussions/{nn}-discussion-{slug}.md` `[manual]`
- Record format matches party's discussion record format `[manual]`
- After saving record, user offered discover/spec/epics/just-exit options `[manual]`

### Create SKILL.md with front-matter and input handling
**Task**: 1.1
**Description**: Scaffold `cpm/skills/consult/SKILL.md` with front-matter (name, description) and input section — $ARGUMENTS handling for file path, URL, description, or prompt to pick an agent by name/role.
**Status**: Complete

### Write roster loading and agent presentation
**Task**: 1.2
**Description**: Add roster loading section — project override (`docs/agents/roster.yaml`) then plugin default (`../../agents/roster.yaml`), error if neither found. Present selected agent to the user.
**Status**: Complete

### Write conversation loop
**Task**: 1.3
**Description**: Add the core orchestration loop — user sends message, active agent(s) respond in character using icon + bold name format. Single-agent mode feels like a 1:1 dialogue. Include exit option prompt after each response.
**Status**: Complete

### Write exit handling and discussion record
**Task**: 1.4
**Description**: Add exit detection (exit/done/end/quit/goodbye), discussion record save to `docs/discussions/`, and pipeline handoff options (discover/spec/epics/just-exit). Same format and flow as party mode.
**Status**: Complete
**Retro**: [Smooth delivery] Core SKILL.md structure followed party mode's pattern closely — each section was a straightforward adaptation with clear references to copy from.

---

## Add invite and dismiss commands
**Story**: 2
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: Invite command, Dismiss command, Multi-agent response ordering

**Acceptance Criteria**:
- "invite Bella" adds Bella to active agents, she announces presence `[manual]`
- "bring in the architect" resolves role to agent and invites them `[manual]`
- Inviting an already-active agent returns a no-op confirmation `[manual]`
- "dismiss Bella" removes Bella from active agents `[manual]`
- Dismissing the only agent prompts for new invite, doesn't exit `[manual]`
- When multiple agents active, they respond in roster order `[manual]`

### Add invite command to conversation loop
**Task**: 2.1
**Description**: Add invite mechanics — recognise natural language invite phrases, resolve by name or role, add to active agents list, agent announces presence. Handle no-op for already-active agents.
**Status**: Complete

### Add dismiss command to conversation loop
**Task**: 2.2
**Description**: Add dismiss mechanics — recognise natural language dismiss phrases, remove from active agents list. Handle dismiss-only-agent (prompt for new invite) and dismiss-all (same behaviour).
**Status**: Complete

### Add multi-agent response behaviour
**Task**: 2.3
**Description**: Specify how multiple active agents respond — roster order, primary agent first, agents can reference each other. Addresses the shift from 1:1 to multi-agent conversation dynamics.
**Status**: Complete
**Retro**: [Smooth delivery] Invite, dismiss, and multi-agent dynamics were straightforward additions — each section followed a clear pattern of recognition + behaviour + edge cases.

---

## Add lead transfer and agent-led mode
**Story**: 3
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: Lead transfer, Natural lead reclaim, Agent-led behavioural shift, Agent-to-agent handover, Lead agent indicator

**Acceptance Criteria**:
- "Margot, take the lead" switches lead to Margot `[manual]`
- After handover, agent's responses shift to probing/driving mode `[manual]`
- User asks direct question while agent leads → agent defers, lead returns to user `[manual]`
- When agent leads, responses are qualitatively different (probing, structured) `[manual]`
- Other active agents defer to lead unless directly addressed `[manual]`
- Dismissing the leading agent returns lead to user `[manual]`
- Leading agent suggests handing to another agent, user confirms `[manual]`
- After confirmation, new agent takes the lead `[manual]`

### Add lead transfer mechanics
**Task**: 3.1
**Description**: Add lead state (user or agent name) and explicit handover recognition. Include auto-invite when handing lead to an inactive agent. Add visual lead indicator.
**Status**: Complete

### Write agent-led behavioural instructions
**Task**: 3.2
**Description**: Describe the qualitative shift when an agent leads — probing questions, structured exploration, challenging assumptions. Other agents defer unless directly addressed.
**Status**: Complete

### Write natural lead reclaim logic
**Task**: 3.3
**Description**: Describe how the agent recognises the user reclaiming the lead — direct question, directive, topic change — and defers back to responsive mode.
**Status**: Complete

### Add agent-to-agent handover
**Task**: 3.4
**Description**: Describe how a leading agent can suggest handing to another agent, user confirmation required, and the resulting lead state change.
**Status**: Complete
**Retro**: [Pattern worth reusing] Writing all four lead transfer sub-tasks as one cohesive section (rather than four separate additions) produced a more coherent result — the lead state, handover, behaviour, reclaim, and agent-to-agent handover flow naturally as subsections of one concept.

---

## Add state management and library check
**Story**: 4
**Status**: Complete
**Blocked by**: —
**Satisfies**: Compaction resilience, Library check

**Acceptance Criteria**:
- Progress file created at session start with active agents and lead state `[unit]`
- Progress file updated after substantive exchanges `[manual]`
- Progress file contains enough context for seamless continuation `[manual]`
- Scans `docs/library/*.md` for scope-matching documents at startup `[manual]`
- Gracefully skips if no library or no matching documents `[manual]`

### Write state management section
**Task**: 4.1
**Description**: Add progress file pattern with consult-specific fields (Active agents, Lead). Copy party's State Management template, add the two new fields. Include session ID, resume adoption, path resolution.
**Status**: Complete

### Write library check section
**Task**: 4.2
**Description**: Add library check at startup — same as party's pattern (glob, front-matter, scope filter for `party` or `all`, graceful degradation for malformed front-matter).
**Status**: Complete
**Retro**: [Smooth delivery] State management and library check were direct copies of party's template with minimal adaptation — the two extra fields (Active agents, Lead) were the only changes needed.

## Lessons

### Smooth Deliveries
- Story 1: Core SKILL.md structure followed party mode's pattern closely — each section was a straightforward adaptation with clear references to copy from.
- Story 2: Invite, dismiss, and multi-agent dynamics were straightforward additions — each section followed a clear pattern of recognition + behaviour + edge cases.
- Story 4: State management and library check were direct copies of party's template with minimal adaptation.

### Patterns Worth Reusing
- Story 3: Writing all four lead transfer sub-tasks as one cohesive section (rather than four separate additions) produced a more coherent result — the lead state, handover, behaviour, reclaim, and agent-to-agent handover flow naturally as subsections of one concept.
