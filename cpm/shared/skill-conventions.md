# CPM Shared Skill Conventions

Common procedures used by multiple CPM skills. This document is loaded into context at session start so that skills can reference these conventions without duplicating them.

Skills that reference this document will say "Follow the shared [Convention Name] procedure" — when you see that, use the matching section below.

## Roster Loading

Load the agent roster so that Perspectives and other agent-driven features use real names, roles, and personalities from the roster — never invented ones.

1. **Project override**: Read `docs/agents/roster.yaml` in the current project directory. If it exists, use it as the complete roster (no merging with defaults).
2. **Plugin default**: If no project override exists, read the plugin's `agents/roster.yaml` (located at `../../agents/roster.yaml` relative to the active skill's SKILL.md file).
3. If neither file can be found, skip agent features and continue the skill normally.

After loading, store the roster in memory for the session. Do not re-load between sections/phases unless compaction has fired.

## Perspectives

Some skill sections include a **Perspectives** block where agent personas briefly weigh in before the user makes a decision. To use perspectives:

1. **Ensure the roster is loaded** — follow the Roster Loading procedure above if not already done.
2. **Select 2-3 agents** whose expertise is relevant to the current section and topic. Use the `role` and `personality` fields from the roster to pick agents who would have a meaningful perspective.
3. **Each agent provides a brief perspective** (1-2 sentences) in character, using the format: `{icon} **{displayName}**: {perspective}`. Use the agent's actual `icon`, `displayName`, `personality`, and `communicationStyle` from the roster — never invent names, icons, or roles.
4. **Perspectives should add value** — surface trade-offs, challenge assumptions, or highlight concerns. If a perspective would just echo what's already been said, skip it.
5. **Present perspectives naturally**, woven into the facilitation before the user makes a decision — not as a separate section.

If the roster cannot be loaded, skip perspectives and continue the facilitation normally.

## Library Check

Check the project library for reference documents relevant to the current skill. Each skill specifies its own scope keyword (e.g., `spec`, `brief`, `architect`, `discover`).

1. **Glob** `docs/library/*.md`. If no files found or directory doesn't exist, skip silently.
2. **Read front-matter** of each file found (the YAML block between `---` delimiters, typically the first ~10 lines). Filter to documents whose `scope` array includes the current skill's scope keyword or `all`.
3. **Report to user**: "Found {N} library documents relevant to this session: {titles}. I'll reference these as context." If none match the scope filter, skip silently.
4. **Deep-read selectively** during the skill's phases/sections when a library document's content is relevant.

**Graceful degradation**: If any library document has malformed or missing front-matter, fall back to using the filename as context. Never block the skill's process due to a malformed library document.

**Compaction resilience**: Include library scan results (files found, scope matches) in the progress file so post-compaction continuation doesn't re-scan.
