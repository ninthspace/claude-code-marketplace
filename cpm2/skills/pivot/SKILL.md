---
name: cpm2:pivot
description: Course correction. Revisit any planning artefact, surgically amend it, and cascade changes through downstream documents. Triggers on "/cpm2:pivot".
---

# Course Correction

Revisit any planning artefact (problem brief, product brief, ADR, spec, or epic), make surgical edits, and walk downstream documents through guided updates. Pivot is lighter than re-running the original skill — amend what exists rather than starting over.

## Input

Check for input in this order:

1. If `$ARGUMENTS` is a file path (e.g. `docs/plans/01-plan-auth.md`), use that as the target document. Skip artefact chain discovery — go straight to the amendment workflow.
2. If no path given, run artefact chain discovery (see below) and present the user with a selection.
3. If no planning documents exist anywhere, tell the user there's nothing to pivot and stop.

## Process

**State tracking**: Create the progress file before Step 1 and update it after each step completes. See State Management below for the format and rationale. Delete the file once the workflow has finished (or after early exit).

### Retro Check (Startup)

Follow the shared **Retro Awareness** procedure before beginning Step 1.

**Retro incorporation** (this skill):
- **Scope surprises**: Inform Step 3 (cascading update facilitation) — past surprises predict which downstream documents the current pivot is most likely to affect.
- **Criteria gaps**: Inform Step 2 (surgical amendment) — gaps caught in past retros may be the same gaps the current pivot is trying to address; surface them to the user.
- **Codebase discoveries**: Inform Step 4 (task impact flagging) — surfaced patterns may identify additional tasks affected beyond the obvious matches.

### Step 1: Artefact Chain Discovery

Discover existing planning artefacts and their relationships. Skip this step if `$ARGUMENTS` provided a direct file path.

1. **Glob all five planning directories**:
   - `docs/plans/[0-9]*-plan-*.md` (problem briefs from cpm2:discover)
   - `docs/briefs/[0-9]*-brief-*.md` (product briefs from cpm2:brief)
   - `docs/architecture/[0-9]*-adr-*.md` (ADRs from cpm2:architect)
   - `docs/specifications/[0-9]*-spec-*.md` (specs from cpm2:spec)
   - `docs/epics/[0-9]*-epic-*.md` (epics from cpm2:epics)

2. **Build dependency chains**: For each document found, read the first 10 lines and look for back-reference fields:
   - Product briefs have `**Source**:` — may contain a path to a problem brief.
   - ADRs have `**Source**:` — may contain a path to a product brief or problem brief.
   - Specs have `**Brief**:` — may contain a file path to a problem brief or product brief, or a description. Only treat it as a chain link if the value is a valid file path that exists on disk.
   - Epics have `**Source spec**:` — a file path to the source spec. Verify the file exists before treating it as a chain link. Multiple epic docs may share the same source spec (1:many).
   - Problem briefs are root nodes with no upstream reference.

   The full cascade chain is: problem brief → product brief → ADRs → spec → epics. Not every chain will have all levels. Use verified file-path references to group documents into chains.

3. **Fall back to slug matching**: When back-references are missing, contain descriptions instead of file paths, or fail to resolve to existing files, match documents by slug. Extract the slug from the filename (the part after the number-prefix and type — e.g. `auth` from `01-plan-auth.md`, `pivot` from `05-spec-pivot.md`) and group documents with the same slug into a chain.

4. **Handle partial chains**: Not every chain will be complete. A spec without a brief, or epics without a spec, are valid — present what exists.

5. **Present to user**: Show the discovered chains and individual documents. Use AskUserQuestion to let the user select which document to amend. Group by chain where possible, list orphan documents separately.

### Step 2: Surgical Amendment

Read and amend the selected document.

1. **Read the document**: Read the selected file with the Read tool. Present a brief summary of its contents to the user — key sections, overall structure, what it covers.

2. **Gather changes**: Ask the user what they want to change. They describe modifications in natural language — additions, removals, rewording, structural changes. Use AskUserQuestion or direct conversation.

3. **Apply edits**: Use the Edit tool to make surgical changes to the document. Multiple edits are fine — apply them one at a time. Do NOT use the Write tool for amendments — Edit only, to minimise risk of accidental content loss.

4. **Save immediately**: Each Edit call saves to disk immediately. No content is held only in memory.

5. **Present change summary**: After all edits are applied, present a clear summary:
   - What changed (section-level, not line-level)
   - What the downstream implications are (which dependent documents might need updating)

### Step 3: Cascading Update Facilitation

Walk downstream documents and facilitate updates. Skip this step if no downstream documents exist.

#### Completion-Aware Preamble

Before walking the cascade, check whether all downstream epic documents are fully complete:

1. **Detect completion**: For each downstream epic doc, scan for completion markers — `[x]` checkboxes on all story tasks, or `**Status**:` fields containing "done" or "complete" (case-insensitive). An epic is fully complete when every story within it is marked complete.

2. **All epics complete — ask intent**: If every downstream epic is fully complete, the user is pivoting a spec whose work has already been delivered. Use AskUserQuestion to determine intent:
   - **Amend the historical record** — Continue with the normal cascade. The user wants to correct or update the existing documents to reflect reality or clarify what was built.
   - **Pivot forward (new epics)** — Skip the cascade entirely. The completed epics stay untouched as a historical record of what shipped. Instead, offer to hand off to `cpm2:epics` with the amended spec as input, generating fresh epic docs for the new work.
   - **Raise a new spec** — Skip the cascade entirely. The amendment is substantial enough that it warrants a fresh specification rather than new epics from the amended document. Hand off to `cpm2:spec` with the amended spec as input context. Only offer this option when the amended document is a spec (not a brief or ADR).

   If the user chooses "Pivot forward", save the progress file, then tell the user to run `/cpm2:epics {amended-spec-path}` to generate new epics. If the user chooses "Raise a new spec", save the progress file, then tell the user to run `/cpm2:spec {amended-spec-path}` to create a new specification. In both cases, proceed directly to Step 4 (skip the cascade walk below).

3. **Partial or no completion**: If some epics are incomplete, or completion markers are absent, proceed with the normal cascade below. Individual story completion is handled per-story during the walk.

#### Cascade Walk

1. **Identify downstream documents**: Using the chain discovered in Step 1 (or built from the direct file path), find documents that depend on the one just amended:
   - If a problem brief was amended → its product briefs, ADRs, specs, and epics are downstream
   - If a product brief was amended → its ADRs, specs, and epics are downstream
   - If an ADR was amended → specs and epics that reference it are downstream
   - If a spec was amended → its epics are downstream
   - If an epic was amended → no downstream documents (epics are leaf nodes)

2. **Walk in dependency order**: Process downstream documents one at a time, starting with the closest dependency (spec before epics).

3. **For each downstream document**:
   a. Read the document with the Read tool.
   b. **Detect per-story completion**: For epic documents, check each story for completion markers — `[x]` on all task checkboxes, or a `**Status**:` field containing "done" or "complete" (case-insensitive). If neither marker is present, treat the story as in-progress.
   c. Compare against the upstream changes made in Step 2. Identify sections that are affected — requirements that reference changed scope, epic stories that implement changed requirements, etc.
   d. **Flag completed stories**: When proposing a change to a story that is marked complete, prepend a visible warning: "⚠️ This story is marked complete — editing it changes the record of delivered work." This gives the user clear context for their apply/skip decision.
   e. Propose specific updates with clear rationale for each. Explain what changed upstream and how it affects this section.
   f. Gate each proposed change with AskUserQuestion:
      - **Apply this change** — Make the edit as proposed
      - **Modify the change** — Ask the user how to adjust, then apply their version
      - **Skip this change** — Leave this section as-is
   g. Apply approved or user-modified edits using the Edit tool (not Write).

4. **Preserve upstream work**: If the cascade fails midway (user exits, error occurs), all already-saved upstream edits are preserved — they were written to disk immediately in Step 2.

5. **Graceful skip**: If no downstream documents exist, skip this step entirely and proceed to Step 4.

6. **Coverage matrix invalidation**: After applying changes to an epic doc, check for a companion coverage matrix at `docs/epics/{nn}-coverage-{slug}.md` (same number and slug as the epic). If it exists and the cascade modified any story acceptance criteria in the epic doc, read the coverage matrix and clear the `✓` from the Verified column for rows whose "Story Criterion (verbatim)" text was changed by the cascade. Rows whose criteria were not modified retain their `✓` status. Use the Edit tool to replace `| ✓ |` with `| |` for affected rows. If no coverage matrix exists, skip this step.

### Step 4: Task Impact Flagging

Identify tasks that may be affected by the changes. Skip this step if no tasks exist or if no epic doc was changed.

1. **Check preconditions**: Call `TaskList` to see if any tasks exist. If none, skip this step. Also skip if the cascade in Step 3 didn't touch any epic doc (changes to briefs/specs that didn't cascade to epics won't affect tasks).

2. **Match affected stories to tasks**: For stories that were changed in Step 2 or Step 3:
   - Match by Task ID: look for `**Task ID**: {id}` fields in the epic doc and match against task IDs from TaskList.
   - Match by subject: fall back to matching story headings (`### {subject}`) against task subjects.

3. **Present the list**: Show the user which tasks may be affected by the pivot, with a brief note on what changed in the corresponding story. Do NOT automatically modify any tasks — present the information and let the user decide what action to take.

4. **Graceful skip**: If no tasks are matched, or if no epic stories were modified, skip this step silently.

### Step 5: Retro Handoff (optional)

After Step 4, offer to capture the lesson behind this pivot. Pivots almost always reflect a learning worth feeding forward — surfacing the offer here prevents the loop from closing prematurely.

Use AskUserQuestion: "This pivot likely reflects a learning. Run `/cpm2:retro` to capture it for next time?"
- **Run retro now** — Hand off to `/cpm2:retro {amended-source-path}`. The retro skill will read the amended artefact and synthesise observations.
- **Skip** — Proceed to workflow completion. The user can run retro later via `/cpm2:retro` if desired.

If the user chose "Pivot forward (new epics)" or "Raise a new spec" in Step 3, skip this step entirely — those branches have their own handoffs.

*Workflow complete — delete the progress file.*

## State Management

Follow the shared **Progress File Management** procedure.

**Lifecycle**:
- **Create**: before starting Step 1 (ensure `docs/plans/` exists).
- **Update**: after each step completes.
- **Delete**: only after all amended artifacts have been confirmed written.

**Format**:

```markdown
# CPM Session State

**Skill**: cpm2:pivot
**Step**: {N} of 4 — {Step Name}
**Target document**: {path to document being amended}
**Chain**: {brief → spec → epics paths, or "single document"}

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

Every scenario below specifies an explicit action sequence ending with a visible result. No silent fallbacks.

- **No planning documents found** → **Action**: Stop the skill. **Result**: Report to the user: "No planning documents found in docs/ — nothing to pivot."

- **Direct file path doesn't exist** → **Action**: Stop the skill. **Result**: Report to the user: "File not found at {path} — verify the path and try again."

- **Back-references don't resolve** → **Action**: Fall back to slug matching (match the slug portion of the filename). If slug matching also fails, present all documents as orphans — list them without resolved upstream/downstream links. **Result**: Report to the user: "Back-references could not be resolved for {N} documents — showing them as unlinked. Cascade may be incomplete."

- **No downstream documents** → **Action**: Skip the cascade step. Proceed directly to task flagging. **Result**: Report to the user: "No downstream documents found — skipping cascade."

- **No tasks exist** → **Action**: Skip the task flagging step. Finish the workflow with the source and cascade edits already completed. **Result**: Report to the user: "No Claude Code tasks found — skipping task flagging."

- **User exits mid-cascade** → **Action**: Preserve all edits already written to disk (source document and any cascaded documents). Stop the workflow without rolling back. **Result**: Report to the user: "Cascade stopped — {N} documents already updated are preserved on disk."

## Guidelines

- **Lighter than re-running, but correct.** Pivot should be more efficient than re-running a full skill — but not at the cost of correctness. Surgical edits must be precise and verified. Follow the shared Implementation Guidelines: use the Edit tool file-by-file (no bulk `sed`/`perl`), and prefer clarity and correctness over speed.
- **Surgical edits only.** Always use Edit for document amendments (Write risks accidental content loss).
- **Human-in-the-loop for cascade.** Every downstream change goes through the user for approval.
- **No auto-modification of tasks.** Flag affected tasks, present the information, let the user decide.
- **Preserve what's saved.** If anything goes wrong, edits already written to disk stay written. Always persist content to disk immediately.
