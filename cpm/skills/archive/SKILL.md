---
name: archive
description: Archive old or completed planning documents. Scans for stale artifacts, groups them by chain, and moves them to docs/archive/ with user confirmation. Triggers on "/cpm:archive".
---

# Archive Planning Documents

Move completed or stale planning artifacts out of the active `docs/` directories into `docs/archive/`, keeping the working tree clean while preserving history.

## Input

Parse `$ARGUMENTS` to determine behavior:

1. If `$ARGUMENTS` is a file path, archive that specific document (and offer to archive its chain).
2. If no arguments, scan all planning directories and present candidates.

## Process

**State tracking**: Create the progress file before Step 1 and update it after each step completes. See State Management below for the format and rationale. Delete the file once all archive operations have completed.

### Stale-Progress Check (Startup)

Follow the shared **Stale-Progress Check** procedure (from the CPM Shared Skill Conventions loaded at session start).

### Step 1: Scan and Discover

Scan the four planning directories for documents and group them into artifact chains.

1. **Glob** the following patterns:
   - `docs/plans/[0-9]*-plan-*.md`
   - `docs/specifications/[0-9]*-spec-*.md`
   - `docs/epics/[0-9]*-epic-*.md`
   - `docs/epics/[0-9]*-coverage-*.md`
   - `docs/retros/[0-9]*-retro-*.md`

   Coverage docs live alongside epics in `docs/epics/` (one coverage doc per epic, sharing the epic's `{parent}-{seq}` prefix and slug). They are **not** independent chain members — each attaches to its sibling epic (see grouping below) and moves with it. A coverage doc must never be left behind when its epic is archived.

   **Explicitly exclude** `docs/library/` — library documents have their own lifecycle via `/cpm:library`.

2. **Extract slugs**: For each document found, extract the slug from the filename by anchoring on the **type identifier**, not on positional numerics. The slug is everything after the type identifier (`-plan-`, `-spec-`, `-epic-`, `-retro-`, `-review-`, `-adr-`, `-quick-`, `-discussion-`, `-coverage-`, `-brief-`). This rule is shape-agnostic — it works for both legacy flat filenames (`{nn}-{type}-{slug}.md`) and new two-part epic filenames (`{parent}-{seq}-epic-{slug}.md`). For example:
   - `01-plan-compaction-resilience.md` → slug: `compaction-resilience` (legacy flat)
   - `03-spec-party-mode.md` → slug: `party-mode` (legacy flat)
   - `01-retro-auth.md` → slug: `auth` (legacy flat)
   - `28-01-epic-doc-numbering-scheme.md` → slug: `doc-numbering-scheme` (new two-part epic)
   - `28-01-coverage-doc-numbering-scheme.md` → slug: `doc-numbering-scheme` (new two-part coverage)

   Always find the type identifier substring first, then take everything after it as the slug — the numeric prefix width varies (one or two integer fields depending on artifact type and shape).

3. **Group into chains**: Build chains from **back-reference links first**, falling back to slug only where no back-reference exists. Slug matching alone is unreliable here: an epic almost always carries its own topic slug (`04-epic-product-brief-skill` → slug `product-brief-skill`), which does **not** match its spec's slug (`14-spec-cpm-lifecycle-expansion`). Never rely on slug equality to bind a spec to its epics.

   Resolve links in this order:

   1. **Epic → spec (primary)**: Read the `**Source spec**:` field from each epic doc's header. The epic belongs to the chain of the spec it names, **regardless of slug**. Every epic naming the same spec joins that spec's chain (1:many — a single spec may own many epics). This is the authoritative spec↔epic link; do not second-guess it by slug.
   2. **Coverage → epic**: Attach each `*-coverage-*.md` doc to its sibling epic — the epic sharing the same `{parent}-{seq}` numeric prefix (two-part scheme) or the same slug (legacy flat). A coverage doc is part of whatever chain its epic is in and is always moved with it.
   3. **Retro → epic**: Link a retro to its epic(s) via the retro's `**Source**:` back-reference if present, otherwise by slug.
   4. **Plan → spec, and slug fallback**: Match plans to specs by slug (plans and specs in this repo share slugs). Use slug matching as a fallback for any document that has no usable back-reference.

   A chain is the transitive closure of these links — the spec, its plan (if any), all epics that name it, every coverage doc attached to those epics, and any retros for those epics. For example the `cpm-lifecycle-expansion` chain is:
   - `docs/specifications/14-spec-cpm-lifecycle-expansion.md`
   - `docs/epics/04-epic-product-brief-skill.md` (+ its coverage doc, if any)
   - `docs/epics/05-epic-architecture-exploration-skill.md` (+ coverage)
   - `docs/epics/06-epic-communication-and-templates.md` (+ coverage)
   - `docs/epics/07-epic-existing-skill-updates.md` (+ coverage)

   Not every chain will be complete — a spec without a plan, or epics without a retro, are normal.

4. If `$ARGUMENTS` was a file path, extract its slug and filter to only that chain. If no other chain members exist, the chain contains only the specified file.

5. If no documents are found in any directory, tell the user there's nothing to archive and stop.

### Step 2: Evaluate Staleness

For each chain (or individual document), evaluate staleness using five signals. A chain is flagged as stale if **any** signal fires. Read documents with the Read tool as needed to check status fields.

**Signal 1 — Epic complete**: Read the epic doc(s) in the chain. If every `## {Story Title}` heading has `**Status**: Complete` (or `Done`) and the epic-level `**Status**:` is `Complete` (or `Done`), the epic is done. When a chain has multiple epic docs (1:many from a single spec), all must be complete for this signal to fire. Flag the chain as stale.

**Signal 2 — Orphaned plan**: A plan document whose slug has no matching spec in `docs/specifications/`. This suggests the plan was abandoned or superseded. Flag the plan as stale.

**Signal 3 — Completed retro**: A retro document whose source epic doc(s) (matched by slug or `**Source**:` back-reference) all have status Complete. The retro has served its purpose. Flag the retro as stale.

**Signal 4 — Spec fully implemented**: A spec whose matching epic doc(s) (linked via `**Source spec**:` back-references in the epic docs) are all *resolved* — status `Complete`/`Done`, or retired (`Superseded` / `Withdrawn`). The spec has been fully delivered or its work abandoned. Flag the spec as stale.

**Signal 5 — Retired epic**: An epic whose epic-level `**Status**:` is `Superseded` or `Withdrawn` — a terminal, user-set status marking work no longer needed (superseded = replaced by other work; withdrawn = dropped). The epic is retired and ready to sweep out of the active tree regardless of its stories' individual statuses.

What this signal flags depends on the rest of the chain — a retired epic must never drag active work or its spec into the archive:

- **Whole chain resolved** — if *every* epic on the spec is resolved, Signal 4 also fires; the spec and all its epics archive together as one chain, as usual.
- **Mixed chain** (the spec still has *active*, unresolved epics) — flag **only the retired epic and its coverage doc** as a standalone archivable unit. The spec and the live sibling epics stay in place. Signal 4 does *not* fire here, so the spec is never pulled in.

For each chain, record which signals fired. Chains with no signals are still presented as candidates — the user may want to archive them for other reasons — but they are not flagged.

### Step 3: Present Candidates

Present the discovered chains and documents to the user, grouped by chain with staleness indicators.

1. **Format the candidate list**: For each chain, show:
   - The slug name as the chain heading
   - All documents in the chain (plan → spec → epics → retro order), showing each epic's attached coverage doc beneath it
   - Which staleness signals fired (if any), as brief labels: `[epic complete]`, `[orphaned plan]`, `[completed retro]`, `[spec implemented]`, `[epic superseded]`, `[epic withdrawn]`
   - Chains with staleness signals should be presented first
   - **Mixed chain with a retired epic** (Signal 5, mixed case): present the retired epic and its coverage doc as their *own* archivable item nested under the chain — labelled `[epic superseded]` / `[epic withdrawn]` — clearly distinct from archiving the whole chain, which stays available (and unflagged) because its spec still has live epics.

2. **Dry-run summary**: Before asking for selection, show a summary: "Found {N} artifact chains containing {M} total documents. {X} chains flagged as stale."

3. **User selection**: Use AskUserQuestion to let the user choose:
   - **Archive all flagged chains** — Move all documents in chains that have at least one staleness signal
   - **Select individually** — Walk through each chain one at a time, asking archive or skip for each
   - **Skip** — Exit the skill with no changes

4. **Individual selection flow**: If the user chose "Select individually", present each chain with AskUserQuestion:
   - **Archive this chain** — Move all documents in this chain
   - **Skip this chain** — Leave it in place

   For a mixed chain carrying a retired epic (Signal 5, mixed case), offer the retired epic as its own choice instead of forcing the whole chain:
   - **Archive just the retired epic** — Move only that epic doc and its coverage doc; leave the spec and live sibling epics in place
   - **Skip** — Leave it in place

5. Build the final list of files to move based on user selections.

*Progress note: capture the selected files list in the Step 3 summary.*

### Step 4: Archive Execution

Move the selected files to `docs/archive/` with mirrored subdirectory structure.

1. **Completeness guard**: Before moving anything, confirm each selected chain is whole. For every chain being archived, verify its source spec and every coverage doc attached to its epics are in the move list. If a completed epic chain would be archived while its source spec or a sibling coverage doc is left behind, flag it to the user and offer to include the missing file(s). Never silently orphan a spec or coverage doc.

   **Exception — standalone retired-epic move** (Signal 5, mixed chain): when the selection is a single retired epic (plus its coverage doc) whose spec still has active epics, the guard does *not* require the spec. The spec must be **left in place** — it still owns live work. Do pull the retired epic's own coverage doc along with it, but never the spec or the live sibling epics.

2. **Create directories**: For each subdirectory needed (e.g. `docs/archive/plans/`, `docs/archive/specifications/`), run `mkdir -p` via Bash to ensure the target directory exists. Coverage docs mirror to `docs/archive/epics/` alongside their epic.

3. **Move files**: For each selected file, run `mv {source} {target}` via Bash. The target path mirrors the source: `docs/specifications/01-spec-foo.md` → `docs/archive/specifications/01-spec-foo.md`.

4. **Track results**: Record success or failure for each file. If a move fails:
   - Continue with the remaining files (always complete the batch)
   - Record the error for the failed file

5. **Report results**: Present a summary to the user:
   - How many files were moved successfully
   - Which files failed and why (if any)
   - The archive paths where files were moved

*Workflow complete — delete the progress file.*

## Output

Files are moved to `docs/archive/{subdirectory}/` preserving the mirrored directory structure. No output document is generated — the archive operation itself is the output.

## State Management

Follow the shared **Progress File Management** procedure.

**Lifecycle**:
- **Create**: before starting Step 1 (ensure `docs/plans/` exists).
- **Update**: after each step completes.
- **Delete**: only after all archive operations have completed.

**Format**:

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

- **User controls everything.** Every move requires explicit user selection — always wait for confirmation.
- **Chains over individuals.** When archiving one document, always offer to archive its full artifact chain.
- **Back-references bind, not slugs.** Spec↔epic links come from the epic's `**Source spec**:` field; epic slugs deliberately differ from their spec's slug. A spec and its coverage docs must never be orphaned when their epics are archived.
- **Non-destructive.** Always move, preserving files under `docs/archive/`.
- **Report failures.** If a move fails mid-chain, report which succeeded and which failed.
