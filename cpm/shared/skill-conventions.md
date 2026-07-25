# CPM Shared Skill Conventions

Common procedures used by multiple CPM skills. This document is loaded into context at session start so that skills can reference these conventions without duplicating them.

Skills that reference this document will say "Follow the shared [Convention Name] procedure" — when you see that, use the matching section below.

## Roster Loading

Load the agent roster so that Perspectives and other agent-driven features use real names, roles, and personalities from the roster rather than invented ones.

1. **Project override**: Read `docs/agents/roster.yaml` in the current project directory. If it exists, use it as the complete roster (no merging with defaults).
2. **Plugin default**: If no project override exists, read the plugin's `agents/roster.yaml` (located at `../../agents/roster.yaml` relative to the active skill's SKILL.md file).
3. If neither file can be found, skip agent features and continue the skill normally.

After loading, store the roster in memory for the session. Do not re-load between sections/phases unless compaction has fired.

## Perspectives

Some skill sections include a **Perspectives** block where agent personas briefly weigh in before the user makes a decision. To use perspectives:

1. **Confirm the roster is loaded** — follow the Roster Loading procedure above if not already done.
2. **Select 2-3 agents** whose expertise is relevant to the current section and topic. Use the `role` and `personality` fields from the roster to pick agents who would have a meaningful perspective.
3. **Each agent provides a brief perspective** (1-2 sentences) in character, using the format: `{icon} **{displayName}**: {perspective}`. Use the agent's actual `icon`, `displayName`, `personality`, and `communicationStyle` from the roster. Actively render each agent's voice from their roster `communicationStyle` and `personality` fields — let those traits drive word choice, tone, and framing so each persona stays distinct rather than collapsing into one flat voice. Draw only on the names, icons, roles, and traits the roster defines, inventing nothing beyond it.
4. **Perspectives should add value** — surface trade-offs, challenge assumptions, or highlight concerns. If a perspective would just echo what's already been said, skip it.
5. **Present perspectives naturally**, woven into the facilitation before the user makes a decision — not as a separate section.

If the roster cannot be loaded, skip perspectives and continue the facilitation normally.

## Library Check

Check the project library for reference documents relevant to the current skill. Each skill specifies its own scope keyword (e.g., `spec`, `brief`, `architect`, `discover`).

1. **Glob** `docs/library/*.md`. If no files found or directory doesn't exist, skip silently.
2. **Read front-matter** of each file found using the Read tool (the YAML block between `---` delimiters, typically the first ~10 lines). Read each file individually — do not use Bash loops with shell variables for this. Filter to documents whose `scope` array includes the current skill's scope keyword or `all`.
3. **Report to user**: "Found {N} library documents relevant to this session: {titles}. I'll reference these as context." If none match the scope filter, skip silently.
4. **Deep-read selectively** during the skill's phases/sections when a library document's content is relevant.

**Graceful degradation**: If any library document has malformed or missing front-matter, fall back to using the filename as context. A malformed library document does not block the skill's process.

**Compaction resilience**: Include library scan results (files found, scope matches) in the progress file so post-compaction continuation doesn't re-scan.

## Retro Awareness

Some skills check past retrospectives at startup so they can incorporate lessons from prior work into the current session. Lessons are selected **across all retros**, not just the newest file — the most recent retro is simply whatever epic or change finished last, which is rarely the same as the most *relevant* lesson for the work now starting. To use:

1. **Glob** `docs/retros/[0-9]*-retro-*.md`. If no files found or directory doesn't exist, skip silently rather than blocking the skill.
2. **Gather and select across all retros.** Read the retros (most recent first) and collect their observations — **excluding any observation carrying a `**Retired` marker** (see **Retro Retirement** below) — then select the most *relevant* few rather than everything from a single file. Judge relevance by:
   - **Source/domain match** — does the retro's `**Source**:` artefact or observation text overlap with the current work's subject (same feature area, files, or domain keywords)?
   - **Category match** — is the observation in one of the categories this skill acts on (see the skill's own **Retro incorporation** block)? Observations outside those categories are not surfaced.
   Use **recency only as a tiebreaker** between otherwise equally relevant observations. **Cap the selection** to a handful (≈3–5 observations) so signal is preserved — "two sharp observations beat ten vague ones" applies here as much as in synthesis. If reading every retro is impractical, scan from most recent backwards and stop once the cap is filled with strong matches; note that older retros were not exhausted.
3. Present a brief summary of the **selected observations** to the user, naming the source retro (filename / `**Source**:`) for each so a stale or mis-matched selection stays visible.
4. Use AskUserQuestion: "Retros have observations relevant to this skill. Incorporate?" with options `Yes, incorporate` / `No, skip`.
5. If yes: apply the skill's incorporation guidance to active context throughout the session — not as a prompt one-off, but as a lens applied to each phase/section/step.

**Per-skill incorporation**: Each skill that uses Retro Awareness includes its own **Retro incorporation** block listing:
- Which of the seven retro observation categories matter most to this skill (smooth deliveries, scope surprises, criteria gaps, complexity underestimates, codebase discoveries, testing gaps, patterns worth reusing).
- What concrete actions to take when those categories surface — not vague "use as context," but specific operations the skill performs differently.

Without per-skill guidance, "incorporate" defaults to vague awareness and the retro effectively goes unused. Each skill states what changes.

**Graceful degradation**: If no retro files exist, skip silently. If front-matter or content is malformed, fall back to filename context. A retro check failure does not block — the retro is advisory input, not a gate.

## Retro Retirement

A retro lesson can outlive its usefulness — the module it warned about is gone, the constraint it captured no longer holds, the pattern was superseded. Retirement marks a single observation as no longer relevant so it stops resurfacing, **without** deleting the retro or losing the audit trail.

- **Marker**: append `**Retired {YYYY-MM-DD}**: {reason}` to the observation's bullet, **in place** under its existing category heading in the source retro file. The bullet is not moved or deleted — keeping it where it lives preserves category context and leaves a visible, greppable, reversible record (un-retire by removing the marker). Example: `- Config loader fails silently: callers must null-check. **Retired 2026-06-17**: loader now throws on missing file.`
- **Effect**: the **Retro Awareness** selection step (step 2 above) excludes any observation carrying a `**Retired` marker. Retired observations stay out of the relevance ranking, so they cannot be surfaced, capped-in, or gated on.
- **Who retires**: three deliberate paths, none of them automatic or default — (1) **`/cpm:retro retire`**, the out-of-cycle review pass that is retirement's normal home; (2) **`cpm:do`'s consumption gate**, via its deliberately-confirmed in-cycle **Obsolete** retire — reserved for the rare case where a lesson's usefulness has demonstrably passed mid-run (see that skill); and (3) the **promote-to-library flow** (`/cpm:retro learn`), which retires an observation once its lesson has graduated to the durable reference library, pointing the reason at the new library doc. The `cpm:do` gate's per-run **Not relevant here** disposition is **not** retirement — it is a local, reversible judgement of fit that leaves the source retro untouched, so the lesson is re-judged on the next run.
- **Granularity**: retirement is per-observation. To retire an entire retro's worth of lessons (e.g. a whole epic's context is obsolete), prefer `cpm:archive`, which moves the file out of `docs/retros/` so consumption no longer globs it.

## Retro Synthesis

Given a set of collected retro observations and story outcomes, synthesise them into a retro file. This procedure is shared by `cpm:do` (Step 8, at epic completion) and `cpm:retro` (its main synthesis step) so that both produce identical retro files from the same inputs — there is **one** synthesis implementation, not two.

**Scope of this procedure**: synthesis and file write **only**. The *caller* gathers the inputs (reading the epic doc's `**Retro**:` fields and any `## Lessons` section, or a `docs/quick` record's `## Retro` section) and performs any downstream handoff (library write-back, pivot offers, pipeline suggestions). This procedure neither gathers sources nor offers follow-on actions — observations in, retro file out.

### Inputs

- **Observations**: a list of per-story observations, each carrying a category and a one-sentence note. Categories are the seven fixed retro categories: smooth deliveries, scope surprises, criteria gaps, complexity underestimates, codebase discoveries, testing gaps, patterns worth reusing.
- **Story outcomes**: the source's story statuses (completed vs total, and any blocked/stuck stories) — used for the summary line and as the fallback when no observations exist.
- **Source metadata**: the source artefact path (epic doc or quick record) and a slug derived from it.

### Procedure

1. **Group observations by category.** Place each observation under its declared category heading. Skip categories with no entries.
2. **Synthesise, don't list.** For each category with entries, write a brief synthesis — a sentence or two about what the pattern means and what to do differently next time — not a reformatted list of the raw notes.
3. **Status-only fallback.** If there are no observations at all, replace the Observations section with a simpler **Batch Outcome** section summarising story completion: which stories completed, which were blocked or stuck, and the overall outcome.
4. **Assign the file number and slug — recompute both here.** Compute `{nn}` fresh via the shared **Numbering** procedure for `docs/retros/` (`max(active ∪ archived) + 1`), and derive `{slug}` from *this* synthesis's source artefact name (e.g. epic `01-epic-auth.md` → slug `auth`). Both values are derived at write time — from the Numbering glob and the current source — rather than from a retro filename already sitting in context. A caller's retro-awareness or consumption step may have read existing retro files earlier in the run; those are files you *consumed*, not the file you *write*. Reading a retro and writing a retro are independent operations, so the consumed retro's number, slug, and path have no bearing on the new file.
5. **Write the retro file** to `docs/retros/{nn}-retro-{slug}.md` (create the directory if absent). **The target path is always a new file.** A correct `max + 1` cannot collide with an existing file, so if `{nn}-retro-{slug}.md` is already present you have miscomputed `{nn}` (typically by inheriting a consumed retro's number instead of recomputing it in step 4): stop, recompute `{nn}` via Numbering, and write to the fresh path — the existing retro stays as it is. Scope this guard precisely — a *repeated slug* across runs is normal, not a collision: re-running synthesis for the same source epic is expected to produce a new number with the same slug (e.g. `12-retro-auth.md` written after an earlier `08-retro-auth.md`), and ad-hoc retros legitimately share slugs too. Only an existing **full path** (`{nn}-retro-{slug}.md`) is the error condition; a recurring slug alone is not. Write the file using this format:

   ```markdown
   # Retro: {Title}

   **Date**: {today's date}
   **Source**: {path to source artefact}
   **Stories**: {completed}/{total} complete

   ## Summary

   {1-3 sentence overview — what was accomplished, what the key takeaways are}

   ## Observations

   ### Smooth Deliveries
   - {observation}: {synthesis}

   ### Scope Surprises
   - {observation}: {synthesis}

   ### Criteria Gaps
   - {observation}: {synthesis}

   ### Complexity Underestimates
   - {observation}: {synthesis}

   ### Codebase Discoveries
   - {observation}: {synthesis}

   ### Testing Gaps
   - {observation}: {synthesis}

   ### Patterns Worth Reusing
   - {observation}: {synthesis}

   ## Recommendations

   {2-5 bullets — concrete, actionable suggestions for the next planning cycle.}
   ```

   Include only categories that have entries. For the status-only fallback, replace the Observations section with the Batch Outcome section described in step 3.
6. **Return the written path** to the caller so it can report the file and run any downstream handoff.

**Signal over noise**: two sharp observations beat ten vague ones. Synthesise into patterns. The whole retro file should be digestible in under a minute.

## Progress File Management

CPM skills that maintain a progress file at `docs/plans/.cpm-progress-{session_id}.md` follow this procedure for compaction resilience. Skills define their own *lifecycle triggers* (when to create/update/delete) and *format* (which fields go in the file); everything else below is shared.

**Why this matters**: The progress file is the only recovery point if context compaction fires mid-flow. A stale or missing file means the user loses session state with no recovery — treat the Write call with the same care as saving user code.

**Path resolution**: All paths in skills are relative to the current Claude Code session's working directory. When calling Write, Read, or any file tool, construct the absolute path by prepending the session's primary working directory. Write to the current session's working directory only — cross-project or cross-session writes corrupt state.

**Session ID**: The `{session_id}` in the filename comes from `CPM_SESSION_ID` — a unique identifier for the current Claude Code session, injected into context by the CPM hooks on startup and after compaction. Use this value verbatim when constructing the progress file path. If `CPM_SESSION_ID` is not present in context (e.g. hooks not installed), fall back to `.cpm-progress.md` (no session suffix) for backwards compatibility.

**Resume adoption**: When a session is resumed (`--resume`) or context is cleared (`/clear`), `CPM_SESSION_ID` changes to a new value while the old progress file remains on disk. The hooks inject all existing progress files into context — if one matches the running skill's `**Skill**:` field but has a different session ID in its filename, adopt it:
1. Read the old file's contents (already visible in context from hook injection).
2. Write a new file at `docs/plans/.cpm-progress-{current_session_id}.md` with the same contents.
3. After the Write confirms success, delete the old file: `rm docs/plans/.cpm-progress-{old_session_id}.md`.

Adoption requires `CPM_SESSION_ID` in context. When absent, the fallback path (unsuffixed filename) handles that case.

**Companion compact summary**: When deleting the progress file, also delete `docs/plans/.cpm-compact-summary-{session_id}.md` if it exists — this companion file is written by the PostCompact hook and should be cleaned up alongside the progress file.

**Write semantics**: Use the Write tool to write the full file each time (not Edit — the file is replaced wholesale on every update).

**Late deletion**: Delete the progress file only once output artifacts are confirmed written. If compaction fires between an early deletion and a pending output, all session state is lost.

**Per-skill responsibility**: Each skill's `## State Management` section specifies its own:
- **Lifecycle**: when to create, update, and delete (using the skill's natural unit of progress: phase, section, step, task, turn, etc.).
- **Format**: the markdown skeleton listing the fields specific to this skill, plus any per-skill notes about what those fields should capture.

Skills reference this procedure with: "Follow the shared **Progress File Management** procedure." followed by their **Lifecycle** and **Format** blocks.

## Stale-Progress Check

Every `/cpm:*` skill runs this once-per-session safety-net as an early startup step, so leftover progress files from other sessions are surfaced to the user even when a slash-command invocation would otherwise steamroll the SessionStart hook's advisory output. The rules live in two shipped helpers so they stay in one place: the **guard** (`hooks/lib/cleancheck-guard.sh`) decides *whether* to run this session, and the **classifier** (`hooks/lib/progress-classify.sh`) decides *how each file is labelled*. Both sit under the CPM plugin root — invoke them at `${CLAUDE_PLUGIN_ROOT}/hooks/lib/…` (the same token `hooks.json` uses to locate the hook scripts).

**When to run**: As an early startup step, in the same startup-checks region as Roster Loading — before the skill begins its own work.

**Procedure**:

1. **Consult the guard.** Run:
   `CPM_SESSION_ID="$CPM_SESSION_ID" bash "${CLAUDE_PLUGIN_ROOT}/hooks/lib/cleancheck-guard.sh"`
   It prints exactly one token:
   - `SUPPRESS` — an active ralph loop is present (`.claude/ralph-loop.local.md`). Do nothing — the safety-net is fully silent during ralph runs (the FR11 autonomous carve-out).
   - `SKIP` — this session already ran the check. Do **nothing**.
   - `RUN` — proceed to step 2. (The guard has just recorded this session's sentinel, so later skills in the same session receive `SKIP`.)

2. **Classify.** On `RUN` only, run:
   `CPM_SESSION_ID="$CPM_SESSION_ID" bash "${CLAUDE_PLUGIN_ROOT}/hooks/lib/progress-classify.sh"`
   It emits one tab-delimited record per progress file — `CLASSIFICATION<TAB>PATH<TAB>SKILL<TAB>PHASE<TAB>AGE_SECONDS<TAB>AGE_LABEL`, where CLASSIFICATION is `CURRENT`, `FRESH`, or `STALE`. No records → nothing to surface; stop.

3. **Present — three-way and non-blocking.** Surface the following without halting the user's request, then carry on with what they asked:
   - **`CURRENT`** — the current session's own progress file. Already injected as active state by the hooks, and not a cleanup candidate.
   - **`STALE`** (other session, ≥3 days old) — offer these for cleanup. List each (skill, phase, age, path) and ask which to delete.
   - **`FRESH`** (other session, <3 days old) — informational only ("active/recent parallel session"). Show them for awareness, keep them out of the deletion offer, and surface them rather than dropping them silently.

4. **Deletion is strictly user-confirmed.** Delete only files the user explicitly names, and only after they have seen exactly what will be removed. No path — here or in the helpers — auto-executes a delete. When the user confirms deleting a progress file, also remove its `.cpm-compact-summary-{id}.md` companion if present.

**Trigger reviewed and unchanged** (spec 40 R11, 2026-07-25). The guard already makes this once-per-session — the first `/cpm:*` skill of a session gets `RUN`, every later one gets `SKIP` from a single call — so "early startup step in every skill" describes where the hook sits, not how often the work happens. Its subject is *other* sessions' leftover files, which a larger context window and rarer compaction do not make less likely.

Skills reference this procedure with: "Follow the shared **Stale-Progress Check** procedure."

## Numbering

Assign the next numeric prefix when a skill creates a new numbered artifact (`docs/specifications/`, `docs/epics/`, `docs/plans/`, `docs/briefs/`, `docs/reviews/`, `docs/retros/`, `docs/architecture/`, `docs/quick/`, `docs/discussions/`, etc.). The same rule applies to every artifact type — skills reference this procedure rather than restating the logic inline.

> **Invariant**: Numeric prefix is an integer identifier, not a fixed-width string. Existing files keep the width they were created with.

### Procedure

For a given artifact type with directory `docs/{type}/` and filename pattern `{nn}-{type}-{slug}.md`:

1. **Glob the active directory**: `docs/{type}/[0-9]*-{type}-*.md`.
2. **Glob the archive mirror**: `docs/archive/{type}/[0-9]*-{type}-*.md`. If the archive directory does not exist (fresh project, nothing ever archived), treat this set as empty and continue — the lookup degrades cleanly to active-only.
3. **Extract the leading numeric prefix** from each matched filename. Parse it as an **integer**, not a string: `"100"` sorts below `"99"` lexically and above it as an integer.
4. **Take the union** of the two sets and compute `max + 1`. If both sets are empty, start at `1`.
5. **Format the new number** with a **minimum of 2 digits**, zero-padded. Numbers `< 100` render as `01`, `02`, …, `99`. Numbers `≥ 100` use their natural width: `100`, `101`, and so on. Do not pad beyond 2 digits; do not truncate or reformat existing files.

### Rules

- **Numbers are retired on archive and not reused.** Because the glob unions active and archived directories, a number that has ever been assigned remains reserved even after its artifact is moved to `docs/archive/`. New artifacts always receive `max(active ∪ archived) + 1`.
- **Integer comparison, not lexical.** Any implementation detail that sorts or compares filenames by string ordering will break the moment a directory crosses `99 → 100`. Parse the prefix as an integer before comparing.
- **No bulk renaming.** Existing 2-digit files keep their width when a directory crosses `99 → 100`. The new file is written at its natural width (`100-…`) next to the existing 2-digit files. Mixed-width coexistence is a permanent invariant the glob handles natively via integer comparison.
- **No auto-widening migration.** There is no "renumber on save of #100" operation. Growth past 99 is transparent to the user.
- **Archive preserves the mirrored directory structure** (`docs/archive/{type}/`) so the archive-side glob can find retired numbers. This is a load-bearing contract with `cpm:archive`.

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
| Scope change, integration boundary, missing requirement that affects ≥2 stories or any downstream document | Pivot the upstream artefact | `/cpm:pivot {path}` |
| Pattern noticed, codebase discovery, complexity insight — **no scope change** | Retro observation only | `**Retro**:` field on the current story (per `cpm:do` Step 6 Part B) |
| Both scope change **and** lesson | Pivot now, retro at end | `/cpm:pivot` + `**Retro**:` field at story completion |

**When in doubt, choose pivot.** Inline edits are silent — they leave no trail and bypass the cascade. The cost of an unnecessary pivot is small (the user can skip downstream changes); the cost of silent spec→reality drift is high.

**Inline edit breadcrumb**: When applying an inline edit to a story or task, record an `**Inline change**: {one-line summary} ({YYYY-MM-DD})` field on the story (alongside any existing `**Retro**:` field). This preserves a trail that downstream skills (drift detection, retro synthesis) can see.

**Skill responsibility**: Skills that may surface change moments during execution (`cpm:do`, `cpm:quick`) reference this convention when a change-worthy situation appears. The decision is presented as a structured `AskUserQuestion` gate (per the **Gate Presentation** convention) with the four options above as labels, rather than as a freeform "should we change this?" prompt.

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

**Compatibility note**: Skill text written before this convention may read as if `Glob` and `Grep` are literal tool names. Treat all such references as semantic operations. No skill file rewrites are needed.

## Gate Presentation

`AskUserQuestion` is for the *gate*, not the *content*. The Claude Code preview panel that renders the question is sized for short prompts and short option labels — long content gets truncated and becomes unreadable.

**Rule**: Documents, drafts, alternatives, ADRs, specs, briefs, planning options, lists of proposed changes — render in the assistant's message body **before** the `AskUserQuestion` call. The `AskUserQuestion` itself carries only the decision: "Approve", "Request changes", "Stop", "Choose A / B / C", etc. Question text and option labels stay short enough to fit the preview panel comfortably.

**Good**:

> *(draft, ADR, spec section, etc. rendered in the message body above)*
>
> `AskUserQuestion`: "Approve this draft?" — options: `Approve` / `Request changes` / `Stop`

**Bad**:

> `AskUserQuestion`: "Here is the draft: [200 lines pasted into question text]. Approve?"

**Option previews**: `AskUserQuestion` options can carry an optional `preview` field that renders in a transient side-by-side pane. Reserve it for small *presentational* choices where the user is comparing concrete variants — a short layout mockup, a wording or naming option, a brief snippet shown side by side. Anything the user needs to keep — drafts, specs, ADRs, briefs, plans, lists of proposed changes — goes in the message body instead, because the preview pane is transient, easy to miss, and not part of the saved message output.

When in doubt: if the content the user needs to read is more than a sentence or two, it belongs in the message body, not in the question or its option previews.

## Conversational Output

How much to say between gates, and in what shape. Opus 5's default responses run longer than prior models', and the effort parameter does not reliably shorten them — length responds to being asked for, so ask for it explicitly rather than assuming a lower effort level will deliver it.

Aim for the shortest response that does the job. A CPM skill's product is the artefact on disk; the conversation around it is scaffolding, and scaffolding earns its space by being brief.

### Narration cadence

Between `AskUserQuestion` gates, the update a user wants is short and specific. The shapes that work:

- **Before a gate**: the content itself — draft, table, list — rendered in the message body, then the gate. The content carries the detail; the prose around it is a sentence or two of framing.
- **After a decision**: one line recording what was decided and where it went — "`quick` holds at `high`; folded into Story 2's must-NOT."
- **During a production loop**: name the step and what it found, not the process — "Read the three skill files; the removal surface is concentrated in `do`."
- **When something unexpected turns up**: say it plainly with its evidence, in the flow of the work, rather than saving it for a summary at the end.

The test is whether someone skimming only the narration still knows where they are and what was decided.

### Correcting yourself

Narrate a correction to something you said earlier when the error would change the user's conclusions or decisions. When it would not — a slip in phrasing, a detail that changes nothing downstream — make the correction and carry on without remarking on it.

Opus 5 reaches for self-correction more readily than earlier models. In a facilitated conversation that reads as a running commentary on your own earlier wording, and it spends attention the user was giving to the decision in front of them.

## Written Deliverable Length

Applies to every skill that writes a file — specs, briefs, ADRs, epics, coverage matrices, reviews, audits, retros, communications, and completion records alike.

Let a document's length match what the task actually needs. A spec covering three requirements is shorter than one covering thirty, and that is the right outcome rather than an incomplete one. Opus 5 writes longer by default, so length is worth a look before saving rather than after.

What to leave out:

- **Padding** — restating a point in different words because a section looked thin.
- **Redundant summaries** — a closing recap of what the reader has just read. A summary earns its place when it carries something the body does not: a decision, a count, a next step.
- **Boilerplate sections** — a heading kept because the template offers it, then filled with "N/A" or a sentence of throat-clearing. A section with nothing to say reads better omitted.

This is calibration rather than a budget. No artefact carries a fixed word or section count, and none should gain one — a long document that earns its length is correct, and a short one that leaves out something the reader needs is not.

## Effort Recommendations

Reference for choosing a session's reasoning effort level. Effort is a session setting, fixed before any skill's instructions load — nothing here applies itself, and no skill raises the level or asks for it to be raised. The table is for whoever sets the level.

In practice a session runs at one level throughout. The per-skill rows are most useful when picking that level for a run dominated by a single skill, or when reconsidering a level that has stopped fitting the work.

| Skill | Level | Rationale |
|-------|-------|-----------|
| do | xhigh | Multi-step execution loop with verification, TDD, and state management |
| epics | xhigh | Spec analysis, story decomposition, coverage matrix construction |
| ralph | xhigh | Autonomous multi-epic execution with failure handling and task budgets |
| spec | high | Facilitated requirements gathering across 7 sections; the architecture decisions it fixes are expensive to revisit later |
| architect | high | Multi-phase architecture exploration with trade-off analysis; these decisions constrain everything downstream |
| review | high | Adversarial analysis across several reviewer perspectives; finding what the author missed rewards depth |
| pivot | high | Surgical amendment with cascade analysis and downstream propagation |
| quick | high | Scoped implementation with verification, but bypasses full pipeline ceremony |
| audit | high | Nine-dimension sweep of an unfamiliar codebase, where the finding quality depends on how much of the code is genuinely understood |
| consult | medium | Deep one-to-one consultation with dynamic expert transfer — conversational work Opus 5 handles well below `xhigh` |
| party | medium | Multi-perspective discussion with roster-driven agent simulation; the difficulty is voice and coverage, not depth of reasoning |
| brief | medium | Facilitated product ideation with vision and value proposition synthesis |
| discover | medium | Facilitated problem discovery across 6 phases with perspectives |
| library | medium | Bounded document intake and front-matter generation |
| retro | medium | Synthesis over already-structured epic doc fields; categorisation is bounded |
| present | medium | Artifact transformation with audience selection |
| archive | low | Mechanical file relocation with user confirmation; the judgement is the user's |
| artifact | low | Read the register, write a row and its backlinks; the facts come from the user |
| status | low | Scan-and-report with no implementation |
| templates | low | List-and-scaffold with no analysis |
| clean | low | Enumerate session-state files and delete the ones named; every step is confirmed |

> **Effort note**: Thinking is on by default on Opus 5, and can be turned off only at effort `high` or below — at `xhigh` and above it stays on. Pair the reasoning-heavy skills at `xhigh`/`max` with a large output budget (~64k tokens) so there is room for the reasoning the level implies. Opus 5 also gets more out of `low` and `medium` than earlier models did at the same settings, so a level that once looked too low for a skill may now be the right fit — the levels above are a starting point to revise against real sessions, not a fixed allocation.

## Subagent Delegation

When to use subagents (the Agent tool) vs. working inline. Subagents are valuable for parallelising large, genuinely independent work and protecting the main context window from excessive results — but they add overhead and lose conversational context.

Opus 5 delegates readily, so the guidance below is about restraint rather than encouragement. Delegation earns its overhead only when the work is large, genuinely independent, and parallelisable; anything smaller is faster and clearer done inline. This reverses spec 32's R1, which told the model to actively reach for fan-out because prior models under-delegated — that correction now pushes the wrong way. Both the "Delegate (fan-out) when" and "Work inline when" lists below stay in force.

### Delegate (fan-out) when

Each case below assumes the work is large enough to repay the overhead. Where it is not, work inline.

- **Reading many independent files**: e.g. reading 5+ library documents, scanning multiple epic docs, or auditing files across directories. Each read is independent, and fanning out keeps the results out of the main context.
- **Per-item work across a long list**: e.g. processing each epic independently in a production loop, or reviewing each story in isolation. The items share no state, so they parallelise cleanly.
- **Broad exploratory research**: e.g. sweeping the codebase for a pattern across many directories, or surveying an unfamiliar project structure. The search results inform a decision but are not themselves the deliverable.

Two cases fall outside this even when they look like the ones above:

- **Work completable in a handful of tool calls stays inline.** A search you could run yourself in two or three calls costs more to delegate than to do — the spawn overhead and the round trip outweigh the saving.
- **Verification of your own work stays inline.** Do not use subagents to verify, double-check, or second-guess something you just did. A subagent starting from no context is a poor auditor of work it did not see, and the pattern compounds with the self-checking the model already performs.

### Work inline when

- **The result drives the next step**: e.g. reading a file to decide what to edit next, or checking a test result before proceeding. Sequential dependencies require inline execution.
- **The code is already in context**: e.g. you just read the file, or the user pasted it. Delegating would re-read what you already have.
- **User interaction is needed**: e.g. AskUserQuestion gates, facilitation loops, or confirmation steps. Subagents cannot interact with the user.
- **The work is a single focused operation**: e.g. one edit, one test run, one file creation. The overhead of spawning outweighs the benefit.

### Rules

- Subagents start with no context from the current conversation — the prompt must be self-contained.
- If one subagent can complete the task, use one rather than several, and keep spawn counts low.
- Assign subagents to research and exploration, not to implementation decisions that require conversational context.
- When delegating, specify whether the subagent should write code or just research. The subagent cannot infer intent from the conversation.

## Implementation Guidelines

Cross-cutting rules for all CPM skills that edit files during execution (do, quick, review autofix, pivot cascade, etc.). Skills that reference this document inherit these guidelines automatically.

### No bulk programmatic edits

Edit existing files with the **Edit tool**, applied file-by-file, so that each change is visible, reviewable, and reversible. Stream-processing tools — `sed`, `perl`, `awk`, and the like — have no role in editing files.

- **Why**: Bulk programmatic edits are opaque — they bypass the tool's diffing and review affordances, risk corrupting files on partial matches, and make it impossible to audit what changed after the fact. The Edit tool produces a clear before/after for every change.
- **Scope**: This applies to *editing existing files*. Using Bash for read-only operations (`grep`, `find`, `git`) or running build/test commands is unaffected. Writing *new* files with the Write tool is also fine — the constraint is about modifying existing content.

### Clarity and correctness over speed

Prefer clarity and correctness over speed in all implementation work. Getting it right matters more than getting it done fast.

- **Why**: Momentum-driven shortcuts — skipping verification, batching unrelated changes, or rushing through edits — create subtle bugs and rework. A correct implementation delivered methodically is faster end-to-end than a quick implementation that needs debugging.
- **How this interacts with skill-level guidelines**: Individual skills may emphasise efficiency or momentum (e.g. "keep momentum", "fast by default"). Those guidelines mean *don't add unnecessary ceremony* — they do not mean *sacrifice correctness for speed*. When the two are in tension, correctness wins.

### Version control stays with the user

Do not run mutating git operations on your own initiative — no `git commit`, no `git add`/staging, no `git branch` or `git checkout -b`, no `git push`, no `git merge`/`rebase`/`reset`. Version control is the user's responsibility, performed outside the skill loop. Read-only git inspection (`git status`, `git log`, `git diff`) is fine and often useful.

- **Why**: Self-initiated commits and branches surprise the user, fragment history on their behalf, and can move work onto a branch they never asked for. Leaving the working tree as edited files keeps the user in control of when and how changes are recorded.
- **When git changes are allowed**: only when explicitly directed — a task whose acceptance criteria call for a git action, a user instruction in the conversation, or a wrapper that mandates it (e.g. `cpm:ralph`'s "commit after each story"). Outside those, finish the work and leave committing to the user.

## HTML Output

CPM artifacts are Markdown — the parsed source of truth. Some skills additionally emit **HTML** in one explicitly-bounded role: **companion assets**, visual content the Markdown references — a UI mockup, a data-flow diagram. HTML is not a parsed or consumed data substrate; downstream skills read the Markdown for requirements, not the markup. Skills that generate HTML reference this convention.

An HTML file that merely mirrors a Markdown artifact earns nothing — Markdown already renders anywhere you would read it. A companion asset earns its place by carrying what the prose cannot. Human-facing *interpretations* — a status dashboard, a dependency view, an audience-reframed communication — are not HTML outputs at all: they are published as hosted pages. See **Artifact Publishing**.

### Consume the shared template — do not fork it

There is exactly **one** shared styling/layout asset: `cpm/assets/html/template.html` (relative to the plugin root). Companion assets draw their styling and layout from this single asset so they stay visually consistent as they accumulate across a project, and no skill grows divergent CSS/layout. Forking the template's CSS, copying its `<style>` block into a skill, or hand-rolling a parallel stylesheet all sit outside this convention.

The template governs **local companion assets only**. A published page is composed per the `artifact-design` skill instead — see **Artifact Publishing**. The two solve different problems: committed files accumulate and drift without a single enforced stylesheet, whereas a hosted page is generated fresh and read once.

**The one carve-out**: a companion asset that represents **deliverable functionality** — a mockup of the UI of the system being built — is *system-specific* and must look like the target system, not CPM. Those mockups deliberately do **not** consume or wear the shared chrome. See *Companion-asset content: shared chrome vs. system-specific mockups* below. Documentation visuals that explain the artifact use the shared template.

The template is a complete, valid, self-contained HTML5 document with an inline `<style>` design system and **placeholder comment tokens** that consumers substitute. The consumption model is:

1. Read `cpm/assets/html/template.html`.
2. Replace each placeholder token with generated content, leaving the `<style>` block untouched:
   - `<!-- CPM:TITLE -->` — document title (also used in `<title>`)
   - `<!-- CPM:SUBTITLE -->` — kicker / eyebrow line (optional; collapses when empty)
   - `<!-- CPM:META -->` — date / source-artifact line (optional)
   - `<!-- CPM:NAV -->` — contents sidebar (a `<ul>` of in-page anchors; styled by `.cpm-toc`)
   - `<!-- CPM:CONTENT -->` — main body
   - `<!-- CPM:FOOTER -->` — footer (optional)
3. Write the result to the storage path for its role (below).

The template ships reusable component classes so consumers express each role without new CSS: prose + tables + code blocks; `.adr-options`/`.adr-option` (side-by-side ADR option/trade-off columns, `.is-chosen` for the selected option); `.sev-critical`/`.sev-major`/`.sev-minor`/`.sev-info` badges and `.finding` blocks (review severity); `.cpm-figure` + `<figcaption>` (container for documentation diagrams that explain the artifact — *not* for deliverable-functionality mockups, see below); `.cpm-callout` (`--note`/`--warn`/`--tip`); and `.cpm-memo`/`.cpm-memo-fields` (memo / onboarding layout). Add `class="cpm-numbered"` to `<main>` for editorial section numbering.

### Storage & reference paths

| Role | Path | Notes |
|------|------|-------|
| Companion asset | `docs/{type}/assets/{nn}-{slug}-{label}.html` | Referenced from the Markdown by a stable **relative** path; `{label}` distinguishes multiple assets for one artifact |

`{type}` is the artifact directory (`specifications`, `architecture`, `reviews`, …); `{nn}` and `{slug}` match the source Markdown's number and slug. Numbering globs match `*.md`, so these HTML siblings do not collide with the numbering scheme.

Companion assets stay repo files. They are not published, and `cpm:do` opens them mid-execution as visual design targets — a URL would make a pipeline step depend on network reachability.

### Self-contained rule

Every companion asset is a **single self-contained file**: inline CSS and inline SVG / `data:` URIs only — no external CSS, JS, images, or fonts, no CDN, no network request to render, no server, and no build step. It is **static — no JavaScript**. A file opens correctly when double-clicked or sent to someone. (The `[integration]` self-containment validator in `cpm/hooks/tests/html-test-helpers.sh` enforces this.)

Export affordances — copy-as-prompt and copy-as-JSON — belong to published pages, not to companion assets. See **Artifact Publishing → Export affordances**.

### Generate-from-source, never replace

No HTML generation step ever mutates or replaces the source Markdown. Generation reads the Markdown read-only and writes HTML to a separate path; the Markdown remains the parsed source of truth. Re-rendering after the Markdown changes updates the existing HTML file in place rather than spawning duplicates. (The source-immutability check in `html-test-helpers.sh` enforces the no-mutation guarantee.)

### Companion-asset content: shared chrome vs. system-specific mockups

Companion assets are two different things, and they are styled differently:

- **Documentation visuals** — diagrams that *explain* the artifact (architecture, data-flow, sequence). This is CPM explaining its own content, so it wears the shared chrome: render the diagram (inline SVG) inside a `.cpm-figure` within the shared shell. Use the template's styling; do not fork it.
- **Deliverable-functionality mockups** — a mockup that represents the **UI of the system being built** (a preview of what the deliverable will look like). These are **system-specific**: the mockup must represent the target system's own design language, *not* CPM's documentation chrome. They therefore **do not consume, embed, or inherit the shared template** — a producing skill builds the mockup as a standalone HTML file, and the `frontend-design` skill is appropriate here precisely because the design must be bespoke to the target system. The mockup is still **self-contained** (single file, inline CSS/SVG, no external resources, no JS — per the self-contained rule) and is stored at the same companion-asset path, but its styling is the deliverable's rather than the template's.

**Rule of thumb**: if the visual *explains the artifact*, it wears the shared chrome; if the visual *is a preview of the deliverable*, it wears the deliverable's own design and stays clear of the shared template.

## Artifact Publishing

A skill's output can be **published** as a hosted, shareable web page using the **Artifact** tool. Publishing composes a page from the artifact's content and returns a URL that can be passed to someone who does not have the repository. It is not a storage mechanism: where the skill also writes a local file, that file remains the output of record, self-contained and openable offline; where it does not, the register entry below is the durable trace.

Skills reference this procedure with exactly this line — copy it byte-for-byte, adding no prefix, suffix, or rewording:

```
An artifact can be published from this output on request — follow the shared **Artifact Publishing** procedure. It is always separately confirmed, and never the default.
```

Each site pairs that line with one skill-specific sentence naming what an artifact would show for *that* skill's output. The shared line carries the rule; the local sentence carries the judgement.

**Always separately confirmed.** Producing the output and publishing it are two decisions, and agreement to the first is never agreement to the second. Ask on its own terms, and say in the question what publishing does: the page is hosted on claude.ai, private to the user by default and shareable by them afterwards, and content sent there may be cached or indexed even after the artifact is deleted. Publishing is never offered as a default, and autonomous runs (`cpm:ralph`) never publish.

**What is never published.** A page that presents itself as issued by a real organisation the user does not represent, that contains fabricated records or approvals presented as genuine, or that targets a private individual. Where an output has that shape, keep it local and do not offer publishing. This bites hardest on `present` communications and deliverable-functionality mockups, which are the outputs most likely to carry someone else's branding.

**Availability.** If the Artifact tool is not present in the session, say so plainly and skip. The skill's own work is unaffected: it still produces whatever it produces, and a skill whose only visual form was the artifact degrades to stating the same content in the conversation. Never treat the tool's absence as a failure of the skill.

### Mechanics

1. **Load the `artifact-design` skill first** — the Artifact tool requires it before a page is written.
2. **Compose the page per `artifact-design`, and emit it as a body fragment.** The Artifact tool supplies its own `<!doctype html>`, `<head>`, and `<body>`, so a complete document is the wrong shape: emit the content with its `<style>` block at the top and no structural tags. Do **not** consume `cpm/assets/html/template.html` here — that template governs local companion assets, which are committed files that drift apart without one enforced stylesheet. A published page is composed fresh and read once, so `artifact-design` governs it instead.
3. **Write the fragment to an ephemeral scratch path** — `docs/plans/{skill}-artifact-{nn}-{slug}.html` — then publish that path. It is a build intermediate, not a tracked CPM artifact, and stays out of the storage directories above, whose path contracts describe complete self-contained documents. The path is per-output and deterministic, so re-publishing the same output redeploys to the same URL rather than minting a second one. It is overwritten on each publish and safe to delete.
4. **Set the page's identity**: a `<title>` matching the artifact, a one-sentence `description`, and a `favicon` kept stable across redeploys of the same output — readers find a tab by its icon, and a changed one reads as a different page.

### Export affordances

Where it adds value, a published page may carry **inline vanilla JavaScript** for export controls:

- **Copy-as-prompt** — copies a ready-to-run CPM command to the clipboard (e.g. `/cpm:do docs/epics/05-epic-foo.md` for the recommended next step), so the reader stays in the loop by pasting it back into a session.
- **Copy-as-JSON** — copies a **well-formed JSON** snapshot of the relevant selection (e.g. the ready-to-pick-up list, or the status summary counts) for downstream tooling.

Three rules hold for every export affordance. **Inline vanilla JS only** — no external `<script src>`, no framework, no bundler, no build step; the Artifact tool's CSP blocks external hosts, and the page must stay self-contained. **Read-only / export-only** — the only effect of any interaction is placing text on the clipboard; mutation of an epic doc or any source artifact stays exclusively with `cpm:do`. **Export data is embedded at generation time** — the prompt strings and the JSON snapshot are baked in when the page is composed (a `data-*` attribute, or a `<script type="application/json">` block), so export needs no network call and does not re-read a source file.

Canonical minimal shape (consume this rather than hand-rolling divergent handlers): a button carrying its payload in a `data-*` attribute plus one delegated click handler that copies it.

```html
<button type="button" class="copy-btn" data-prompt="/cpm:do docs/epics/05-epic-foo.md">Copy next step</button>
<script>
  document.addEventListener('click', function (e) {
    var b = e.target.closest('.copy-btn');
    if (!b) return;
    var payload = b.dataset.json || b.dataset.prompt || '';
    if (navigator.clipboard) navigator.clipboard.writeText(payload);
  });
</script>
```

**Clipboard access inside the artifact frame is verified working** (2026-07-25, tested on a live published page). The page reported `window !== top`, a secure context, and `navigator.clipboard.writeText` present; both a copy-as-prompt and a copy-as-JSON control wrote successfully, confirmed by pasting. Notably `permissions.query("clipboard-write")` came back **unsupported** on that engine and the write still succeeded — so treat that query as a diagnostic, never as a gate to branch on.

Two things follow. **Keep the `navigator.clipboard` guard**: it costs one condition and covers the engines this was not tested on. **Keep rendering the payload as selectable `<pre>` text alongside the control** — not as a fallback for a dead button any more, but because a reader who wants to read the command rather than paste it should not have to click to see it. A purely static page (no export controls) remains a valid deliverable — interactivity is an enhancement, not the point.

### Recording is part of publishing

Recording is part of publishing, not a follow-up. As soon as the URL comes back:

- **Register it** in `docs/artifacts/index.md` per the `cpm:artifact` skill's Register format — URL, what it is, the date, the source artifact(s) as the association, and one sentence on why it was published.
- **Record it on the source artifact** in an `**Artifacts**:` metadata field, so the relationship reads from both ends.

An artifact whose URL exists only in the transcript is one nobody finds again — that is the failure this step exists to prevent, and it is why registration happens at the moment of publishing rather than being left to a later tidy-up. A later session updating the same output passes the recorded URL when publishing; without it, a session that did not itself publish mints a *new* URL and every link already shared goes stale.

## A Closing Note on Length and Tone

Placed last because it applies to everything above.

**Length**: say what the step found and what happens next, then stop. When two phrasings carry the same meaning, use the shorter one. Let the artefacts hold the detail — they are what the user keeps.

**Tone**: plain and direct, warm enough to be good company across a long facilitation. State confidence where the evidence supports it and uncertainty where it does not; neither needs padding.
