# Discussion: Speccing a new cpm:consult skill

**Date**: 2026-02-19
**Agents**: Jordan, Margot, Bella, Priya, Tomas, Elli

## Key Decisions

1. **Separate skill, not a party modifier** — The one-to-one conversation pattern has fundamentally different orchestration mechanics from party mode. A dedicated `cpm:consult` skill shares the same roster and artifact pipeline but has its own simpler loop.

2. **User leads by default** — In consult mode the user is the facilitator, not the system. The user asks questions, steers topics, decides when to go deeper. Agents respond as expert witnesses.

3. **Explicit handover, natural reclaim** — User can hand the lead to an agent explicitly (e.g. "Margot, take the lead"), at which point the agent drives: asking probing questions, pushing back, structuring exploration. The user reclaims the lead naturally by simply directing the conversation again (asking a direct question, changing topic). The agent recognises the shift and defers.

4. **Invite doesn't change lead** — Adding a new agent to the conversation does not affect who is currently leading. The new agent joins in whatever mode is current.

5. **Same discussion record as party** — Output artifact uses the same `docs/discussions/` path, numbering scheme, format, and pipeline handoff options. A consultation is just a discussion with different dynamics — the artifact format should be consistent regardless of how many agents participated.

## Core Mechanics

### Entry
- User invokes the skill, optionally naming an agent (e.g. `/cpm:consult Margot`)
- If no agent named, user is prompted to pick one from the roster

### Conversation Loop
1. User sends message
2. Each active agent generates a response (in roster order)
3. If only one agent active → single response, feels like 1:1 dialogue
4. If multiple agents active → they respond in sequence, can reference each other
5. Check for commands: invite, dismiss, lead handover, exit

### State Model
- **Active agents**: ordered list, starts as exactly one, grows via invite, shrinks via dismiss
- **Lead**: either `user` (default) or an agent name
- **Conversation context**: full history (no context transfer needed — all agents share the same Claude context window)

### Commands
- **Invite**: "invite Bella" — adds agent to active list. Agent joins with full context, announces presence.
- **Dismiss**: "dismiss Bella" — removes agent from active list. If dismissed agent was leading, lead returns to user.
- **Hand over lead**: "Margot, take the lead" — sets lead to named agent. If agent not active, auto-invites them.
- **Reclaim lead**: User starts leading naturally (direct question, directive, topic change). Agent recognises and defers.

## Edge Cases (flagged by Tomas)

- **Dismiss the only agent**: Don't exit. Prompt user to invite someone else.
- **Invite an already-active agent**: No-op with confirmation ("Bella is already in the conversation.")
- **Hand lead to an inactive agent**: Auto-invite them first.
- **Agent reference by role**: Support lookup by role ("invite the architect") not just display name.
- **All agents dismissed**: Same as dismiss-the-only-agent — prompt, don't exit.

## Shared Infrastructure with Party Mode

| Aspect | Party | Consult |
|---|---|---|
| Roster | Same | Same |
| Progress file | Same pattern | Same pattern + Lead + Active agents fields |
| Discussion record | Same format | Same format |
| Exit flow | Same | Same |
| Pipeline handoff | Same | Same |
| Agent selection | Automated, 2-3 per turn | User-controlled, starts at 1 |
| Lead | System (orchestrator) | User (default), transferable |
| Agent addition | Automatic rotation | Explicit invite |
| Agent removal | N/A | Explicit dismiss |

## Behavioural Differences by Lead State

- **User leads**: Agents respond to questions, offer expertise, stay concise. Responsive mode.
- **Agent leads**: Lead agent drives — asks probing questions, suggests structure, challenges assumptions. Other active agents defer unless directly addressed.

## Artifact Notes (from Elli)

- Same `docs/discussions/` output path, same numbering scheme
- Header says "Consultation" or "Discussion" — format is the same regardless
- Progress file needs two extra fields vs party: `Lead` and `Active agents`
