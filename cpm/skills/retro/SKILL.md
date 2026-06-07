---
name: cpm:retro
description: Lightweight retrospective. Reads a completed epic doc, synthesises observations, and writes a retro file for feed-forward into the next planning cycle. Triggers on "/cpm:retro".
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

> Output format is fixed (used by downstream skills). Run `/cpm:templates preview retro` to see the format.

### Step 1: Read Source Document

Read the resolved source document with the Read tool.

**For epic sources** (`docs/epics/`), identify:
- Total number of stories and their statuses (Pending, In Progress, Complete)
- Any `**Retro**:` fields on completed stories (these are per-story observations captured by `cpm:do` Step 6, Part B — mandatory on verification gates)
- Any `## Lessons` section already present (batch summary from `cpm:do` Step 8)
- The overall completion state of the batch

**For quick sources** (`docs/quick/`), identify:
- The change description, classification (`fix` or `change`), and verification summary
- The `## Retro` section's observation — a single category and one-sentence observation per the format defined by `cpm:quick`
- Whether the change shipped successfully (record promoted to completion record per `cpm:quick` Step 4)

Present a brief summary to the user — for epic sources: story counts, completion, observation count. For quick sources: change classification, observation category, outcome.

### Step 2: Synthesise Observations

Gather the observations from the source resolved in Step 1, then hand them to the shared **Retro Synthesis** procedure (in the CPM Shared Skill Conventions). Source-gathering is this skill's responsibility; the grouping, synthesis, and retro-file format live in the shared procedure, so that `cpm:do` and `cpm:retro` produce identical retro files from the same inputs — there is one synthesis implementation, not two.

**Gather the observations** into the shared procedure's input shape — a list of per-story observations, each with a category and a one-sentence note:

**For epic sources**:
- **If `**Retro**:` fields exist**, each field is one observation — its `[category]` is the category and the text is the note. The seven categories are: smooth deliveries, scope surprises, criteria gaps, complexity underestimates, codebase discoveries, testing gaps, patterns worth reusing.
- **If a `## Lessons` section exists but no `**Retro**:` fields** (e.g. fields were lost during editing, or an older `cpm:do` run synthesised them away), use the `## Lessons` section as the observation source — it contains the same observations in pre-grouped form.
- **If both exist**, use the `**Retro**:` fields as the primary observations (they are the raw input) and count each only once, even when it also appears in `## Lessons`.
- **If neither exists**, pass no observations — the shared procedure's status-only fallback produces a Batch Outcome summary from story statuses alone.

**For quick sources**: pass a single observation — the declared category and one-sentence note from the record's `## Retro` section.

**Then follow the shared Retro Synthesis procedure**, passing the gathered observations, the source's story outcomes (story counts and any blocked/stuck stories identified in Step 1), and the source artefact path. The procedure groups by category, writes a brief synthesis per category (or the Batch Outcome fallback), and proceeds to the file write in Step 3.

### Step 3: Write Retro File

The shared **Retro Synthesis** procedure (invoked in Step 2) performs the write: it assigns `{nn}` via the shared **Numbering** procedure, derives `{slug}` from the source artefact name (e.g. epic doc `01-epic-auth.md` produces retro slug `auth`), creates `docs/retros/` if it doesn't exist, and writes the retro file to `docs/retros/{nn}-retro-{slug}.md` in the shared retro-file format.

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

- **Continue to /cpm:pivot** *(only when scope-affecting observations exist)* — Use the retro to amend the source spec/epic. Pass the source artefact path (from the retro's `**Source**:` field) as `$ARGUMENTS` to `/cpm:pivot`.
- **Continue to /cpm:discover** — Use the retro as starting context for problem discovery.
- **Continue to /cpm:spec** — Use the retro as starting context for requirements specification.
- **Continue to /cpm:epics** — Use the retro as starting context for work breakdown.
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

- **Signal over noise.** A retro with 2 sharp observations is better than one with 10 vague ones. Synthesise into patterns, not just reformatted lists.
- **Actionable recommendations.** Every recommendation should be something concrete that changes how the next cycle is planned or executed.
- **Works without observations.** If no `**Retro**:` fields were captured, still produce a useful retro from story status — what completed, what didn't, what that implies.
- **Scannable.** The entire retro file should be digestible in under a minute. Use bullet points and short paragraphs.
