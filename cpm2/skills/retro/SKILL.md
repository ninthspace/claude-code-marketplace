---
name: cpm2:retro
description: Lightweight retrospective. Reads a completed epic doc, synthesises observations, and writes a retro file for feed-forward into the next planning cycle. Triggers on "/cpm2:retro".
---

# Lightweight Retrospective

Read a completed (or partially completed) epic doc, synthesise observations captured during task execution, and produce a retro file that feeds forward into the next planning cycle.

## Input

This skill operates on two source types: **epic docs** (`docs/epics/`) and **quick records** (`docs/quick/`). Both produce retro-eligible observations during execution; the retro skill consumes either kind.

Check for input in this order:

1. If `$ARGUMENTS` references a file path, use it. Accept paths under `docs/epics/` (epic doc) or `docs/quick/` (quick record).
2. If no path given, look for the most recent file across **both** `docs/epics/*-epic-*.md` and `docs/quick/*-quick-*.md` (compare by filename prefix or modification time). Present the most recent candidate(s) to the user with AskUserQuestion to confirm.
3. If neither directory has matching files, tell the user there's nothing to retro and stop.

**Source detection**: Once the input is resolved, classify it by directory or filename pattern:
- **Epic source** (`docs/epics/...-epic-...md`): observations live in `**Retro**:` fields on completed stories and the optional `## Lessons` section. Steps 1-3 below apply as written.
- **Quick source** (`docs/quick/...-quick-...md`): observations live in the record's `## Retro` section (mandatory single-category observation). Steps 1-3 still apply, with adjustments noted inline.

## Process

**State tracking**: Create the progress file before Step 1 and update it after each step completes. See State Management below for the format and rationale. Delete the progress file once the final retro file has been saved.

### Template Hint (Startup)

Before Step 1, display:

> Output format is fixed (used by downstream skills). Run `/cpm2:templates preview retro` to see the format.

### Step 1: Read Source Document

Read the resolved source document with the Read tool.

**For epic sources** (`docs/epics/`), identify:
- Total number of stories and their statuses (Pending, In Progress, Complete)
- Any `**Retro**:` fields on completed stories (these are per-story observations captured by `cpm2:do` Step 6, Part B — mandatory on verification gates)
- Any `## Lessons` section already present (batch summary from `cpm2:do` Step 8)
- The overall completion state of the batch

**For quick sources** (`docs/quick/`), identify:
- The change description, classification (`fix` or `change`), and verification summary
- The `## Retro` section's observation — a single category and one-sentence observation per the format defined by `cpm2:quick`
- Whether the change shipped successfully (record promoted to completion record per `cpm2:quick` Step 4)

Present a brief summary to the user — for epic sources: story counts, completion, observation count. For quick sources: change classification, observation category, outcome.

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

**If a `## Lessons` section exists but no `**Retro**:` fields** (e.g. fields were lost during editing, or an older `cpm2:do` run synthesised them away), use the `## Lessons` section as input — it contains the same observations in pre-grouped form.

**If both `**Retro**:` fields and `## Lessons` exist**, use the `**Retro**:` fields as primary input (they are the raw observations). Reference the `## Lessons` grouping structure but count each observation only once, even when it appears in both places.

**If neither `**Retro**:` fields nor `## Lessons` exist**, produce a summary from story status alone:
- Which stories completed, which didn't
- Any stories that were blocked or stuck
- Overall batch outcome

**For quick sources**: the input is a single observation, not a batch. Place it under its declared category (e.g. a "Codebase discovery" observation goes under that single heading) and write a one-sentence synthesis. Skip categories that have no entries — a quick retro often produces a single-category retro file, which is fine.

For each category with observations, write a brief synthesis — not just a list, but a sentence or two about what the pattern means and what to do differently next time.

### Step 3: Write Retro File

Save the retro file to `docs/retros/{nn}-retro-{slug}.md`. Create the `docs/retros/` directory if it doesn't exist.

- `{nn}` is assigned by the shared **Numbering** procedure (from the CPM Shared Skill Conventions loaded at session start).
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

{2-5 bullet points — concrete suggestions for the next planning cycle based on the observations. These should be actionable inputs for cpm2:discover or cpm2:spec.}
```

Only include observation categories that have entries. If no `**Retro**:` fields exist, replace the Observations section with a simpler "Batch Outcome" section summarising story completion status.

Tell the user the retro file path after saving.

### Step 3.5: Library Write-Back

After writing the retro file, check if any retro observations should be fed back into library documents. This step closes the loop: `library → ... → retro → library`.

1. **Glob** `docs/library/*.md`. If no files found or directory doesn't exist, skip this step silently and proceed to Step 4.

2. **Read front-matter** of each library document using the Read tool. Read each file individually with the Read tool directly (Bash loops with shell variables lose context). Filter to documents whose `scope` array includes `do` or `all` — these are the documents that guided task execution and are most likely to benefit from retro observations.

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
   - **Skip write-back** — Leave all library documents unchanged

6. **Write amendments**: For each approved amendment, use the Edit tool to:
   - Append the `## Amendment` block to the end of the library document
   - Update the `last-reviewed` date in the document's front-matter to today's date

**Graceful degradation**:
- If no library directory exists, skip silently.
- If no observations match any library documents, skip silently — only amend when there is a genuine match.
- If no `**Retro**:` fields were captured (status-only retro), skip this step entirely.
- The retro workflow always continues past write-back failures.

### Step 4: Pipeline Handoff

After presenting the retro file path, offer the user options for what to do next.

**Pivot suggestion check**: Before presenting the handoff options, scan the synthesised observations for scope-affecting categories — **criteria gaps**, **scope surprises**, and **codebase discoveries** that imply the source spec or epic missed something material. If any such observation is present, surface a pivot offer alongside the regular handoff options.

Use AskUserQuestion:

- **Continue to /cpm2:pivot** *(only when scope-affecting observations exist)* — Use the retro to amend the source spec/epic. Pass the source artefact path (from the retro's `**Source**:` field) as `$ARGUMENTS` to `/cpm2:pivot`.
- **Continue to /cpm2:discover** — Use the retro as starting context for problem discovery.
- **Continue to /cpm2:spec** — Use the retro as starting context for requirements specification.
- **Continue to /cpm2:epics** — Use the retro as starting context for work breakdown.
- **Just exit** — End the session, no handoff.

If the user chooses a pipeline skill, pass the retro file path (or source artefact path for pivot) as the input context for that skill.

Delete the progress file after handoff or exit.

## State Management

Follow the shared **Progress File Management** procedure.

**Lifecycle**:
- **Create**: before starting Step 1 (ensure `docs/plans/` exists).
- **Update**: after each step completes.
- **Delete**: only after the final retro file has been saved and confirmed written.

**Format**:

```markdown
# CPM Session State

**Skill**: cpm2:retro
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

- **Signal over noise.** A retro with 2 sharp observations is better than one with 10 vague ones. Synthesise into patterns, not just reformatted lists.
- **Actionable recommendations.** Every recommendation should be something concrete that changes how the next cycle is planned or executed.
- **Works without observations.** If no `**Retro**:` fields were captured, still produce a useful retro from story status — what completed, what didn't, what that implies.
- **Scannable.** The entire retro file should be digestible in under a minute. Use bullet points and short paragraphs.
