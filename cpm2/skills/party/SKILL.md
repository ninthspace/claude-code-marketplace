---
name: cpm2:party
description: Multi-perspective discussion with named agent personas. Bring your whole team into one conversation — PM, Architect, Developer, UX Designer, Test Engineer, and more. Use for brainstorming, decision-making, or exploring trade-offs from diverse viewpoints. Triggers on "/cpm2:party".
---

# Party Mode

Launch a multi-persona discussion where specialist agents respond in character, build on each other's ideas, and constructively disagree — surfacing richer analysis than a single perspective.

## Input

If `$ARGUMENTS` is provided, use it as the starting topic/context:

- If it's a **file path**, read the file and use its contents as context for the discussion.
- If it's a **URL**, fetch the URL and use the content as context.
- If it's a **description**, use it directly as the topic.

If no arguments are given, ask the user what they'd like to discuss.

## Roster Loading

Follow the shared **Roster Loading** procedure. After loading, introduce the available agents as a compact roster listing each agent's icon, name, and role. Adapt the display to whatever agents are actually loaded. End with: "What would you like to discuss? (Or address any agent by name.)"

## Library Check

Follow the shared **Library Check** procedure with scope keyword `party`. Deep-read selectively during the orchestration loop when agent personas cite documented constraints or prior decisions.

## Orchestration Loop

This is the core conversation loop. For each user message:

### 1. Analyse the Topic

Consider three dimensions:
- **Domain expertise needed** — Which agents have relevant knowledge?
- **Complexity** — Does this need 2 or 3 perspectives?
- **Conversation context** — What's been discussed so far? Who hasn't spoken recently?

### 2. Select Agents

Pick **2-3 agents** to respond:

- **Primary agent**: Best domain expertise match for the current topic.
- **Secondary agent**: Complementary or contrasting viewpoint.
- **Tertiary agent** (optional): Only include a third when the topic genuinely benefits from an additional perspective. Let the topic earn the third voice.

**Named agent priority**: If the user addresses an agent by name (e.g. "Margot, what do you think?"), that agent **must** respond, plus 1-2 complementary agents.

**Rotation awareness**: Track which agents have participated recently. If an agent hasn't spoken in several turns and their expertise is even tangentially relevant, favour including them. Rotate so every agent gets airtime over multiple turns.

### 3. Generate Responses

Each agent responds in character. Format:

```
{icon} **{displayName}**: {response in character}
```

Rules for agent responses:
- **Stay in character.** Each agent's personality and communication style (from the roster) should be evident in how they express themselves.
- **Reference each other.** Agents should build on, agree with, challenge, or extend what other agents have said — both in the current turn and from earlier in the conversation. Use natural references: "Building on what Kai said...", "I see Margot's point, but...", "That's exactly the risk Tomasz was flagging earlier..."
- **Disagree constructively.** When agents have legitimately different perspectives, they should express them. An architect and developer will sometimes disagree on abstraction levels. A PM and UX designer may have different views on feature priority. This tension is the point — preserve it.
- **Be opinionated.** Every agent should state what they would recommend, not just observe or analyse. "I'd suggest...", "My recommendation would be...", "If it were my call..." — agents have expertise and should use it to propose concrete actions, approaches, or decisions. Analysis without a recommendation is incomplete.
- **Stay concise.** Each agent's response should be focused — a few sentences to a short paragraph. Not walls of text. The value is in the diversity of perspectives, not the volume.
- **Research before asking.** When a question is about code, implementation details, or anything discoverable in the codebase — use Read, Grep, and Glob to find the answer yourself. Agents should investigate the code and form an informed view *before* responding, not ask the user to look things up for them. Reserve questions for the user's **intent, preferences, priorities, and decisions** — things only the user can answer.

### 4. Direction of Travel

After the agent responses, read the room. The discussion will be in one of three phases — signal which one with a short line after the agent responses:

**Exploring** — The conversation is still opening up: gathering context, asking questions, surfacing considerations. No signal needed. Just let the conversation flow.

**Converging** — Themes are emerging. Agents are starting to align on certain points, or a clear tension between two approaches is crystallising. Signal this lightly:

```
🧭 **Emerging direction**: {1-2 sentences describing what the team is gravitating towards, or the key fork in the road}
```

**Ready to recommend** — The discussion has landed. Agents are in broad agreement, or the trade-offs between options are fully explored and the team has a clear preference. Now surface the recommendation:

```
💡 **The team recommends**: {1-2 sentence consensus recommendation}
```

If the team is split but the options are well-defined:

```
💡 **Two paths forward**:
1. {Option A — who backs it and why}
2. {Option B — who backs it and why}
```

**Judging the phase**: Let convergence emerge naturally. Most discussions need several rounds of exploring before themes emerge. The shift from exploring to converging should feel earned — driven by what the agents have actually said, not by a desire to wrap up. A discussion can also move backwards (e.g. a new consideration reopens a settled question). Match the signal to the reality of the conversation, not to a linear progression.

### 5. Present Exit Option

After each round of agent responses, present a subtle exit option:

```
---
*Type **wrap up** to end the discussion, or continue the conversation.*
```

**Important**: Use "wrap up" as the primary trigger — "exit" and "quit" are reserved by the Claude Code CLI and will terminate the session entirely, orphaning the progress file.

## Exit Handling

The user can end party mode at any time by typing "wrap up", "done", "end discussion", or "goodbye".

When an exit is triggered, follow this sequence:

### 1. Acknowledge

Briefly acknowledge the end of the discussion. Keep it natural — one sentence, not a ceremony.

### 2. Save Discussion Record

Save the progress file's content as a permanent discussion artifact. This preserves the full fidelity of decisions, key points, and context accumulated during the conversation — no summarisation, no information loss.

1. **Read the current progress file** (`docs/plans/.cpm-progress-{session_id}.md`).
2. **Determine the output path**: Save to `docs/discussions/{nn}-discussion-{slug}.md`.
   - `{nn}` is assigned by the shared **Numbering** procedure (from the CPM Shared Skill Conventions loaded at session start).
   - `{slug}` is a short kebab-case name derived from the discussion topic.
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

**Preserve verbatim.** The progress file already contains curated, structured content — decisions with numbered objectives, key points, rationale. Summarising loses this detail. The discussion record is the artifact.

### 3. Pipeline Handoff

After saving the discussion record, offer the user options for what to do next. Use AskUserQuestion:

- **Continue to /cpm2:discover** — Use the discussion record as starting context for problem discovery
- **Continue to /cpm2:spec** — Use the discussion record as starting context for requirements specification
- **Continue to /cpm2:epics** — Use the discussion record as starting context for work breakdown
- **Done for now** — End the session, no handoff

If the user chooses a pipeline skill, pass the discussion record file path as the input context for that skill. The file path becomes the `$ARGUMENTS` equivalent — the next skill should read the file and treat it as its starting brief/description.

## State Management

Follow the shared **Progress File Management** procedure.

**Lifecycle**:
- **Create**: after roster loading and topic confirmation (before the first orchestration turn).
- **Update**: after every 2-3 substantive exchanges (not every single turn — use judgement).
- **Delete**: only after the discussion record has been saved to `docs/discussions/` and any pipeline handoff is complete.

**Format**:

```markdown
# CPM Session State

**Skill**: cpm2:party
**Phase**: Discussion in progress
**Topic**: {the discussion topic}
**Agents loaded**: {comma-separated list of agent display names}

## Discussion Highlights

### Key points so far
- {Major point or insight from the discussion}
- {Another key point}

### Active thread
{Brief description of the current line of discussion — what was just being talked about, which agents were involved, what the user's last question or statement was about}

### Agents who have participated recently
{List of agents who spoke in the last few turns, so rotation awareness can continue}

## Next Action
Continue the party mode discussion. The user's last message was about {brief description}. Resume the orchestration loop.
```

The "Discussion Highlights" section is the critical part — it captures enough of the conversation's substance that post-compaction continuation feels seamless. Focus on key insights, decisions, and the current thread — breadth of substance over completeness.

## Arguments

If `$ARGUMENTS` provides a topic, skip the "what would you like to discuss?" question and go straight into the first orchestrated response round using the provided topic as context.

## Guidelines

- **Facilitate first.** The agents serve the user's thinking, not the other way around. If the user wants to steer the conversation, let them.
- **Quality over quantity.** Two sharp, distinct perspectives are better than three that all say roughly the same thing.
- **Natural disagreement.** Let genuine conflict surface organically and let it stand. Real teams disagree — that's where good decisions come from.
- **Match depth to topic.** A quick question gets quick responses. A complex architectural decision gets deeper analysis.
- **Keep it moving.** If the conversation is going in circles, have Ren (Scrum Master) notice and suggest a decision or direction change.
- **Respect the user's focus.** If the user is clearly interested in one agent's perspective, let that agent take the lead for a few turns. Others can chime in when they have something genuinely additive.
