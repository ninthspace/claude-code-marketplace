---
name: cpm:archive
description: Archive old or completed planning documents. Scans for stale artifacts, groups them by chain, and moves them to docs/archive/ with user confirmation. Triggers on "/cpm:archive".
---

# Archive Planning Documents

Move completed or stale planning artifacts out of the active `docs/` directories into `docs/archive/`, keeping the working tree clean while preserving history.

## Input

Parse `$ARGUMENTS` to determine behavior:

1. If `$ARGUMENTS` is a file path, archive that specific document (and offer to archive its chain).
2. If no arguments, scan all planning directories and present candidates.

## Process

**State tracking**: Before starting Step 1, create the progress file (see State Management below). Each step below ends with a mandatory progress file update — do not skip it. After completing all archive operations, delete the file.

### Step 1: Scan and Discover

Scan the four planning directories for documents and group them into artifact chains.

1. **Glob** the following patterns:
   - `docs/plans/[0-9]*-plan-*.md`
   - `docs/specifications/[0-9]*-spec-*.md`
   - `docs/epics/[0-9]*-epic-*.md`
   - `docs/retros/[0-9]*-retro-*.md`

   **Explicitly exclude** `docs/library/` — library documents have their own lifecycle via `/cpm:library`.

2. **Extract slugs**: For each document found, extract the slug from the filename. The slug is everything after the number-prefix and type identifier: `{NN}-{type}-{slug}.md`. For example:
   - `01-plan-compaction-resilience.md` → slug: `compaction-resilience`
   - `03-spec-party-mode.md` → slug: `party-mode`
   - `01-retro-auth.md` → slug: `auth`

3. **Group into chains**: Match documents across directories by slug. A chain is the set of all documents sharing the same slug. For example, slug `compaction-resilience` might have:
   - `docs/plans/01-plan-compaction-resilience.md`
   - `docs/specifications/01-spec-compaction-resilience.md`
   - `docs/epics/01-epic-compaction-resilience.md`

   A chain may contain multiple epic docs when a single spec produced several epics (1:many). To discover these, read the `**Source spec**:` field from each epic doc's header and group epic docs that share the same source spec into the same chain.

   Not every chain will be complete — a spec without a plan, or epics without a retro, are normal.

4. If `$ARGUMENTS` was a file path, extract its slug and filter to only that chain. If no other chain members exist, the chain contains only the specified file.

5. If no documents are found in any directory, tell the user there's nothing to archive and stop.

**Update progress file now** — write the full `.cpm-progress.md` with Step 1 summary before continuing.

### Step 2: Evaluate Staleness

For each chain (or individual document), evaluate staleness using four signals. A chain is flagged as stale if **any** signal fires. Read documents with the Read tool as needed to check status fields.

**Signal 1 — Epic complete**: Read the epic doc(s) in the chain. If every `## {Story Title}` heading has `**Status**: Complete` and the epic-level `**Status**:` is `Complete`, the epic is done. When a chain has multiple epic docs (1:many from a single spec), all must be complete for this signal to fire. Flag the chain as stale.

**Signal 2 — Orphaned plan**: A plan document whose slug has no matching spec in `docs/specifications/`. This suggests the plan was abandoned or superseded. Flag the plan as stale.

**Signal 3 — Completed retro**: A retro document whose source epic doc(s) (matched by slug or `**Source**:` back-reference) all have status Complete. The retro has served its purpose. Flag the retro as stale.

**Signal 4 — Spec fully implemented**: A spec whose matching epic doc(s) (linked via `**Source spec**:` back-references in the epic docs) all have status Complete. The spec has been fully delivered. Flag the spec as stale.

For each chain, record which signals fired. Chains with no signals are still presented as candidates — the user may want to archive them for other reasons — but they are not flagged.

**Update progress file now** — write the full `.cpm-progress.md` with Step 2 summary before continuing.

### Step 3: Present Candidates

Present the discovered chains and documents to the user, grouped by chain with staleness indicators.

1. **Format the candidate list**: For each chain, show:
   - The slug name as the chain heading
   - All documents in the chain (plan → spec → epics → retro order)
   - Which staleness signals fired (if any), as brief labels: `[epic complete]`, `[orphaned plan]`, `[completed retro]`, `[spec implemented]`
   - Chains with staleness signals should be presented first

2. **Dry-run summary**: Before asking for selection, show a summary: "Found {N} artifact chains containing {M} total documents. {X} chains flagged as stale."

3. **User selection**: Use AskUserQuestion to let the user choose:
   - **Archive all flagged chains** — Move all documents in chains that have at least one staleness signal
   - **Select individually** — Walk through each chain one at a time, asking archive or skip for each
   - **Skip** — Don't archive anything, exit the skill

4. **Individual selection flow**: If the user chose "Select individually", present each chain with AskUserQuestion:
   - **Archive this chain** — Move all documents in this chain
   - **Skip this chain** — Leave it in place

5. Build the final list of files to move based on user selections.

**Update progress file now** — write the full `.cpm-progress.md` with Step 3 summary (selected files list) before continuing.

### Step 4: Archive Execution

Move the selected files to `docs/archive/` with mirrored subdirectory structure.

1. **Create directories**: For each subdirectory needed (e.g. `docs/archive/plans/`, `docs/archive/specifications/`), run `mkdir -p` via Bash to ensure the target directory exists.

2. **Move files**: For each selected file, run `mv {source} {target}` via Bash. The target path mirrors the source: `docs/specifications/01-spec-foo.md` → `docs/archive/specifications/01-spec-foo.md`.

3. **Track results**: Record success or failure for each file. If a move fails:
   - Continue with the remaining files (don't abort the batch)
   - Record the error for the failed file

4. **Report results**: Present a summary to the user:
   - How many files were moved successfully
   - Which files failed and why (if any)
   - The archive paths where files were moved

**Update progress file now** — write the full `.cpm-progress.md` with Step 4 summary, then delete the progress file.

## Output

Files are moved to `docs/archive/{subdirectory}/` preserving the mirrored directory structure. No output document is generated — the archive operation itself is the output.

## State Management

Maintain `docs/plans/.cpm-progress.md` throughout the session for compaction resilience. This allows seamless continuation if context compaction fires mid-conversation.

**Create** the file before starting Step 1 (ensure `docs/plans/` exists). **Update** it after each step completes. **Delete** it only after all archive operations have completed — never before. If compaction fires between deletion and a pending write, all session state is lost.

Use the Write tool to write the full file each time (not Edit — the file is replaced wholesale). Format:

```markdown
# CPM Session State

**Skill**: cpm:archive
**Step**: {N} of 4 — {Step Name}

## Completed Steps

### Step 1: Scan and Discover
{Summary — chains found, document counts per directory, slugs identified}

### Step 2: Evaluate Staleness
{Summary — which chains flagged, which signals fired}

### Step 3: Present Candidates
{Summary — user selections, files queued for archiving}

### Step 4: Archive Execution
{Summary — files moved, successes, failures}

{...include only completed steps...}

## Next Action
{What to do next}
```

## Guidelines

- **User controls everything.** Never auto-archive. Every move requires explicit user selection.
- **Chains over individuals.** When archiving one document, always offer to archive its full artifact chain.
- **Non-destructive.** Move, never delete. Files remain accessible under `docs/archive/`.
- **Report failures.** If a move fails mid-chain, report which succeeded and which failed.
