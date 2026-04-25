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

## Retro Awareness

Some skills check for recent retrospectives at startup so they can incorporate lessons from past work into the current session. To use:

1. **Glob** `docs/retros/[0-9]*-retro-*.md`. If no files found or directory doesn't exist, skip silently — never block the skill.
2. Read the most recent retro file (highest numeric prefix).
3. Present a brief summary of its observations and recommendations to the user, focusing on the categories the running skill cares about (see the skill's own **Retro incorporation** block).
4. Use AskUserQuestion: "A recent retro has observations relevant to this skill. Incorporate?" with options `Yes, incorporate` / `No, skip`.
5. If yes: apply the skill's incorporation guidance to active context throughout the session — not as a prompt one-off, but as a lens applied to each phase/section/step.

**Per-skill incorporation**: Each skill that uses Retro Awareness includes its own **Retro incorporation** block listing:
- Which of the seven retro observation categories matter most to this skill (smooth deliveries, scope surprises, criteria gaps, complexity underestimates, codebase discoveries, testing gaps, patterns worth reusing).
- What concrete actions to take when those categories surface — not vague "use as context," but specific operations the skill performs differently.

Without per-skill guidance, "incorporate" defaults to vague awareness and the retro effectively goes unused. Skills must say what changes.

**Graceful degradation**: If no retro files exist, skip silently. If front-matter or content is malformed, fall back to filename context. Never block on retro check failures — the retro is advisory input, not a gate.

## Progress File Management

CPM skills that maintain a progress file at `docs/plans/.cpm-progress-{session_id}.md` follow this procedure for compaction resilience. Skills define their own *lifecycle triggers* (when to create/update/delete) and *format* (which fields go in the file); everything else below is shared.

**Why this matters**: The progress file is the only recovery point if context compaction fires mid-flow. A stale or missing file means the user loses session state with no recovery — treat the Write call with the same care as saving user code.

**Path resolution**: All paths in skills are relative to the current Claude Code session's working directory. When calling Write, Read, or any file tool, construct the absolute path by prepending the session's primary working directory. Always write to the current session's working directory only — cross-project or cross-session writes corrupt state.

**Session ID**: The `{session_id}` in the filename comes from `CPM_SESSION_ID` — a unique identifier for the current Claude Code session, injected into context by the CPM hooks on startup and after compaction. Use this value verbatim when constructing the progress file path. If `CPM_SESSION_ID` is not present in context (e.g. hooks not installed), fall back to `.cpm-progress.md` (no session suffix) for backwards compatibility.

**Resume adoption**: When a session is resumed (`--resume`) or context is cleared (`/clear`), `CPM_SESSION_ID` changes to a new value while the old progress file remains on disk. The hooks inject all existing progress files into context — if one matches the running skill's `**Skill**:` field but has a different session ID in its filename, adopt it:
1. Read the old file's contents (already visible in context from hook injection).
2. Write a new file at `docs/plans/.cpm-progress-{current_session_id}.md` with the same contents.
3. After the Write confirms success, delete the old file: `rm docs/plans/.cpm-progress-{old_session_id}.md`.

Adoption requires `CPM_SESSION_ID` in context. When absent, the fallback path (unsuffixed filename) handles that case.

**Companion compact summary**: When deleting the progress file, also delete `docs/plans/.cpm-compact-summary-{session_id}.md` if it exists — this companion file is written by the PostCompact hook and should be cleaned up alongside the progress file.

**Write semantics**: Use the Write tool to write the full file each time (not Edit — the file is replaced wholesale on every update).

**Late deletion**: Always delete the progress file *after* output artifacts are confirmed written, never before. If compaction fires between an early deletion and a pending output, all session state is lost.

**Per-skill responsibility**: Each skill's `## State Management` section specifies its own:
- **Lifecycle**: when to create, update, and delete (using the skill's natural unit of progress: phase, section, step, task, turn, etc.).
- **Format**: the markdown skeleton listing the fields specific to this skill, plus any per-skill notes about what those fields should capture.

Skills reference this procedure with: "Follow the shared **Progress File Management** procedure." followed by their **Lifecycle** and **Format** blocks.

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
- **Archive must preserve the mirrored directory structure** (`docs/archive/{type}/`) for the archive-side glob to find retired numbers. This is a load-bearing contract with `cpm2:archive`.

### Scenarios

- **Fresh project, nothing in active or archive**: next number is `1`, rendered as `01`.
- **Active contains `01-…` through `27-…`, archive empty**: next number is `28`, rendered as `28`.
- **Active empty, archive contains `27-…`**: next number is `28` (never `01`). The retired number stays retired.
- **Active contains `99-…`, archive empty**: next number is `100`, rendered as `100` (no padding beyond 2 digits, no renaming of `99-…`).
- **Active contains `99-…` and `100-…`, archive contains `50-…`**: next number is `101`. Integer comparison correctly yields `max(99, 100, 50) + 1 = 101`.
- **Archive directory does not exist** (fresh project): the archive-side glob returns empty and the lookup continues using only the active directory.

## Change Type Decision

When a change to existing planning artefacts is needed — discovered mid-execution, raised during review, or surfaced as a separate intent — three response patterns exist. Use this decision matrix to pick one.

| Situation | Action | Mechanism |
|---|---|---|
| Wording fix, typo, single-criterion clarification — **no scope change** | Inline edit (with breadcrumb) | Edit the criterion in place, record an `**Inline change**:` field |
| Scope change, integration boundary, missing requirement that affects ≥2 stories or any downstream document | Pivot the upstream artefact | `/cpm2:pivot {path}` |
| Pattern noticed, codebase discovery, complexity insight — **no scope change** | Retro observation only | `**Retro**:` field on the current story (per `cpm2:do` Step 6 Part B) |
| Both scope change **and** lesson | Pivot now, retro at end | `/cpm2:pivot` + `**Retro**:` field at story completion |

**When in doubt, choose pivot.** Inline edits are silent — they leave no trail and bypass the cascade. The cost of an unnecessary pivot is small (the user can skip downstream changes); the cost of silent spec→reality drift is high.

**Inline edit breadcrumb**: When applying an inline edit to a story or task, record an `**Inline change**: {one-line summary} ({YYYY-MM-DD})` field on the story (alongside any existing `**Retro**:` field). This preserves a trail that downstream skills (drift detection, retro synthesis) can see.

**Skill responsibility**: Skills that may surface change moments during execution (`cpm2:do`, `cpm2:quick`) reference this convention when a change-worthy situation appears. The decision is presented as a structured `AskUserQuestion` gate (per the **Gate Presentation** convention) with the four options above as labels — never as a freeform "should we change this?" prompt.

## Tool Operations

Skills use `Glob` and `Grep` (and similar names) as **semantic operations**, not specific tool calls. The names describe *what to do*, not *which tool to invoke*:

- **`Glob`** means "find files matching a pattern."
- **`Grep`** means "search file contents for a pattern."
- **`Read`**, **`Edit`**, **`Write`** retain their literal tool meanings.

Use whichever tool the current harness actually provides for each operation. Realistic options across environments include:

- Built-in `Glob` / `Grep` tools (older harness versions).
- `bfs` / `ugrep` (newer macOS/Linux defaults).
- `fff` MCP server tools (`find_files`, `grep`, `multi_grep`) when configured.
- `Bash` with `find`, `grep`, `rg`, or equivalents.

**Precedence**: Project `CLAUDE.md` tool preferences win over anything implied by these operation names. If a project says "prefer fff" or "use ripgrep," follow that — the skill's vocabulary is general; the project's stack is specific.

**Compatibility note**: Skill text written before this convention may read as if `Glob` and `Grep` are literal tool names. Treat all such references as semantic operations. No skill file rewrites are required.

## Gate Presentation

`AskUserQuestion` is for the *gate*, never the *content*. The Claude Code preview panel that renders the question is sized for short prompts and short option labels — long content gets truncated and becomes unreadable.

**Rule**: Documents, drafts, alternatives, ADRs, specs, briefs, planning options, lists of proposed changes — render in the assistant's message body **before** the `AskUserQuestion` call. The `AskUserQuestion` itself carries only the decision: "Approve", "Request changes", "Stop", "Choose A / B / C", etc. Question text and option labels stay short enough to fit the preview panel comfortably.

**Good**:

> *(draft, ADR, spec section, etc. rendered in the message body above)*
>
> `AskUserQuestion`: "Approve this draft?" — options: `Approve` / `Request changes` / `Stop`

**Bad**:

> `AskUserQuestion`: "Here is the draft: [200 lines pasted into question text]. Approve?"

When in doubt: if the content the user needs to read is more than a sentence or two, it belongs in the message body, not in the question.

## Effort Recommendations

Map each CPM skill to a reasoning effort level. Skills that reference this document inherit the recommended level automatically.

| Skill | Level | Rationale |
|-------|-------|-----------|
| do | xhigh | Multi-step execution loop with verification, TDD, and state management |
| epics | xhigh | Spec analysis, story decomposition, coverage matrix construction |
| spec | xhigh | Facilitated requirements gathering across 7 sections with architecture decisions |
| architect | xhigh | Multi-phase architecture exploration with trade-off analysis |
| ralph | xhigh | Autonomous multi-epic execution with failure handling and task budgets |
| consult | xhigh | Deep one-to-one consultation with dynamic expert transfer |
| party | xhigh | Multi-perspective discussion with roster-driven agent simulation |
| review | xhigh | Adversarial analysis with multi-agent review perspectives |
| brief | xhigh | Facilitated product ideation with vision and value proposition synthesis |
| discover | xhigh | Facilitated problem discovery across 6 phases with perspectives |
| pivot | high | Surgical amendment with cascade analysis and downstream propagation |
| quick | high | Scoped implementation with verification, but bypasses full pipeline ceremony |
| library | medium | Document intake and front-matter generation; consolidation is bounded |
| archive | medium | File relocation with user confirmation |
| retro | medium | Observation synthesis from structured epic doc fields |
| present | medium | Artifact transformation with audience selection |
| status | medium | Scan and report with no implementation |
| templates | medium | List and scaffold with no analysis |

## Subagent Delegation

When to use subagents (the Agent tool) vs. working inline. Subagents are valuable for parallelising independent work and protecting the main context window from excessive results — but they add overhead and lose conversational context.

### Delegate (fan-out) when

- **Reading multiple independent files**: e.g. reading 5+ library documents, scanning multiple epic docs, or auditing files across directories. Each read is independent — fan out to avoid bloating the main context.
- **Per-item work across a list**: e.g. processing each epic independently in a production loop, or reviewing each story in isolation. The items share no state — parallelise them.
- **Exploratory research**: e.g. searching the codebase for patterns, finding all usages of a function, or surveying project structure. The search results inform a decision but are not themselves the deliverable.

### Work inline when

- **The result drives the next step**: e.g. reading a file to decide what to edit next, or checking a test result before proceeding. Sequential dependencies require inline execution.
- **The code is already in context**: e.g. you just read the file, or the user pasted it. Delegating would re-read what you already have.
- **User interaction is needed**: e.g. AskUserQuestion gates, facilitation loops, or confirmation steps. Subagents cannot interact with the user.
- **The work is a single focused operation**: e.g. one edit, one test run, one file creation. The overhead of spawning outweighs the benefit.

### Rules

- Subagents start with no context from the current conversation — the prompt must be self-contained.
- Assign subagents to research and exploration, not to implementation decisions that require conversational context.
- When delegating, specify whether the subagent should write code or just research. The subagent cannot infer intent from the conversation.

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
