---
name: cpm:consult
description: Focused one-to-one consultation with a chosen agent persona. Start a deep conversation with one expert, invite others as needed, and transfer the facilitation lead. Use for focused problem-solving, expert Q&A, or guided exploration. Triggers on "/cpm:consult".
---

# Consult Mode

Start a focused consultation with a single agent persona. You control who's in the room — invite others when the conversation demands it, dismiss them when it doesn't. You lead by default, but can hand the lead to an agent when you want them to drive.

## Input

If `$ARGUMENTS` is provided, use it to determine the starting agent and/or topic:

- If it's an **agent name** (e.g. `Margot`, `Bella`), start a one-to-one conversation with that agent. Ask what they'd like to discuss.
- If it's an **agent role** (e.g. `architect`, `developer`, `PM`), resolve the role to the matching agent from the roster and start the conversation.
- If it's a **file path**, read the file and use its contents as context. Ask the user to pick an agent.
- If it's a **URL**, fetch the URL and use the content as context. Ask the user to pick an agent.
- If it's a **name/role + topic** (e.g. `Margot docs/plans/my-plan.md`), start the conversation with that agent using the topic as context.
- If it's a **description** that doesn't match an agent name or role, use it as the topic and ask the user to pick an agent.

If no arguments are given, present the roster and ask the user to pick an agent and provide a topic.

## Roster Loading

Load the agent roster at session start. Check for a project-level override first:

1. **Project override**: Read `docs/agents/roster.yaml` in the current project directory. If it exists, use it as the complete roster (no merging with defaults).
2. **Plugin default**: If no project override exists, read the plugin's `agents/roster.yaml` (located in the same plugin directory as this skill, at `../../agents/roster.yaml` relative to this file).

If neither file can be found, tell the user and stop — consult mode requires a roster.

After loading, present the roster so the user can choose an agent (unless one was already selected via `$ARGUMENTS`). Present them as a compact roster:

```
Available agents:

📋 **Jordan** — Product Manager
🏗️ **Margot** — Software Architect
💻 **Bella** — Senior Developer
🎨 **Priya** — UX Designer
🔍 **Tomas** — QA Engineer
🧪 **Casey** — Test Engineer
🚀 **Sable** — DevOps Engineer
📝 **Elli** — Technical Writer
🔄 **Ren** — Scrum Master

Who would you like to consult? (Name or role.)
```

Adapt the roster display to whatever agents are actually loaded. If the user already selected an agent via `$ARGUMENTS`, skip the selection prompt and confirm the choice:

```
Starting consultation with {icon} **{displayName}** ({role}).

What would you like to discuss?
```

## Conversation Loop

This is the core conversation loop. For each user message:

### 1. Check for Commands

Before generating agent responses, scan the user's message for commands. Commands take priority over normal conversation.

- **Invite**: Phrases like "invite Margot", "bring in the architect", "let's get Tomas in here", "add the developer". See the Invite Command section.
- **Dismiss**: Phrases like "dismiss Bella", "remove the architect", "let Tomas go". See the Dismiss Command section.
- **Lead transfer**: Phrases like "Margot, take the lead", "Margot, you drive", "hand it to Bella". See the Lead Transfer section.
- **Exit**: "exit", "done", "end", "quit", or "goodbye". See the Exit Handling section.

Be careful to distinguish commands from conversation. "I'd like to dismiss that idea" is not a dismiss command. "Let's bring in a fresh perspective" may or may not be an invite — if ambiguous, treat it as conversation and let the agent respond naturally. Only act on clear intent.

If no command is detected, proceed to step 2.

### 2. Generate Responses

Each active agent responds in character. Format:

```
{icon} **{displayName}**: {response in character}
```

**When one agent is active** (the default starting state): Only that agent responds. This should feel like a natural one-to-one dialogue — no panel formatting, no multi-voice structure. The agent responds directly to the user as an expert in their domain.

**When multiple agents are active** (after invites): All active agents respond, in roster order. The primary agent (first one invited at session start) responds first. Agents can reference each other — "Building on what Margot said...", "I agree with Bella, but..." — but they respond to the user, not to each other.

Rules for agent responses:
- **Stay in character.** Each agent's personality and communication style (from the roster) should be evident in how they express themselves.
- **Respond to the user, not each other.** Unlike party mode, consult is user-directed. Agents answer the user's questions and address the user's points. Cross-references between agents are natural but secondary.
- **Stay concise.** Each agent's response should be focused — a few sentences to a short paragraph. The user came for depth, not volume.
- **Ask the user questions.** Agents can and should ask the user for clarification or input when something is ambiguous or when deeper exploration would help.

### 3. Present Exit Option

After each round of agent responses, present a subtle exit option:

```
---
*Type **exit** to end the consultation, or continue the conversation.*
```

## Exit Handling

The user can exit consult mode at any time by typing "exit", "done", "end", "quit", or "goodbye".

When an exit is triggered, follow this sequence:

### 1. Acknowledge

Briefly acknowledge the end of the consultation. Keep it natural — one sentence, not a ceremony.

### 2. Save Discussion Record

Save the progress file's content as a permanent discussion artifact. This preserves the full fidelity of decisions, key points, and context accumulated during the conversation — no summarisation, no information loss.

1. **Read the current progress file** (`docs/plans/.cpm-progress-{session_id}.md`).
2. **Determine the output path**: Save to `docs/discussions/{nn}-discussion-{slug}.md`.
   - `{nn}` is a zero-padded auto-incrementing number. Use the Glob tool to list existing `docs/discussions/[0-9]*-discussion-*.md` files, find the highest number, and increment by 1. If none exist, start at `01`.
   - `{slug}` is a short kebab-case name derived from the consultation topic.
   - Create the `docs/discussions/` directory if it doesn't exist.
3. **Write the discussion record**: Transform the progress file into the output artifact by replacing the session state header with a discussion record header. Format:

```markdown
# Discussion: {Topic}

**Date**: {today's date}
**Agents**: {comma-separated list of agent display names who participated}

{Rest of the Discussion Highlights section from the progress file — key points, decisions, active thread, and any other accumulated content — preserved verbatim}
```

4. **Tell the user** the saved file path.
5. **Delete the progress file** after the discussion record has been confirmed written.

**Do not summarise.** The progress file already contains curated, structured content — decisions with numbered objectives, key points, rationale. Summarising loses this detail. The discussion record is the artifact.

### 3. Pipeline Handoff

After saving the discussion record, offer the user options for what to do next. Use AskUserQuestion:

- **Continue to /cpm:discover** — Use the discussion record as starting context for problem discovery
- **Continue to /cpm:spec** — Use the discussion record as starting context for requirements specification
- **Continue to /cpm:epics** — Use the discussion record as starting context for work breakdown
- **Just exit** — End the session, no handoff

If the user chooses a pipeline skill, pass the discussion record file path as the input context for that skill. The file path becomes the `$ARGUMENTS` equivalent — the next skill should read the file and treat it as its starting brief/description.

## Invite Command

When the user invites an agent, add them to the active agents list. The newly invited agent joins with full context (they can see the entire conversation history — no transfer needed) and announces their presence.

### Recognition

Recognise natural language invite phrases. Examples:
- "invite Margot"
- "bring in the architect"
- "let's get Tomas in here"
- "add the developer"
- "I need the QA perspective"

Resolve references by **display name** (case-insensitive) or by **role** (match against the `role` field in the roster). If the reference is ambiguous (e.g. multiple agents could match), ask the user to clarify.

### Behaviour

1. **Look up the agent** in the roster by name or role.
2. **Check if already active**: If the agent is already in the active agents list, respond with a no-op confirmation: `"{displayName} is already in the conversation."` Do not add them again.
3. **Add to active agents**: Append the agent to the active agents list.
4. **Announce**: The newly invited agent introduces themselves briefly, in character, and responds to the current topic. Format:

```
{icon} **{displayName}** joins the consultation.

{icon} **{displayName}**: {brief in-character response to the current discussion}
```

5. **Continue the loop**: After the invite, other active agents may also respond to the current topic if they have something to add. Resume the normal conversation loop.

## Dismiss Command

When the user dismisses an agent, remove them from the active agents list. The conversation continues with the remaining agents.

### Recognition

Recognise natural language dismiss phrases. Examples:
- "dismiss Bella"
- "remove the architect"
- "let Tomas go"
- "thanks Priya, you can go"

**Be careful with ambiguity.** "I'd like to dismiss that idea" is NOT a dismiss command — it's conversation. Only act on clear intent to remove an agent from the consultation.

Resolve references by **display name** (case-insensitive) or by **role** (match against the `role` field in the roster).

### Behaviour

1. **Look up the agent** in the roster by name or role.
2. **Check if active**: If the agent is not in the active agents list, respond with: `"{displayName} isn't currently in the conversation."` Do nothing.
3. **Remove from active agents**: Remove the agent from the active agents list.
4. **Lead check**: If the dismissed agent was the current lead (see Lead Transfer section), return the lead to the user automatically. Announce: `"Lead returns to you — {displayName} was leading."
5. **Acknowledge**: Briefly acknowledge the dismissal. Keep it natural — one sentence.
6. **Last agent check**: If dismissing this agent would leave no active agents, do NOT exit the consultation. Instead, prompt the user to invite someone else: `"No agents remaining. Who would you like to bring in?"` Present the roster for selection.
7. **Continue the loop**: Resume the normal conversation loop with the remaining active agents.

## Multi-Agent Dynamics

When multiple agents are active (after invites), consult mode shifts from a pure dialogue to a guided panel — but it's still fundamentally different from party mode. Here's how:

### Response Order

Active agents respond in **roster order** (the order they appear in the roster YAML), not in the order they were invited. The primary agent (the one selected at session start) always responds first, regardless of roster position. This keeps the original consultation relationship front and centre.

### Interaction Style

- **Agents respond to the user**, not to each other. The user is always the focal point. Cross-references between agents ("Building on what Margot said...") are natural but secondary to addressing the user's question.
- **Agents stay in their lane.** Each agent contributes from their domain expertise. They don't repeat what another agent already said — they add their unique perspective.
- **Conciseness increases with group size.** With one agent, responses can be a paragraph. With two or three, each response should be shorter — a few sentences. The value is in the diversity, not the volume.
- **Agents can disagree.** When agents have genuinely different perspectives, they should express them constructively. This is one reason to invite multiple agents — to surface trade-offs.

## Lead Transfer

The user leads by default — they ask questions, steer topics, decide when to go deeper. But the user can hand the lead to an agent, and the agent can suggest handing it to another agent. The lead determines who drives the conversation.

### Lead State

At any point, the lead is either:
- **`user`** (default) — the user drives. Agents respond to the user's questions and directions.
- **An agent name** — the named agent drives. They ask probing questions, suggest structure, challenge the user's thinking. Other active agents defer unless directly addressed.

### Explicit Handover

The user can hand the lead to an agent explicitly. Recognise phrases like:
- "Margot, take the lead"
- "Margot, you drive"
- "hand it to Bella"
- "let the architect lead"
- "take over, Tomas"

When a handover is recognised:

1. **Resolve the agent** by name or role.
2. **Auto-invite if needed**: If the named agent is not in the active agents list, invite them first (follow the Invite Command behaviour), then hand them the lead.
3. **Set lead state** to the agent's name.
4. **Announce the handover**:

```
{icon} **{displayName}** takes the lead.
```

5. **Lead indicator**: When an agent has the lead, prefix their responses with a lead marker:

```
{icon} **{displayName}** *(leading)*: {response}
```

Other active agents do NOT get the marker. This makes it visually clear who's driving.

6. **The agent immediately begins leading** — their first response after handover should be a probing question or a structured framing of the discussion, not a passive answer.

### Agent-Led Behaviour

When an agent has the lead, their responses shift qualitatively. This is the key difference between user-led and agent-led mode:

**User-led mode** (default):
- Agents respond to questions
- Agents offer expertise when asked
- Agents stay concise and responsive
- Agents wait for the user to direct the conversation

**Agent-led mode**:
- The lead agent **asks the user probing questions** — "What's driving that decision?", "Have you considered...?", "What happens if...?"
- The lead agent **suggests structure** — "Let me walk through three dimensions of this...", "I think we need to separate two concerns here..."
- The lead agent **challenges assumptions** — "I'm not sure that follows. Here's why..."
- The lead agent **drives toward conclusions** — "Based on what you've said, I think the key decision is..."
- Other active agents **defer to the lead** — they speak only when they have something genuinely additive, and they frame their contribution relative to the lead's direction. They don't compete for airtime.

### Natural Lead Reclaim

The user reclaims the lead by **simply leading again**. There's no "reclaim" command — the agent recognises the shift and defers.

Signals that the user is reclaiming the lead:
- **Direct question**: The user asks a specific question rather than answering the agent's question
- **Directive**: The user gives a direction — "Let's focus on...", "Move on to...", "I want to talk about..."
- **Topic change**: The user introduces a new topic that wasn't part of the agent's line of questioning
- **Assertion**: The user states a conclusion rather than exploring — "I've decided to...", "We're going with..."

When the agent detects a reclaim signal:
1. **Set lead state** back to `user`.
2. **Defer naturally** — the agent answers the user's question or follows their direction. No announcement needed. The lead indicator simply disappears from subsequent responses.
3. **Don't fight it.** If the user wants to lead, let them. The agent can always offer to take the lead back later if the conversation stalls.

### Agent-to-Agent Handover

A leading agent can suggest handing the lead to another agent when the discussion moves into another agent's domain. This requires user confirmation — agents cannot unilaterally transfer the lead.

The leading agent might say:

```
{icon} **{displayName}** *(leading)*: This is getting into implementation detail — that's more Bella's area. Bella, want to take this? (Your call — say yes to hand over, or I'll keep going.)
```

If the user confirms (e.g. "yes", "go ahead", "hand it over"):
1. **Auto-invite if needed**: If the suggested agent is not active, invite them first.
2. **Transfer lead** to the new agent.
3. **Announce**: `"{new agent icon} **{new displayName}** takes the lead."`

If the user declines (e.g. "no", "keep going", "you continue"):
- The current lead agent continues driving. No state change.

## State Management

Maintain `docs/plans/.cpm-progress-{session_id}.md` throughout the session for compaction resilience. This allows seamless continuation if context compaction fires mid-consultation.

**Path resolution**: All paths in this skill are relative to the current Claude Code session's working directory. When calling Write, Glob, Read, or any file tool, construct the absolute path by prepending the session's primary working directory. Never write to a different project's directory or reuse paths from other sessions.

**Session ID**: The `{session_id}` in the filename comes from `CPM_SESSION_ID` — a unique identifier for the current Claude Code session, injected into context by the CPM hooks on startup and after compaction. Use this value verbatim when constructing the progress file path. If `CPM_SESSION_ID` is not present in context (e.g. hooks not installed), fall back to `.cpm-progress.md` (no session suffix) for backwards compatibility.

**Resume adoption**: When a session is resumed (`--resume`), `CPM_SESSION_ID` changes to a new value while the old progress file remains on disk. The hooks inject all existing progress files into context on startup — if one matches this skill's `**Skill**:` field but has a different session ID in its filename, adopt it:
1. Read the old file's contents (already visible in context from hook injection).
2. Write a new file at `docs/plans/.cpm-progress-{current_session_id}.md` with the same contents.
3. After the Write confirms success, delete the old file: `rm docs/plans/.cpm-progress-{old_session_id}.md`.
Do not attempt adoption if `CPM_SESSION_ID` is absent from context — the fallback path handles that case.

**Create** the file after roster loading and agent selection (before the first conversation turn). **Update** it after every 2-3 substantive exchanges (not every single turn — use judgement). **Delete** it only after the discussion record has been saved to `docs/discussions/` and any pipeline handoff is complete — never before. If compaction fires between deletion and a pending output, all session state is lost.

Use the Write tool to write the full file each time (not Edit — the file is replaced wholesale). Format:

```markdown
# CPM Session State

**Skill**: cpm:consult
**Phase**: Consultation in progress
**Topic**: {the consultation topic}
**Active agents**: {ordered comma-separated list of active agent display names}
**Lead**: {user or agent display name}

## Discussion Highlights

### Key points so far
- {Major point or insight from the consultation}
- {Another key point}

### Active thread
{Brief description of the current line of discussion — what was just being talked about, who was leading, what the user's last question or statement was about}

## Next Action
Continue the consultation. The user's last message was about {brief description}. Lead is {user/agent name}. Active agents: {list}. Resume the conversation loop.
```

The "Discussion Highlights" section is the critical part — it captures enough of the conversation's substance that post-compaction continuation feels seamless. The `Active agents` and `Lead` fields are essential for restoring the correct conversation dynamics after compaction.

## Library Check

After roster loading and before the first conversation turn, check the project library for reference documents:

1. **Glob** `docs/library/*.md`. If no files found or directory doesn't exist, skip silently.
2. **Read front-matter** of each file found (the YAML block between `---` delimiters, typically the first ~10 lines). Filter to documents whose `scope` array includes `party` or `all`.
3. **Report to user**: "Found {N} library documents relevant to this consultation: {titles}. Agents can reference these." If none match the scope filter, skip silently.
4. **Deep-read selectively** during the conversation loop when an agent's response would benefit from referencing library content — e.g. an architect referencing architecture docs, or a developer citing coding standards.

**Graceful degradation**: If any library document has malformed or missing front-matter, fall back to using the filename as context. Never block the consultation due to a malformed library document.

**Compaction resilience**: Include library scan results (files found, scope matches) in the progress file so post-compaction continuation doesn't re-scan.

## Guidelines

- **The user leads by default.** Agents serve the user's thinking, not the other way around. The user controls who's in the room and who's driving.
- **Depth over breadth.** Consult mode exists for focused exploration. One sharp, deep perspective is better than three surface-level ones.
- **Natural disagreement.** When multiple agents are active and have different perspectives, let them disagree constructively. This tension surfaces trade-offs.
- **Match depth to topic.** A quick question gets a quick response. A complex architectural decision gets deeper analysis and follow-up questions.
- **Respect the lead.** When an agent is leading, let them drive. When the user reclaims the lead, defer immediately. Don't fight for control.
- **Commands over conversation.** When the user's intent is clearly a command (invite, dismiss, handover), execute it. When it's ambiguous, treat it as conversation.
