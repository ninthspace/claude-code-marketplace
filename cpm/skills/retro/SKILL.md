---
name: cpm:retro
description: Lightweight retrospective. Reads a completed epic doc, synthesises observations, and writes a retro file for feed-forward into the next planning cycle. Triggers on "/cpm:retro".
---

# Lightweight Retrospective

Read a completed (or partially completed) epic doc, synthesise observations captured during task execution, and produce a retro file that feeds forward into the next planning cycle.

## Input

Check for input in this order:

1. If `$ARGUMENTS` references a file path (e.g. `docs/epics/01-epic-auth.md`), use that as the epic doc.
2. If no path given, look for the most recent `docs/epics/*-epic-*.md` file and ask the user to confirm.
3. If no epic docs exist, tell the user there's nothing to retro and stop.

## Process

**State tracking**: Before starting Step 1, create the progress file (see State Management below). Each step below ends with a mandatory progress file update — do not skip it. After saving the final retro file, delete the progress file.

### Template Hint (Startup)

Before Step 1, display:

> Output format is fixed (used by downstream skills). Run `/cpm:templates preview retro` to see the format.

### Step 1: Read Epic Doc

Read the resolved epic doc with the Read tool. Identify:

- Total number of stories and their statuses (Pending, In Progress, Complete)
- Any `**Retro**:` fields on completed stories (these are per-story observations captured by `cpm:do` Step 6, Part B — mandatory on verification gates)
- Any `## Lessons` section already present (batch summary from `cpm:do` Step 8)
- The overall completion state of the batch

Present a brief summary to the user: how many stories, how many complete, how many observations found.

**Update progress file now** — write the full `.cpm-progress-{session_id}.md` with Step 1 summary before continuing.

### Step 2: Synthesise Observations

Analyse the collected observations and story outcomes. Build the retro content:

**If `**Retro**:` fields exist**, group them by observation category:
- **Smooth Deliveries**: Stories that went as planned — useful for identifying what good scoping looks like
- **Scope Surprises**: Stories that were larger or smaller than expected
- **Criteria Gaps**: Acceptance criteria that missed something important
- **Complexity Underestimates**: Stories harder than expected due to technical factors
- **Codebase Discoveries**: Unexpected findings in the codebase
- **Testing Gaps**: Tests that revealed issues acceptance criteria didn't anticipate, or acceptance criteria that proved untestable with the available test infrastructure
- **Patterns Worth Reusing**: Approaches or abstractions discovered during implementation that should be applied elsewhere

**If a `## Lessons` section exists but no `**Retro**:` fields** (e.g. fields were lost during editing, or an older `cpm:do` run synthesised them away), use the `## Lessons` section as input — it contains the same observations in pre-grouped form.

**If both `**Retro**:` fields and `## Lessons` exist**, use the `**Retro**:` fields as primary input (they are the raw observations). Reference the `## Lessons` grouping structure but don't double-count observations that appear in both places.

**If neither `**Retro**:` fields nor `## Lessons` exist**, produce a summary from story status alone:
- Which stories completed, which didn't
- Any stories that were blocked or stuck
- Overall batch outcome

For each category with observations, write a brief synthesis — not just a list, but a sentence or two about what the pattern means and what to do differently next time.

**Update progress file now** — write the full `.cpm-progress-{session_id}.md` with Step 2 summary before continuing.

### Step 3: Write Retro File

Save the retro file to `docs/retros/{nn}-retro-{slug}.md`. Create the `docs/retros/` directory if it doesn't exist.

- `{nn}` is a zero-padded auto-incrementing number. Use the Glob tool to list existing `docs/retros/[0-9]*-retro-*.md` files, find the highest number, and increment by 1. If none exist, start at `01`.
- `{slug}` is derived from the epic doc name (e.g. epic doc `01-epic-auth.md` produces retro slug `auth`).

Format:

```markdown
# Retro: {Title}

**Date**: {today's date}
**Source**: {path to epic doc}
**Stories**: {completed}/{total} complete

## Summary

{1-3 sentence overview of the batch — what was accomplished, what the key takeaways are}

## Observations

### Smooth Deliveries
- {observation from story N}: {synthesis}

### Scope Surprises
- {observation from story N}: {synthesis}

### Criteria Gaps
- {observation from story N}: {synthesis}

### Complexity Underestimates
- {observation from story N}: {synthesis}

### Codebase Discoveries
- {observation from story N}: {synthesis}

### Testing Gaps
- {observation from story N}: {synthesis}

### Patterns Worth Reusing
- {observation from story N}: {synthesis}

## Recommendations

{2-5 bullet points — concrete suggestions for the next planning cycle based on the observations. These should be actionable inputs for cpm:discover or cpm:spec.}
```

Only include observation categories that have entries. If no `**Retro**:` fields exist, replace the Observations section with a simpler "Batch Outcome" section summarising story completion status.

Tell the user the retro file path after saving.

**Update progress file now** — write the full `.cpm-progress-{session_id}.md` with Step 3 summary before continuing.

### Step 3.5: Library Write-Back

After writing the retro file, check if any retro observations should be fed back into library documents. This step closes the loop: `library → ... → retro → library`.

1. **Glob** `docs/library/*.md`. If no files found or directory doesn't exist, skip this step silently and proceed to Step 4.

2. **Read front-matter** of each library document. Filter to documents whose `scope` array includes `do` or `all` — these are the documents that guided task execution and are most likely to benefit from retro observations.

3. **Match observations to library documents**: For each retro observation (from the `**Retro**:` fields collected in Step 1), assess whether it's relevant to any library document. Use the observation category and content to match:
   - **Codebase discoveries** → likely relevant to architecture or coding standards docs
   - **Complexity underestimates** → may indicate missing constraints in architecture docs
   - **Criteria gaps** → may indicate missing rules in coding standards or business rules docs
   - **Scope surprises** → less commonly relevant to library docs, but flag if they reveal missing architectural context
   - **Testing gaps** → may indicate missing testing conventions in library docs or gaps in test infrastructure documentation

4. **Propose amendments**: For each matched observation, draft an amendment block:

   ```markdown
   ## Amendment — {YYYY-MM-DD} (via retro)

   **Source**: {path to retro file just written}
   **Category**: {observation category}

   {Observation text — what was learned and what should change}
   ```

5. **User approval gate**: Present all proposed amendments to the user, grouped by target library document. Use AskUserQuestion:
   - **Apply all amendments** — Write all proposed amendments
   - **Review individually** — Walk through each amendment one at a time
   - **Skip write-back** — Don't amend any library documents

6. **Write amendments**: For each approved amendment, use the Edit tool to:
   - Append the `## Amendment` block to the end of the library document
   - Update the `last-reviewed` date in the document's front-matter to today's date

**Graceful degradation**:
- If no library directory exists, skip silently.
- If no observations match any library documents, skip silently — don't force amendments.
- If no `**Retro**:` fields were captured (status-only retro), skip this step entirely.
- Never block the retro workflow for write-back failures.

**Update progress file now** — write the full `.cpm-progress-{session_id}.md` with Step 3.5 summary before continuing.

### Step 4: Pipeline Handoff

After presenting the retro file path, offer the user options for what to do next. Use AskUserQuestion:

- **Continue to /cpm:discover** — Use the retro as starting context for problem discovery
- **Continue to /cpm:spec** — Use the retro as starting context for requirements specification
- **Continue to /cpm:epics** — Use the retro as starting context for work breakdown
- **Just exit** — End the session, no handoff

If the user chooses a pipeline skill, pass the retro file path as the input context for that skill. The retro file becomes the `$ARGUMENTS` equivalent — the next skill should treat it as its starting context.

Delete the progress file after handoff or exit.

## State Management

Maintain `docs/plans/.cpm-progress-{session_id}.md` throughout the session for compaction resilience. This allows seamless continuation if context compaction fires mid-conversation.

**Path resolution**: All paths in this skill are relative to the current Claude Code session's working directory. When calling Write, Glob, Read, or any file tool, construct the absolute path by prepending the session's primary working directory. Never write to a different project's directory or reuse paths from other sessions.

**Session ID**: The `{session_id}` in the filename comes from `CPM_SESSION_ID` — a unique identifier for the current Claude Code session, injected into context by the CPM hooks on startup and after compaction. Use this value verbatim when constructing the progress file path. If `CPM_SESSION_ID` is not present in context (e.g. hooks not installed), fall back to `.cpm-progress.md` (no session suffix) for backwards compatibility.

**Resume adoption**: When a session is resumed (`--resume`), `CPM_SESSION_ID` changes to a new value while the old progress file remains on disk. The hooks inject all existing progress files into context on startup — if one matches this skill's `**Skill**:` field but has a different session ID in its filename, adopt it:
1. Read the old file's contents (already visible in context from hook injection).
2. Write a new file at `docs/plans/.cpm-progress-{current_session_id}.md` with the same contents.
3. After the Write confirms success, delete the old file: `rm docs/plans/.cpm-progress-{old_session_id}.md`.
Do not attempt adoption if `CPM_SESSION_ID` is absent from context — the fallback path handles that case.

**Create** the file before starting Step 1 (ensure `docs/plans/` exists). **Update** it after each step completes. **Delete** it only after the final retro file has been saved and confirmed written — never before. If compaction fires between deletion and a pending write, all session state is lost.

Use the Write tool to write the full file each time (not Edit — the file is replaced wholesale). Format:

```markdown
# CPM Session State

**Skill**: cpm:retro
**Step**: {N} of 4 — {Step Name}
**Output target**: docs/retros/{nn}-retro-{slug}.md
**Input source**: {path to epic doc}

## Completed Steps

### Step 1: Read Epic Doc
{Summary — story count, completion status, observation count}

### Step 2: Synthesise Observations
{Summary — categories found, key patterns identified}

### Step 3: Write Retro File
{Summary — file path written, recommendation count}

{...include only completed steps...}

## Next Action
{What to do next}
```

## Guidelines

- **Signal over noise.** A retro with 2 sharp observations is better than one with 10 vague ones. Synthesise, don't just reformat.
- **Actionable recommendations.** Every recommendation should be something concrete that changes how the next cycle is planned or executed.
- **Works without observations.** If no `**Retro**:` fields were captured, still produce a useful retro from story status — what completed, what didn't, what that implies.
- **Scannable.** The entire retro file should be digestible in under a minute. Use bullet points and short paragraphs.
