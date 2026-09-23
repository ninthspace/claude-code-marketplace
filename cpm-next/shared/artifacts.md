# cpm-next Artefact Contract

The skills in this plugin keep their procedures short and their data strict. This file is the strict part. The cpm board, `/cpm:status`, and the v3 skills parse these files, so the formats below are a contract: write them exactly, read them tolerantly.

## Where things live

| Artefact | Path | Written by |
|---|---|---|
| Discussion | `docs/discussions/{nn}-discussion-{slug}.md` | party |
| Brief | `docs/briefs/{nn}-brief-{slug}.md` | plan |
| ADR (only for decisions that outlive one spec) | `docs/architecture/{nn}-adr-{slug}.md` | plan |
| Spec | `docs/specifications/{nn}-spec-{slug}.md` | plan |
| Epic | `docs/epics/{parent}-{seq}-epic-{slug}.md` | plan (structure), do (status) |
| Retro | `docs/retros/{nn}-retro-{slug}.md` | do |
| Quick change record | `docs/quick/{nn}-quick-{slug}.md` | do |
| Reference library | `docs/library/*.md` | library, or the user; every skill reads it |
| Persona roster override | `docs/agents/roster.yaml` | the user; replaces the plugin default entirely |

Read all of these as context whenever they bear on the work. Existing v3 files, including legacy flat epics (`{nn}-epic-{slug}.md`) and coverage matrices (`*-coverage-*.md`), are valid input. This plugin does not create coverage matrices; the `**Satisfies**` field on each story carries the traceability instead.

## Numbering

`{nn}` is `max + 1` over the integer prefixes in both `docs/{type}/` and `docs/archive/{type}/`. Compare as integers, never as strings. Pad to at least two digits (`01`, `99`, `100`). Numbers are never reused and existing files are never renamed.

Epic prefixes are two-part. `{parent}` is the source spec's number, or `00` when the epic comes from a brief, discussion or description with no spec. `{seq}` is `max + 1` over existing epics with that parent, again across active and archive.

## Status vocabulary

The first token of a `**Status**:` value is what tools read. Anything after ` — ` is a human note.

- Stories and tasks: `Pending`, `In Progress`, `Complete`.
- Epics: those three, derived from their stories, plus the user-set terminal values `Superseded` and `Withdrawn`. Never set the terminal values yourself.
- Read `Done` as `Complete`; always write `Complete`.
- A story is unblocked when its `**Blocked by**` is `—` or every item it names is `Complete`. A `Superseded` or `Withdrawn` epic never satisfies a dependency.

## Brief

```markdown
# Product Brief: {Title}

**Date**: {YYYY-MM-DD}
**Source**: {paths or "conversation"}

## Problem
## Vision
## Users and Value
## Key Features
### Essential
### Enhancing
## Constraints
## User Journeys
## Assumptions
```

Omit a section that would only contain filler. Keep Assumptions: it is where anything decided without the user is recorded.

## Spec

```markdown
# Spec: {Title}

**Date**: {YYYY-MM-DD}
**Source**: {brief / discussion / ADR paths, or "conversation"}

## Problem Summary

## Functional Requirements
### Must Have
- **FR1**: {requirement} — AC: {testable criterion} `[unit|feature|integration|manual]`
### Should Have
### Could Have
### Won't Have (this iteration)

## Non-Functional Requirements
- **NFR1**: {requirement with a measurable threshold}

## Architecture Decisions
### AD1: {Decision}
{Choice, the alternatives considered, and why. Cite an ADR file if one exists.}

## Scope
### In Scope
### Out of Scope

## Testing Strategy
{Test command, which tags map to which suites, integration boundaries.}

## Assumptions
```

Requirement labels (`FR3`, `NFR2`, `AD1`) are stable identifiers. When amending, add new numbers rather than renumbering.

## Epic

```markdown
# {Epic Name}

**Source spec**: {path, or the brief/discussion path for a 00- epic}
**Date**: {YYYY-MM-DD}
**Status**: Pending
**Blocked by**: —

## {Story Title}
**Story**: {N}
**Status**: Pending
**Blocked by**: —
**Satisfies**: {FR1, NFR2 — omit only for 00- epics}

**Acceptance Criteria**:
- {criterion} `[tag]`

### {Task Title}
**Task**: {N.1}
**Description**: {what this task covers within the story}
**Status**: Pending

---
```

Stories are numbered from 1 within each epic. Tasks use `{story}.{seq}`. Intra-epic dependencies name stories (`Story 2`); cross-epic dependencies name the epic by filename prefix (`Epic 28-01-epic-setup`).

### Evidence against each criterion

`do` records evidence as an indented line directly under the criterion it proves, never in a separate block:

```markdown
**Acceptance Criteria**:
- {criterion} `[tag]`
  - Evidence: {test name and command, file:line, or the manual step taken and what was observed}
- {criterion} `[tag]`
  - Not met: {what was tried and why it fell short}
```

The criterion line itself is never edited to record verification, so its text stays comparable with coverage matrices and earlier readings. A story is `Complete` only when every criterion has an `Evidence` line; a `Not met` line leaves it blocked. Read a legacy story-level `**Evidence**:` field as valid input, but don't write one.

### Fields `do` may add to a story

- `**Retro**: {an observation worth carrying into future work}`
- `**Inline change**: {one-line summary} ({YYYY-MM-DD})` for a wording fix with no scope change.
- `**Amended**: {what changed} ({YYYY-MM-DD}) — cited: {file:line | FRn | conflicting criterion}`
- `**Pivot deferred**: {change} → {artefact path} (Story {N}, {YYYY-MM-DD}) — cited: {citation}`

### Fields on the epic header

- `**Retro waived**: {reason} ({YYYY-MM-DD})` marks a completed epic whose run produced nothing worth a retro.

## Library document

```markdown
---
title: {Title}
source: {original path or URL}
added: {YYYY-MM-DD}
last-reviewed: {YYYY-MM-DD}
scope:
  - {scope value}
summary: >
  {two to five sentences of constraints, decisions and rules, written for skills}
---

{source content, unchanged}
```

All six fields are required. Filenames are kebab-case with no number prefix.

`scope` holds v3 skill names, because v3 skills filter the library on them; cpm-next skills read every library document regardless. Choose by what the document constrains:

| The document constrains | Scope values |
|---|---|
| what gets planned: requirements, domain rules, architecture | `discover`, `brief`, `architect`, `spec`, `epics` |
| how code gets written: standards, conventions, API contracts | `do`, `quick`, `review` |
| discussion: team norms, positions to argue from | `party`, `consult` |
| everything: glossaries, domain language, team conventions | `all`, alone |

Combine rows freely; an API contract is usually `spec`, `epics`, `do`.

v3's `/cpm:retro learn` appends amendments below the body in this form, and `library consolidate` folds them back in:

```markdown
## Amendment — {YYYY-MM-DD} (via retro)

**Source**: {retro path}
**Category**: {observation category}

{what was learned and what should change}
```

## Amending an existing artefact

Edit in place and add an `**Amended**: {YYYY-MM-DD} — {summary}` line under the header. Never rewrite a `Complete` story's criteria; add a new story for new work instead. When an upstream change alters what a `Pending` story must do, update that story in the same pass.
