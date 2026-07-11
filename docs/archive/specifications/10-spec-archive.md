# Spec: CPM Archive Skill

**Date**: 2026-02-11
**Brief**: User description — add a CPM skill that archives old or dead documents

## Problem Summary

CPM generates planning artifacts across `docs/plans/`, `docs/specifications/`, `docs/stories/`, and `docs/retros/` over time. Completed or superseded documents accumulate and create noise in the working docs tree. A new `/cpm:archive` skill moves stale documents to `docs/archive/`, keeping active directories clean while preserving history.

## Functional Requirements

### Must Have
- Scan `docs/plans/`, `docs/specifications/`, `docs/stories/`, and `docs/retros/` for archive candidates
- Present candidates with staleness indicators and artifact chain grouping
- User-controlled selection — choose individually, select all, or skip. Never auto-archive
- Move selected documents to `docs/archive/` with mirrored subdirectory structure (e.g. `docs/archive/specifications/01-spec-foo.md`)
- When archiving one document, offer to archive the full artifact chain (all documents sharing the same slug across directories)

### Should Have
- Staleness heuristics to auto-flag likely-dead documents (see Architecture Decisions)
- Dry-run summary showing what will be moved before executing

### Won't Have (this iteration)
- Restore functionality
- Archive reason annotations on files
- Auto-archive triggered by skill completion
- Permanent deletion of documents

## Non-Functional Requirements

### Data Integrity
- Archive operations must be atomic per document. If a move fails mid-chain, report which files succeeded and which failed rather than leaving things in a silently inconsistent state.

## Architecture Decisions

### Archive Location Structure
**Choice**: Mirrored subdirectory structure under `docs/archive/`
**Rationale**: Preserves semantic grouping, avoids naming collisions between different document types sharing a number prefix, and makes the original location obvious for future restore
**Alternatives considered**: Flat `docs/archive/` directory — simpler but creates collision risk and poor scanability at scale

### Chain Detection Method
**Choice**: Slug matching on filenames
**Rationale**: CPM documents follow the pattern `{NN}-{type}-{slug}.md`. Extracting the slug (everything after `NN-type-`) and matching across directories is simple, reliable, and doesn't depend on document content format
**Alternatives considered**: Content reference parsing (following `**Brief**:` and `**Source**:` links) — more precise but fragile if formats vary or links are edited

### Staleness Heuristics
**Choice**: Four signals, no date-based heuristics
**Rationale**: Completion status is a reliable, objective indicator of staleness. Date-based signals produce false positives (a plan may legitimately sit for weeks)
**Alternatives considered**: Age-based thresholds — rejected as too noisy

The four signals:
1. **Stories all complete** — Every story in a stories doc has status Complete
2. **Orphaned plan** — A plan with no corresponding spec (slug not found in `docs/specifications/`)
3. **Completed retro** — A retro whose source stories doc has all stories Complete
4. **Spec fully implemented** — A spec whose corresponding stories doc has all stories Complete

## Scope

### In Scope
- Scanning four `docs/` subdirectories for candidates
- Staleness heuristic evaluation
- Chain grouping by slug
- User-controlled selection via AskUserQuestion
- Moving files to `docs/archive/{subdirectory}/` via Bash `mv`
- Dry-run summary before execution
- State management (`.cpm-progress.md`) for compaction resilience
- SKILL.md following existing CPM skill patterns

### Out of Scope
- `docs/library/` documents (managed separately via `/cpm:library`)
- Permanent deletion of any documents
- Automatic archiving without user confirmation
- Restore functionality
- Modifying document contents
- Git operations (user handles staging and commit)

### Deferred
- `/cpm:archive restore` — reverse operation to move documents back
- Pipeline integration — auto-suggest archive after `/cpm:retro` completes
- Archive manifest/index file
