# Spec: Epic Hierarchy for CPM

**Date**: 2026-02-11
**Brief**: Party mode discussion — restructuring spec-to-stories hierarchy

## Problem Summary

CPM's current hierarchy has a specification producing a single "stories doc" that contains epics as section headers, stories as deliverables, and tasks as implementation steps. This inverts standard agile terminology — epics appear subordinate to stories — and forces a rigid 1:1 mapping between specs and work breakdown documents. The restructuring makes epics the top-level output: a spec produces one or more epic documents, each self-contained with its own stories and tasks, enabling independent tracking, prioritisation, and implementation.

## Functional Requirements

### Must Have
1. Epic documents replace stories documents — output path is `docs/epics/{nn}-epic-{slug}.md`
2. `cpm:stories` skill renamed to `cpm:epics` — directory moves from `cpm/skills/stories/` to `cpm/skills/epics/`, frontmatter name updates
3. Spec-to-epics is 1:many — `cpm:epics` can produce multiple epic files from a single spec
4. Epic doc format is self-contained with local numbering — `#` epic title, `##` stories, `###` tasks, story/task numbers local to the epic
5. `cpm:do` updated — references `docs/epics/`, heading-level matching updated for `##` stories and `###` tasks
6. `cpm:archive` updated — scans `docs/epics/` instead of `docs/stories/`, staleness heuristics adapted for epic format
7. `cpm:retro` updated — reads from `docs/epics/` instead of `docs/stories/`
8. `cpm:pivot` updated — references `docs/epics/` instead of `docs/stories/`
9. `cpm:spec` updated — suggests `/cpm:epics` instead of `/cpm:stories` as next step
10. `cpm:party` updated — offers `/cpm:epics` in pipeline handoff options
11. README updated — all references to `cpm:stories`, `docs/stories/`, pipeline diagram, and file tree reflect new naming
12. Cross-epic dependency convention — epic doc can declare `**Blocked by**: Epic {nn}-epic-{slug}`, blocking all stories in the dependent epic until the upstream epic is complete
13. Epic-level status tracking — each epic doc carries a top-level `**Status**:` field (Pending / In Progress / Complete) derived from its stories
14. `cpm:do` auto-discovery — when no path is given, auto-selects if only one epic has unblocked tasks; asks only when there's a genuine choice
15. Spec back-reference — each epic doc includes a `**Source spec**:` field linking to the specification that produced it

### Won't Have (this iteration)
- Migration of existing `docs/stories/` files to new format
- Sub-epic nesting (epics don't contain other epics)
- Cross-epic task-level dependencies (dependencies are epic-to-epic only)

## Non-Functional Requirements

### Usability
- Epic docs must be at least as scannable as current stories docs — the shifted heading hierarchy and removal of the grouping layer should simplify, not complicate
- Terminology consistency across all skills, README, and output templates — no lingering "stories doc" or `docs/stories/` references
- Existing `docs/stories/` files in projects already using CPM are not broken or deleted

### Reliability
- Compaction resilience pattern (`.cpm-progress.md`) continues unchanged, referencing `docs/epics/` paths
- Graceful degradation unchanged — `cpm:do` works without an epic doc, missing/malformed epic files don't crash workflows

## Architecture Decisions

### Skill Naming
**Choice**: Rename `cpm:stories` to `cpm:epics`. Directory moves from `cpm/skills/stories/` to `cpm/skills/epics/`.
**Rationale**: Skill name matches the output artifact. Pipeline reads naturally: discover → spec → epics → do.
**Alternatives considered**: Keeping `cpm:stories` (rejected — misleading when the output is epic documents).

### Epic Document Heading Structure
**Choice**: Shift headings up one level. `#` is the epic title, `##` for stories, `###` for tasks.
**Rationale**: The document *is* the epic, so it gets `h1`. Removes the redundant `## Epic:` grouping header. Tasks move from `h4` to `h3`, improving visibility.
**Alternatives considered**: Keeping current depths with `h1` unused (rejected — wastes the natural hierarchy and keeps tasks at hard-to-scan `h4`).

### cpm:do Epic Discovery
**Choice**: Smart pick — auto-select if only one epic has unblocked tasks; ask the user only when there's a genuine choice. Explicit file path always takes precedence.
**Rationale**: Saves the user a question in the common case (working through one epic at a time) while preserving flexibility.
**Alternatives considered**: Always asking (rejected — unnecessary friction when there's only one option), most-recently-modified (rejected — recency doesn't correlate with what should be worked on next).

### Cross-Epic Dependencies
**Choice**: Epic-level only, referencing by filename slug. `**Blocked by**: Epic {nn}-epic-{slug}` blocks all stories in the dependent epic.
**Rationale**: Coarse-grained dependency keeps the model simple. Fine-grained cross-epic story deps would indicate the epics are too tightly coupled and should be merged.
**Alternatives considered**: Story-level cross-references across epics (rejected — adds complexity, signals a design problem).

## Scope

### In Scope
- `cpm/skills/epics/SKILL.md` — Full rewrite of current `cpm/skills/stories/SKILL.md`
- `cpm/skills/do/SKILL.md` — Smart discovery, updated paths, updated heading matching, cross-epic awareness
- `cpm/skills/archive/SKILL.md` — Updated scan paths and staleness heuristics
- `cpm/skills/retro/SKILL.md` — Updated path references
- `cpm/skills/pivot/SKILL.md` — Updated path references
- `cpm/skills/spec/SKILL.md` — Updated next-step suggestion
- `cpm/skills/party/SKILL.md` — Updated pipeline handoff
- `cpm/README.md` — All references, pipeline diagram, file tree
- Directory rename: `cpm/skills/stories/` → `cpm/skills/epics/`

### Out of Scope
- Migration of existing `docs/stories/` files
- Sub-epic nesting
- Cross-epic task-level dependencies
- New features in any skill beyond what's needed for the restructure
- Changes to `cpm:discover` (produces briefs, doesn't reference stories/epics)
- Plugin manifest or hooks changes

### Deferred
- Tooling to migrate existing `docs/stories/` to `docs/epics/` format
- `cpm:do` working across multiple epics in a single session
