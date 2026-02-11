---
name: cpm:pivot
description: Course correction. Revisit any planning artefact, surgically amend it, and cascade changes through downstream documents. Triggers on "/cpm:pivot".
---

# Course Correction

Revisit any planning artefact (brief, spec, or stories), make surgical edits, and walk downstream documents through guided updates. Pivot is lighter than re-running the original skill — amend what exists rather than starting over.

## Input

Check for input in this order:

1. If `$ARGUMENTS` is a file path (e.g. `docs/plans/01-plan-auth.md`), use that as the target document. Skip artefact chain discovery — go straight to the amendment workflow.
2. If no path given, run artefact chain discovery (see below) and present the user with a selection.
3. If no planning documents exist anywhere, tell the user there's nothing to pivot and stop.

## Process

**State tracking**: Before starting Step 1, create the progress file (see State Management below). Each step below ends with a mandatory progress file update — do not skip it. After completing the workflow (or exiting early), delete the file.

### Step 1: Artefact Chain Discovery

Discover existing planning artefacts and their relationships. Skip this step if `$ARGUMENTS` provided a direct file path.

1. **Glob all three planning directories**:
   - `docs/plans/[0-9]*-plan-*.md` (briefs from cpm:discover)
   - `docs/specifications/[0-9]*-spec-*.md` (specs from cpm:spec)
   - `docs/stories/[0-9]*-story-*.md` (stories from cpm:stories)

2. **Build dependency chains**: For each document found, read the first 10 lines and look for back-reference fields:
   - Specs have `**Brief**:` — may contain a file path (e.g. `docs/plans/01-plan-auth.md`) or a description (e.g. `Party mode discussion`). Only treat it as a chain link if the value is a valid file path that exists on disk.
   - Stories have `**Source**:` — typically a file path to the source spec (e.g. `docs/specifications/01-spec-auth.md`). Verify the file exists before treating it as a chain link.
   - Briefs are root nodes with no upstream reference.

   Use verified file-path references to group documents into chains (e.g. `plan-auth.md` → `spec-auth.md` → `story-auth.md`).

3. **Fall back to slug matching**: When back-references are missing, contain descriptions instead of file paths, or don't resolve to existing files, match documents by slug. Extract the slug from the filename (the part after the number-prefix and type — e.g. `auth` from `01-plan-auth.md`, `pivot` from `05-spec-pivot.md`) and group documents with the same slug into a chain.

4. **Handle partial chains**: Not every chain will be complete. A spec without a brief, or stories without a spec, are valid — present what exists.

5. **Present to user**: Show the discovered chains and individual documents. Use AskUserQuestion to let the user select which document to amend. Group by chain where possible, list orphan documents separately.

**Update progress file now** — write the full `.cpm-progress.md` with Step 1 summary before continuing.

### Step 2: Surgical Amendment

Read and amend the selected document.

1. **Read the document**: Read the selected file with the Read tool. Present a brief summary of its contents to the user — key sections, overall structure, what it covers.

2. **Gather changes**: Ask the user what they want to change. They describe modifications in natural language — additions, removals, rewording, structural changes. Use AskUserQuestion or direct conversation.

3. **Apply edits**: Use the Edit tool to make surgical changes to the document. Multiple edits are fine — apply them one at a time. Do NOT use the Write tool for amendments — Edit only, to minimise risk of accidental content loss.

4. **Save immediately**: Each Edit call saves to disk immediately. No content is held only in memory.

5. **Present change summary**: After all edits are applied, present a clear summary:
   - What changed (section-level, not line-level)
   - What the downstream implications are (which dependent documents might need updating)

**Update progress file now** — write the full `.cpm-progress.md` with Step 2 summary before continuing.

### Step 3: Cascading Update Facilitation

Walk downstream documents and facilitate updates. Skip this step if no downstream documents exist.

1. **Identify downstream documents**: Using the chain discovered in Step 1 (or built from the direct file path), find documents that depend on the one just amended:
   - If a brief was amended → its spec and stories are downstream
   - If a spec was amended → its stories are downstream
   - If stories were amended → no downstream documents (stories are leaf nodes)

2. **Walk in dependency order**: Process downstream documents one at a time, starting with the closest dependency (spec before stories).

3. **For each downstream document**:
   a. Read the document with the Read tool.
   b. Compare against the upstream changes made in Step 2. Identify sections that are affected — requirements that reference changed scope, stories that implement changed requirements, etc.
   c. Propose specific updates with clear rationale for each. Explain what changed upstream and how it affects this section.
   d. Gate each proposed change with AskUserQuestion:
      - **Apply this change** — Make the edit as proposed
      - **Modify the change** — Ask the user how to adjust, then apply their version
      - **Skip this change** — Leave this section as-is
   e. Apply approved or user-modified edits using the Edit tool (not Write).

4. **Preserve upstream work**: If the cascade fails midway (user exits, error occurs), all already-saved upstream edits are preserved — they were written to disk immediately in Step 2.

5. **Graceful skip**: If no downstream documents exist, skip this step entirely and proceed to Step 4.

**Update progress file now** — write the full `.cpm-progress.md` with Step 3 summary before continuing.

### Step 4: Task Impact Flagging

Identify tasks that may be affected by the changes. Skip this step if no tasks exist or if the stories doc wasn't changed.

1. **Check preconditions**: Call `TaskList` to see if any tasks exist. If none, skip this step. Also skip if the cascade in Step 3 didn't touch any stories doc (changes to briefs/specs that didn't cascade to stories won't affect tasks).

2. **Match affected stories to tasks**: For stories that were changed in Step 2 or Step 3:
   - Match by Task ID: look for `**Task ID**: {id}` fields in the stories doc and match against task IDs from TaskList.
   - Match by subject: fall back to matching story headings (`### {subject}`) against task subjects.

3. **Present the list**: Show the user which tasks may be affected by the pivot, with a brief note on what changed in the corresponding story. Do NOT automatically modify any tasks — present the information and let the user decide what action to take.

4. **Graceful skip**: If no tasks are matched, or if no stories were modified, skip this step silently.

**Update progress file now** — write the full `.cpm-progress.md` with Step 4 summary, then delete the progress file.

## State Management

Maintain `docs/plans/.cpm-progress.md` throughout the session for compaction resilience. This allows seamless continuation if context compaction fires mid-conversation.

**Create** the file before starting Step 1 (ensure `docs/plans/` exists). **Update** it after each step completes. **Delete** it only after all amended artifacts have been confirmed written — never before. If compaction fires between deletion and a pending write, all session state is lost.

Use the Write tool to write the full file each time (not Edit — the file is replaced wholesale). Format:

```markdown
# CPM Session State

**Skill**: cpm:pivot
**Step**: {N} of 4 — {Step Name}
**Target document**: {path to document being amended}
**Chain**: {brief → spec → stories paths, or "single document"}

## Completed Steps

### Step 1: Artefact Chain Discovery
{Summary — chains found, document selected for amendment}

### Step 2: Surgical Amendment
{Summary — what was changed, downstream implications identified}

### Step 3: Cascading Update Facilitation
{Summary — which downstream docs were updated, which changes were applied/skipped}

### Step 4: Task Impact Flagging
{Summary — affected tasks identified, user decisions}

{...include only completed steps...}

## Next Action
{What to do next}
```

## Graceful Degradation

- **No planning documents found**: Tell the user there's nothing to pivot and stop. Don't error.
- **Direct file path doesn't exist**: Tell the user the file wasn't found and stop.
- **Back-references don't resolve**: Fall back to slug matching. If neither works, present documents as orphans.
- **No downstream documents**: Skip cascade step, proceed to task flagging.
- **No tasks exist**: Skip task flagging, finish the workflow.
- **User exits mid-cascade**: Already-saved edits to the source document (and any already-cascaded documents) are preserved on disk.

## Guidelines

- **Lighter than re-running.** The whole point of pivot is speed. If amending a brief takes longer than re-running cpm:discover, the skill has failed.
- **Surgical edits only.** Always use Edit, never Write, for document amendments. This minimises risk of accidental content loss.
- **Human-in-the-loop for cascade.** Never auto-update downstream documents. Every downstream change goes through the user.
- **No auto-modification of tasks.** Flag affected tasks, present the information, let the user decide.
- **Preserve what's saved.** If anything goes wrong, edits already written to disk stay written. Never hold content only in memory.
