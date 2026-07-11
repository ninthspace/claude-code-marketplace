# Spec: CPM Consult Skill

**Date**: 2026-02-19
**Brief**: docs/discussions/04-discussion-consult-skill.md

## Problem Summary

Party mode (`cpm:party`) enables multi-perspective brainstorming where 2-3 agents respond per turn, selected by the system. This is powerful for surfacing trade-offs but doesn't serve a different need: focused, deep consultation with a single expert agent where the user drives the conversation. The `cpm:consult` skill fills this gap — a one-to-one conversation with a chosen agent, user-controlled membership via invite/dismiss, user-led by default with transferable facilitation lead, sharing party mode's roster, state management, discussion record format, and pipeline handoff.

## Functional Requirements

### Must Have
1. **Agent selection on entry** — User invokes `/cpm:consult` with an optional agent name or role. If none specified, prompted to pick from the roster.
2. **One-to-one conversation loop** — Selected agent responds in character every turn. Single-agent responses feel like a dialogue, not a panel.
3. **Invite command** — User can invite additional agents mid-conversation by name or role (e.g. "invite Bella", "bring in the architect"). Newly invited agents join with full context and announce their presence. Inviting an already-active agent returns a no-op confirmation.
4. **Dismiss command** — User can remove agents from the conversation. If the dismissed agent was leading, lead returns to user. Dismissing the only agent prompts for a new invite, doesn't exit.
5. **Lead transfer** — User leads by default. Explicit handover to an agent (e.g. "Margot, take the lead") switches mode: the agent drives the conversation, asks probing questions, structures the exploration. Other active agents defer to the lead unless directly addressed. Handing lead to an inactive agent auto-invites them.
6. **Natural lead reclaim** — User reclaims the lead by directing the conversation (asking a direct question, giving a directive, changing topic). Agent recognises the shift and defers.
7. **Roster loading** — Same as party: check `docs/agents/roster.yaml` first, fall back to plugin default. If neither exists, stop with an error message.
8. **Exit with discussion record** — Same exit flow as party: save to `docs/discussions/{nn}-discussion-{slug}.md` using the same format and numbering scheme.
9. **Pipeline handoff on exit** — After saving record, offer continue to discover/spec/epics or just exit. Pass discussion record file path as input to the next skill.
10. **Compaction resilience** — Progress file at `docs/plans/.cpm-progress-{session_id}.md` with active agents, lead state, and discussion highlights. Same session ID, resume adoption, and write-full-file patterns as party.
11. **Agent-led behavioural shift** — When an agent has the lead, their responses are qualitatively different: probing, structured, challenging. Not just answering. Other active agents defer to the lead unless directly addressed.
12. **Library check** — Same as party: scan `docs/library/*.md` for scope-matching documents (`party` or `all`) at startup. Graceful degradation for malformed front-matter.
13. **Agent-to-agent handover** — A leading agent can suggest handing to another agent ("This is more Bella's area — Bella, want to take this?"), user confirms before the handover happens.

### Should Have
14. **Multi-agent response ordering** — When multiple agents are active, they respond in roster order. The primary (first invited) agent responds first.
15. **Lead agent indicator** — Visual cue showing who currently has the lead (e.g. a marker next to the leading agent's name).

### Could Have
(None this iteration)

### Won't Have (this iteration)
- Automated agent selection — unlike party, consult doesn't auto-select agents. User always controls who's in the room.
- Rotation tracking — no need for rotation awareness since membership is explicit.
- Separate artifact format — uses the same discussion record as party.

## Non-Functional Requirements

### Usability
- Commands (invite, dismiss, handover) recognised from natural phrasing, not rigid syntax. The skill describes intent categories with examples; the LLM handles fuzzy matching.
- When multiple agents are active, responses remain visually scannable — same icon + bold name formatting as party.
- The shift between user-led and agent-led should be obvious in the agent's tone and response style, not just tracked in state.

### Consistency
- Same state management pattern as party (`.cpm-progress-{session_id}.md` + hooks)
- Same file conventions (`docs/discussions/`, `docs/agents/roster.yaml`)
- Same exit flow and pipeline handoff options
- SKILL.md structure follows the same template as other CPM skills

### Maintainability
- Skill references the shared roster YAML — no hardcoded persona data
- Edge case handling (dismiss-only-agent, invite-already-active, hand-lead-to-inactive, agent-reference-by-role) is specified explicitly in the skill instructions

## Architecture Decisions

### Skill Structure
**Choice**: Single SKILL.md at `cpm/skills/consult/SKILL.md`
**Rationale**: Follows existing CPM pattern. The conversation loop for consult is simpler than party's — no agent selection heuristics or rotation tracking. A single SKILL.md is more than sufficient.
**Alternatives considered**: Multi-file workflow (overkill for a conversation loop), embedding in party SKILL.md (muddies both skills' responsibilities)

### Command Recognition
**Choice**: Natural language recognition with explicit intent categories and examples in SKILL.md
**Rationale**: The LLM handles fuzzy matching natively. Rigid syntax would feel jarring in a conversational skill. The SKILL.md describes categories (invite, dismiss, handover, reclaim) with example phrases.
**Alternatives considered**: Slash-command syntax like `/invite Bella` (too formal for a conversation), keyword-only matching (too fragile, risk of false positives like "dismiss that idea")

### State Management
**Choice**: Same `.cpm-progress-{session_id}.md` pattern as party, with two additional fields: `Active agents` (ordered list) and `Lead` (user or agent name)
**Rationale**: Zero new infrastructure. Existing hooks already detect any progress file regardless of which skill wrote it. Follows the retro recommendation to maintain consistent SKILL.md structure.
**Alternatives considered**: Separate state file format (unnecessary divergence from party), no state tracking (unacceptable for long consultations that may hit compaction)

### Library Scope
**Choice**: Same scope filter as party (`party` or `all`). No consult-specific library tag.
**Rationale**: Documents are documents — a reference document relevant to a party discussion is equally relevant to a consultation. Adding a separate scope tag creates unnecessary granularity.
**Alternatives considered**: Consult-specific scope tag (over-engineering for no user benefit)

## Scope

### In Scope
- New `cpm/skills/consult/SKILL.md` — complete skill definition
- Skill registration in CPM's skill manifest/configuration
- Update `cpm-presentation.html` to include consult skill
- Update `cpm-onboarding-presentation.html` to include consult skill
- Update `cpm-training-guide.html` to include consult skill
- Plugin version bump

### Out of Scope
- Changes to party mode's SKILL.md
- Changes to the roster format or default roster content
- Changes to hooks or state management infrastructure
- New library scope tags
- Automated testing of persona quality

### Deferred
- Per-session agent memory (agents remembering context from previous consult sessions)
- Consult-specific discussion record header (e.g. "Consultation" vs "Discussion")

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
| Agent selection on entry | User invokes `/cpm:consult Margot` → Margot is selected and responds first | `[manual]` |
| Agent selection on entry | User invokes `/cpm:consult` with no argument → prompted to pick an agent | `[manual]` |
| Agent selection on entry | User invokes `/cpm:consult architect` (by role) → correct agent selected | `[manual]` |
| One-to-one conversation loop | With one active agent, only that agent responds each turn | `[manual]` |
| One-to-one conversation loop | Responses are in character with agent's personality and communication style | `[manual]` |
| Invite command | "invite Bella" adds Bella to active agents, she announces presence | `[manual]` |
| Invite command | "bring in the architect" resolves role to agent and invites them | `[manual]` |
| Invite command | Inviting an already-active agent returns a no-op confirmation | `[manual]` |
| Dismiss command | "dismiss Bella" removes Bella from active agents | `[manual]` |
| Dismiss command | Dismissing the leading agent returns lead to user | `[manual]` |
| Dismiss command | Dismissing the only agent prompts for new invite, doesn't exit | `[manual]` |
| Lead transfer | "Margot, take the lead" switches lead to Margot | `[manual]` |
| Lead transfer | After handover, agent's responses shift to probing/driving mode | `[manual]` |
| Natural lead reclaim | User asks direct question while agent leads → agent defers, lead returns to user | `[manual]` |
| Roster loading | Loads from `docs/agents/roster.yaml` if present, else plugin default | `[manual]` |
| Roster loading | If neither roster exists, skill stops with error message | `[manual]` |
| Exit with discussion record | On exit, record saved to `docs/discussions/{nn}-discussion-{slug}.md` | `[manual]` |
| Exit with discussion record | Record format matches party's discussion record format | `[manual]` |
| Pipeline handoff | After saving record, user offered discover/spec/epics/just-exit options | `[manual]` |
| Compaction resilience | Progress file created at session start with active agents and lead state | `[unit]` |
| Compaction resilience | Progress file updated after substantive exchanges | `[manual]` |
| Compaction resilience | Progress file contains enough context for seamless continuation | `[manual]` |
| Agent-led behavioural shift | When agent leads, responses are qualitatively different (probing, structured) | `[manual]` |
| Agent-led behavioural shift | Other active agents defer to lead unless directly addressed | `[manual]` |
| Library check | Scans `docs/library/*.md` for scope-matching documents at startup | `[manual]` |
| Library check | Gracefully skips if no library or no matching documents | `[manual]` |
| Agent-to-agent handover | Leading agent suggests handing to another agent, user confirms | `[manual]` |
| Agent-to-agent handover | After confirmation, new agent takes the lead | `[manual]` |

### Integration Boundaries
- **Roster YAML** — Consult reads the same `roster.yaml` as party. The roster format (name, displayName, icon, role, personality, communicationStyle) is the contract.
- **Progress file / hooks** — Consult writes `.cpm-progress-{session_id}.md` with `**Skill**: cpm:consult` header. Existing hooks detect and inject this file on startup and after compaction.
- **Discussion record** — Output to `docs/discussions/` follows the same numbering and format as party. Downstream skills (discover, spec, epics) consume these files by path.
- **Pipeline handoff** — Consult passes the discussion record file path as `$ARGUMENTS` to the next skill. The receiving skill reads the file — same contract as party's handoff.

### Test Infrastructure
No new test infrastructure required. The existing hook test suite (`test-helpers.sh`, bash test runner) can be extended to verify that a consult-style progress file (with `Active agents` and `Lead` fields) is correctly detected and injected by hooks.

### Unit Testing
Unit testing of individual components is handled at the `cpm:do` task level — each story's acceptance criteria drive test coverage during implementation.
