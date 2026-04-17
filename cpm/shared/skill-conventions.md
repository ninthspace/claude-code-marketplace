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
2. **Read front-matter** of each file found using the Read tool (the YAML block between `---` delimiters, typically the first ~10 lines). Read each file individually — do not use Bash loops with shell variables for this. Filter to documents whose `scope` array includes the current skill's scope keyword or `all`.
3. **Report to user**: "Found {N} library documents relevant to this session: {titles}. I'll reference these as context." If none match the scope filter, skip silently.
4. **Deep-read selectively** during the skill's phases/sections when a library document's content is relevant.

**Graceful degradation**: If any library document has malformed or missing front-matter, fall back to using the filename as context. Never block the skill's process due to a malformed library document.

**Compaction resilience**: Include library scan results (files found, scope matches) in the progress file so post-compaction continuation doesn't re-scan.

## Numbering

Assign the next numeric prefix when a skill creates a new numbered artifact (`docs/specifications/`, `docs/epics/`, `docs/plans/`, `docs/briefs/`, `docs/reviews/`, `docs/retros/`, `docs/architecture/`, `docs/quick/`, `docs/discussions/`, etc.). The same rule applies to every artifact type — skills reference this procedure rather than restating the logic inline.

> **Invariant**: Numeric prefix is an integer identifier, not a fixed-width string. Never pad existing files to match new widths.

### Procedure

For a given artifact type with directory `docs/{type}/` and filename pattern `{nn}-{type}-{slug}.md`:

1. **Glob the active directory**: `docs/{type}/[0-9]*-{type}-*.md`.
2. **Glob the archive mirror**: `docs/archive/{type}/[0-9]*-{type}-*.md`. If the archive directory does not exist (fresh project, nothing ever archived), treat this set as empty and continue — the lookup degrades cleanly to active-only.
3. **Extract the leading numeric prefix** from each matched filename. Parse it as an **integer**, not a string. Lexical comparison is forbidden: `"100"` must compare as greater than `"99"`, which only works under integer comparison.
4. **Take the union** of the two sets and compute `max + 1`. If both sets are empty, start at `1`.
5. **Format the new number** with a **minimum of 2 digits**, zero-padded. Numbers `< 100` render as `01`, `02`, …, `99`. Numbers `≥ 100` use their natural width: `100`, `101`, and so on. Do not pad beyond 2 digits; do not truncate or reformat existing files.

### Rules

- **Numbers are retired on archive, never reused.** Because the glob unions active and archived directories, a number that has ever been assigned remains reserved even after its artifact is moved to `docs/archive/`. New artifacts always receive `max(active ∪ archived) + 1`.
- **Integer comparison, not lexical.** Any implementation detail that sorts or compares filenames by string ordering will break the moment a directory crosses `99 → 100`. Parse the prefix as an integer before comparing.
- **No bulk renaming.** Existing 2-digit files are never re-padded to 3 digits when a directory crosses `99 → 100`. The new file is written at its natural width (`100-…`) next to the existing 2-digit files. Mixed-width coexistence is a permanent invariant the glob handles natively via integer comparison.
- **No auto-widening migration.** There is no "renumber on save of #100" operation. Growth past 99 is transparent to the user.
- **Archive must preserve the mirrored directory structure** (`docs/archive/{type}/`) for the archive-side glob to find retired numbers. This is a load-bearing contract with `cpm:archive`.

### Scenarios

- **Fresh project, nothing in active or archive**: next number is `1`, rendered as `01`.
- **Active contains `01-…` through `27-…`, archive empty**: next number is `28`, rendered as `28`.
- **Active empty, archive contains `27-…`**: next number is `28` (never `01`). The retired number stays retired.
- **Active contains `99-…`, archive empty**: next number is `100`, rendered as `100` (no padding beyond 2 digits, no renaming of `99-…`).
- **Active contains `99-…` and `100-…`, archive contains `50-…`**: next number is `101`. Integer comparison correctly yields `max(99, 100, 50) + 1 = 101`.
- **Archive directory does not exist** (fresh project): the archive-side glob returns empty and the lookup continues using only the active directory.

## Implementation Guidelines

Cross-cutting rules for all CPM skills that edit files during execution (do, quick, review autofix, pivot cascade, etc.). Skills that reference this document inherit these guidelines automatically.

### No bulk programmatic edits

Never use `sed`, `perl`, `awk`, or other stream-processing tools via the Bash tool to edit files. Always use the **Edit tool**, applied file-by-file, so that each change is visible, reviewable, and reversible.

- **Why**: Bulk programmatic edits are opaque — they bypass the tool's diffing and review affordances, risk corrupting files on partial matches, and make it impossible to audit what changed after the fact. The Edit tool produces a clear before/after for every change.
- **Scope**: This applies to *editing existing files*. Using Bash for read-only operations (`grep`, `find`, `git`) or running build/test commands is unaffected. Writing *new* files with the Write tool is also fine — the constraint is about modifying existing content.

### Clarity and correctness over speed

Prefer clarity and correctness over speed in all implementation work. Getting it right matters more than getting it done fast.

- **Why**: Momentum-driven shortcuts — skipping verification, batching unrelated changes, or rushing through edits — create subtle bugs and rework. A correct implementation delivered methodically is faster end-to-end than a quick implementation that needs debugging.
- **How this interacts with skill-level guidelines**: Individual skills may emphasise efficiency or momentum (e.g. "keep momentum", "fast by default"). Those guidelines mean *don't add unnecessary ceremony* — they do not mean *sacrifice correctness for speed*. When the two are in tension, correctness wins.
