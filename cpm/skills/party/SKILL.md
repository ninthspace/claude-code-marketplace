---
name: cpm:party
description: Multi-perspective discussion with named agent personas. Bring your whole team into one conversation — PM, Architect, Developer, UX Designer, and more. Use for brainstorming, decision-making, or exploring trade-offs from diverse viewpoints. Triggers on "/cpm:party".
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

Load the agent roster at session start. Check for a project-level override first:

1. **Project override**: Read `docs/agents/roster.yaml` in the current project directory. If it exists, use it as the complete roster (no merging with defaults).
2. **Plugin default**: If no project override exists, read the plugin's `agents/roster.yaml` (located in the same plugin directory as this skill, at `../../agents/roster.yaml` relative to this file).

If neither file can be found, tell the user and stop — party mode requires a roster.

After loading, briefly introduce the available agents. Present them as a compact roster:

```
Your team for this session:

📋 **Jordan** — Product Manager
🏗️ **Margot** — Software Architect
💻 **Kai** — Senior Developer
🎨 **Priya** — UX Designer
🔍 **Tomasz** — QA Engineer
🚀 **Sable** — DevOps Engineer
📝 **Ellis** — Technical Writer
🔄 **Ren** — Scrum Master

What would you like to discuss? (Or address any agent by name.)
```

Adapt the roster display to whatever agents are actually loaded.

## Library Check

After roster loading and before the first orchestration round, check the project library for reference documents:

1. **Glob** `docs/library/*.md`. If no files found or directory doesn't exist, skip silently.
2. **Read front-matter** of each file found (the YAML block between `---` delimiters, typically the first ~10 lines). Filter to documents whose `scope` array includes `party` or `all`.
3. **Report to user**: "Found {N} library documents relevant to this discussion: {titles}. Agents can reference these." If none match the scope filter, skip silently.
4. **Deep-read selectively** during the orchestration loop when an agent's response would benefit from referencing library content — e.g. an architect referencing architecture docs, or a developer citing coding standards.

**Graceful degradation**: If any library document has malformed or missing front-matter, fall back to using the filename as context. Never block the discussion due to a malformed library document.

**Compaction resilience**: Include library scan results (files found, scope matches) in the progress file so post-compaction continuation doesn't re-scan.

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
- **Tertiary agent** (optional): Only include a third when the topic genuinely benefits from an additional perspective. Don't force it.

**Named agent priority**: If the user addresses an agent by name (e.g. "Margot, what do you think?"), that agent **must** respond, plus 1-2 complementary agents.

**Rotation awareness**: Track which agents have participated recently. If an agent hasn't spoken in several turns and their expertise is even tangentially relevant, favour including them. Don't let the same 2-3 agents dominate every turn.

### 3. Generate Responses

Each agent responds in character. Format:

```
{icon} **{displayName}**: {response in character}
```

Rules for agent responses:
- **Stay in character.** Each agent's personality and communication style (from the roster) should be evident in how they express themselves.
- **Reference each other.** Agents should build on, agree with, challenge, or extend what other agents have said — both in the current turn and from earlier in the conversation. Use natural references: "Building on what Kai said...", "I see Margot's point, but...", "That's exactly the risk Tomasz was flagging earlier..."
- **Disagree constructively.** When agents have legitimately different perspectives, they should express them. An architect and developer will sometimes disagree on abstraction levels. A PM and UX designer may have different views on feature priority. This tension is the point — don't smooth it over.
- **Stay concise.** Each agent's response should be focused — a few sentences to a short paragraph. Not walls of text. The value is in the diversity of perspectives, not the volume.
- **Ask the user questions.** Agents can and should ask the user for clarification or input. When an agent asks a direct question, that naturally becomes the prompt for the user's next message.

### 4. Present Exit Option

After each round of agent responses, present a subtle exit option:

```
---
*Type **exit** to end the discussion, or continue the conversation.*
```

## Exit Handling

The user can exit party mode at any time by typing "exit", "done", "end", "quit", or "goodbye".

When an exit is triggered, follow this sequence:

### 1. Acknowledge

Briefly acknowledge the end of the discussion. Keep it natural — one sentence, not a ceremony.

### 2. Discussion Summary

Produce a structured summary of the conversation:

```markdown
## Discussion Summary

**Topic**: {the original topic or question}

### Key Points
- {Major insight or conclusion from the discussion}
- {Another key point}

### Agreements
- {Points where agents converged or the user confirmed a direction}

### Open Questions
- {Unresolved disagreements or topics that need more thought}

### Recommendations
- {Actionable next steps suggested by agents during the discussion}
```

Rules for the summary:
- **Be selective.** Capture the substance, not a transcript. 3-5 bullet points per section is typical.
- **Attribute where useful.** If a key insight came from a specific agent, mention them: "Margot recommended separating the read and write paths."
- **Skip empty sections.** If there are no open questions, don't include that heading.
- **Make it reusable.** This summary may be passed as input to discover/spec/stories via the pipeline handoff. Write it so it stands on its own without the full conversation context.

### 3. Pipeline Handoff

After presenting the summary, offer the user options for what to do next. Use AskUserQuestion:

- **Continue to /cpm:discover** — Use the summary as starting context for problem discovery
- **Continue to /cpm:spec** — Use the summary as starting context for requirements specification
- **Continue to /cpm:stories** — Use the summary as starting context for work breakdown
- **Just exit** — End the session, no handoff

If the user chooses a pipeline skill, pass the discussion summary as the input context for that skill. The summary becomes the `$ARGUMENTS` equivalent — the next skill should treat it as its starting brief/description.

## State Management

Maintain `docs/plans/.cpm-progress.md` throughout the session for compaction resilience. This allows seamless continuation if context compaction fires mid-discussion.

**Create** the file after roster loading and topic confirmation (before the first orchestration turn). **Update** it after every 2-3 substantive exchanges (not every single turn — use judgement). **Delete** it after a clean exit.

Use the Write tool to write the full file each time (not Edit — the file is replaced wholesale). Format:

```markdown
# CPM Session State

**Skill**: cpm:party
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

The "Discussion Highlights" section is the critical part — it captures enough of the conversation's substance that post-compaction continuation feels seamless. Don't try to capture everything; focus on key insights, decisions, and the current thread.

## Arguments

If `$ARGUMENTS` provides a topic, skip the "what would you like to discuss?" question and go straight into the first orchestrated response round using the provided topic as context.

## Guidelines

- **Facilitate, don't dominate.** The agents serve the user's thinking, not the other way around. If the user wants to steer the conversation, let them.
- **Quality over quantity.** Two sharp, distinct perspectives are better than three that all say roughly the same thing.
- **Natural disagreement.** Don't manufacture conflict, but don't suppress it either. Real teams disagree — that's where good decisions come from.
- **Match depth to topic.** A quick question gets quick responses. A complex architectural decision gets deeper analysis.
- **Keep it moving.** If the conversation is going in circles, have Ren (Scrum Master) notice and suggest a decision or direction change.
- **Respect the user's focus.** If the user is clearly interested in one agent's perspective, let that agent take the lead for a few turns. Others can chime in when they have something genuinely additive.
