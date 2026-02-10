# Spec: CPM Library System

**Date**: 2026-02-10
**Brief**: Party mode discussion — incorporating project artifacts into CPM

## Problem Summary

CPM operates as a closed artifact loop (discover → spec → stories → do → retro) with no mechanism to ingest existing project knowledge — architecture decisions, coding standards, security policies, glossaries. This means CPM skills plan and execute without awareness of constraints and conventions the team has already established. The library system introduces a convention-based reference directory, an intake skill for curating documents with structured metadata, and a retro write-back mechanism that turns the pipeline from linear into circular.

## Functional Requirements

### Must Have

- **`docs/library/` convention** — A known directory that all CPM consumer skills automatically check for reference material. If it doesn't exist, skills proceed silently.
- **Layered discovery protocol** — Skills check library in three passes: (1) glob filenames, (2) read front-matter/summary of scope-matching files, (3) deep-read selectively when the current task context demands it.
- **`/cpm:library` intake skill** — Accepts a file path or URL, copies the document into `docs/library/`, reads it, and generates YAML front-matter with structured metadata.
- **Front-matter schema** — Standardised YAML block on every library document: `title`, `source`, `added`, `last-reviewed`, `scope` (array of skill names), `summary` (CPM-oriented actionable distillation). All fields required.
- **Scope-based filtering** — Consumer skills only deep-read library documents whose `scope` array includes their skill name. A special value `all` matches every skill.
- **Transparency on ingestion** — When a skill reads library documents, it reports to the user which files it found and is using as context.

### Should Have

- **Retro write-back** — `/cpm:retro` appends observations to relevant library documents as clearly marked amendment blocks (`## Amendment` headings with date, source retro, and category). Updates `last-reviewed` in front-matter. Original content never modified.
- **Consolidation action** — `/cpm:library consolidate <file>` reads a document's original content plus all accumulated amendments, produces a reconciled version, and presents it to the user for approval before writing.
- **Auto-scope suggestion** — During intake, CPM analyses document content and suggests which skills it's relevant to, rather than requiring the user to pick from a raw list.

### Won't Have (this iteration)

- Non-markdown document support
- Automatic codebase scanning to populate library
- Cross-project library sharing
- Versioning/diff tracking beyond git
- Staleness warnings
- `/cpm:library list` and `/cpm:library remove` commands
- Subdirectory organisation within `docs/library/`

## Non-Functional Requirements

### Context Window Efficiency
The layered discovery protocol manages token cost. Filename globs are near-zero. Front-matter scans consume ~10 lines per document. Deep reads happen only when scope-matched and task-relevant. The front-matter summary is the primary triage mechanism — most skills should be able to work from it without reading the full document.

### Graceful Degradation
- Missing `docs/library/` directory: all consumer skills proceed silently, zero friction.
- Malformed or missing front-matter: skill falls back to filename-only context, never blocks.
- Unrecognised `scope` values: ignored, not errored.

### Compaction Resilience
Library discovery results (files found, files read, scope matches) are captured in the skill's progress file so post-compaction continuation doesn't re-scan.

### Consistency
Front-matter schema is identical across all library documents — same fields, same YAML structure, same date format (`YYYY-MM-DD`). Amendment blocks follow a consistent format (`## Amendment — {date} (via retro)`) so consolidation can parse them reliably.

## Architecture Decisions

### Front-Matter Schema
**Choice**: Six required YAML fields — `title`, `source`, `added`, `last-reviewed`, `scope`, `summary`. No optional fields.
**Rationale**: Every optional field creates inconsistency that consumers must handle. A minimal, all-required schema means consumers can always rely on every field being present. The `scope` array uses skill names as values (`discover`, `spec`, `stories`, `do`, `party`) plus an `all` shorthand.
**Alternatives considered**: A manifest file mapping paths to metadata (rejected — higher coupling, additional config file to maintain). Filename conventions as metadata (rejected — too limited, no room for summary or scope).

### Directory Structure
**Choice**: Flat `docs/library/` directory alongside existing CPM directories (`plans/`, `specifications/`, `stories/`, `retros/`). No numbered prefixes, no enforced naming.
**Rationale**: Library documents are a reference collection, not a sequence. Front-matter is the source of truth for metadata. Flat structure keeps the glob pattern simple and avoids category hierarchies CPM would need to understand.
**Alternatives considered**: Nested subdirectories by category (rejected — adds complexity, requires recursive glob, invites over-organisation). Separate config file pointing to scattered docs (rejected — convention over configuration is simpler).

### Consumer Skill Integration Pattern
**Choice**: A four-step library check preamble added to each consumer skill (discover, spec, stories, do, party): (1) glob filenames, (2) read front-matter and filter by scope, (3) report to user, (4) deep-read selectively during skill execution.
**Rationale**: Layered approach minimises token cost while keeping the user informed. Step 4 is contextual — the skill decides when to read based on what it's doing, not upfront.
**Alternatives considered**: Read all library docs upfront at skill start (rejected — wastes context window on irrelevant material). Only read when user explicitly requests (rejected — defeats the purpose of automatic context awareness).

### Retro Write-Back Format
**Choice**: `## Amendment` headings appended to document body with date, source retro path, and observation category. Front-matter `last-reviewed` updated. Original content never modified.
**Rationale**: Annotate-don't-overwrite preserves the document author's original work. Amendment headings are visually distinct and parseable for consolidation. Source attribution maintains traceability back to the retro that generated the observation.
**Alternatives considered**: Inline edits to original content (rejected — loses original intent, hard to audit). Separate amendment log file (rejected — splits context, harder for skills to discover).

## Scope

### In Scope
- `/cpm:library` skill with intake and consolidation actions
- `docs/library/` directory convention
- Front-matter schema definition and generation
- Library check preamble for five consumer skills (discover, spec, stories, do, party)
- Layered discovery protocol implementation
- Retro write-back with amendment format
- Auto-scope suggestion during intake

### Out of Scope
- Non-markdown document formats
- Automatic codebase scanning for library population
- Cross-project library sharing
- Version tracking beyond git
- Staleness warnings on old documents
- List and remove utility commands
- Subdirectory organisation
- TOC convention enforcement

### Deferred
- **Staleness awareness** — flagging documents not reviewed recently. `last-reviewed` field already supports it; trivial to add once core system exists.
- **List/remove commands** — utility actions for managing the library. Low complexity, add when needed.
- **Pivot integration** — `/cpm:pivot` could amend library docs. Evaluate after retro write-back proves useful.
