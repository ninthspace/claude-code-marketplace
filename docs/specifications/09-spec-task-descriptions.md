# Spec: Task Descriptions in Stories

**Date**: 2026-02-11
**Brief**: Party mode discussion — task titles insufficient after context clear

## Problem Summary

The `cpm:stories` skill creates tasks with titles only. In-session this works because the implementer has residual context from the breakdown conversation. After a context clear (compaction or new session), `cpm:do` must reconstruct task scope via a three-hop lookup: task title → parent story's acceptance criteria → linked spec. This gap is sharpest when a story has multiple tasks that divide its acceptance criteria between them — the title alone doesn't clarify which criteria each task covers. Adding an optional one-sentence description to tasks during breakdown eliminates this ambiguity and makes the stories doc self-contained at both the story and task level.

## Functional Requirements

### Must Have

- **Task description field in stories doc format** — Tasks (`####` headings) gain an optional `**Description**:` field, one sentence, placed after the `**Task**:` line and before `**Task ID**:`. The field scopes the task within its parent story — clarifying which acceptance criteria or concern the task addresses.
- **Description generation in `cpm:stories` Step 3b** — When breaking stories into tasks, write a description for each task that clarifies its scope within the parent story. Descriptions should say which acceptance criteria or concern the task addresses, not restate the spec.
- **Description consumption in `cpm:do` Step 1** — When loading a task, `cpm:do` reads the description from the stories doc alongside the title and parent story's acceptance criteria, giving the implementer immediate scope clarity without a three-hop lookup.
- **TaskCreate description field populated** — In `cpm:stories` Step 4, the one-line description from the stories doc fills the existing `{Description with relevant context}` placeholder in the TaskCreate template, so `TaskGet` returns it even without the stories doc.

### Should Have

- **Judgement-based inclusion** — Descriptions are a facilitator judgement call, not mandatory boilerplate. If a task title is self-evident in the context of its parent story (e.g., a single-task story), the description can be omitted. The `cpm:stories` skill should guide this during Step 3b.

### Could Have

- **Acceptance criteria mapping** — Descriptions could explicitly reference which numbered acceptance criteria the task covers (e.g., "Covers criteria 1-3"). Useful but potentially brittle if criteria are reordered.

### Won't Have (this iteration)

- Task-level acceptance criteria — tasks don't get their own criteria; that design principle stays unchanged.
- Retroactive description generation for existing stories docs.

## Non-Functional Requirements

### Consistency

- Task descriptions use the same tone and style as existing stories doc fields — imperative, concise, no jargon divergence.
- The `**Description**:` field follows the same formatting pattern as other task metadata fields (`**Task**:`, `**Task ID**:`, `**Status**:`).
- Existing stories docs without descriptions remain valid — no breaking change to the format. `cpm:do` treats the field as optional.

## Architecture Decisions

### Field Placement
**Choice**: `**Description**:` placed after `**Task**:` and before `**Task ID**:`.
**Rationale**: Groups human-authored content together (title, number, description) and separates it from system-managed fields (Task ID, Status). Readers scan top-down and get the "what is this?" before the "what's its state?"
**Alternatives considered**: Placing after Status at the end of the block — rejected because it separates the description from the title it clarifies.

### TaskCreate Population
**Choice**: The one-line description fills the existing `{Description with relevant context}` placeholder in the TaskCreate template.
**Rationale**: The placeholder already exists and is underspecified. The stories doc description is exactly the relevant context it was designed for. No structural change to the template needed.
**Alternatives considered**: Adding a separate field — rejected as unnecessary when the placeholder already exists.

## Scope

### In Scope
- Add `**Description**:` field to the task block format in `cpm:stories` SKILL.md output template
- Update `cpm:stories` Step 3b with guidance on writing task descriptions
- Update `cpm:stories` Step 4 TaskCreate to populate the description placeholder
- Update `cpm:do` Step 1 (Load Context) to read the description field from the stories doc

### Out of Scope
- Changes to story-level fields (stories already have acceptance criteria)
- Retroactive description generation for existing stories docs
- Validation or linting of description quality
- Changes to `cpm:do` behaviour beyond reading the field
- Changes to any other CPM skills (party, retro, pivot, library, discover)

### Deferred
- **Explicit AC mapping in descriptions** — Referencing specific acceptance criteria numbers. Evaluate after seeing how free-form descriptions work in practice.
- **Batch enrichment tool** — A tool to add descriptions to existing stories docs, similar to `cpm:library consolidate` for front-matter. Only build if the pattern proves valuable.
