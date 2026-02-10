---
name: cpm:library
description: Curate a project reference library. Import external documents with structured front-matter so other CPM skills can discover and use them as context. Triggers on "/cpm:library".
---

# Project Reference Library

Import external documents into a curated `docs/library/` directory with structured YAML front-matter. Other CPM skills automatically discover and reference these documents during planning and execution.

## Input

Parse `$ARGUMENTS` to determine the action:

1. **Consolidate action**: If `$ARGUMENTS` starts with `consolidate` (e.g. `consolidate docs/library/coding-standards.md`), extract the file path and proceed to the Consolidation workflow below.
2. **Intake action**: If `$ARGUMENTS` is a file path or URL, use it as the source document for intake.
3. **No arguments**: Ask the user what document they want to import. Use AskUserQuestion:
   - **Import a local file** — Provide a file path
   - **Import from a URL** — Provide a URL

## Intake Workflow

Import a document into the project library with generated front-matter.

**State tracking**: Before starting Step 1, create the progress file (see State Management below). Each step below ends with a mandatory progress file update — do not skip it. After saving the final library document, delete the file.

### Step 1: Read Source Document

Read the source document:

- **File path**: Use the Read tool to read the file. If the file doesn't exist, tell the user and stop.
- **URL**: Use the WebFetch tool to retrieve the content. If the fetch fails, tell the user and stop.

Present a brief summary of the document to the user — what it covers, how long it is, what kind of content it contains (standards, architecture, guidelines, etc.).

**Update progress file now.**

### Step 2: Generate Front-Matter

Analyse the document content and generate the six required front-matter fields:

- **`title`**: A clear, concise title derived from the document's heading or content.
- **`source`**: The original file path or URL the document was imported from.
- **`added`**: Today's date in `YYYY-MM-DD` format.
- **`last-reviewed`**: Same as `added` (first import is the first review).
- **`scope`**: Array of CPM skill names this document is relevant to. See Auto-Scope Suggestion below.
- **`summary`**: A CPM-oriented distillation of the document — actionable constraints, decisions, rules, and conventions that downstream skills need. This is NOT a human abstract; it's written for CPM skills to use during triage. Keep it to 2-5 sentences focused on what matters for planning and implementation.

#### Auto-Scope Suggestion

Analyse the document content to suggest which skills should reference it. Use these heuristics:

| Content signals | Suggested scope |
|---|---|
| Architecture decisions, system design, component boundaries, integration patterns | `discover`, `spec`, `do` |
| Coding standards, style guides, naming conventions, linting rules | `do` |
| API contracts, data models, schema definitions | `spec`, `stories`, `do` |
| Business rules, domain logic, workflow descriptions | `discover`, `spec`, `stories` |
| Security policies, compliance requirements, access control | `spec`, `do` |
| Team conventions, process guidelines, collaboration norms | `all` |
| Glossaries, terminology, domain language | `all` |

Present the suggested scope to the user with AskUserQuestion. Show the suggested values and let them adjust:

- **Accept suggested scope** — Use the suggested scope values
- **Adjust scope** — Let the user modify the list

Valid scope values: `discover`, `spec`, `stories`, `do`, `party`, `all`. The value `all` is a shorthand that matches every skill — don't combine it with individual skill names.

Present the complete generated front-matter to the user for confirmation before proceeding.

**Update progress file now.**

### Step 3: Write Library Document

1. Create the `docs/library/` directory if it doesn't exist.
2. Derive a filename from the title — kebab-case, no number prefix (library docs are a collection, not a sequence). For example: `coding-standards.md`, `architecture-decisions.md`, `api-contracts.md`.
3. Write the document with front-matter prepended:

```markdown
---
title: {title}
source: {source path or URL}
added: {YYYY-MM-DD}
last-reviewed: {YYYY-MM-DD}
scope:
  - {skill name}
  - {skill name}
summary: >
  {CPM-oriented summary — actionable constraints and rules
  for downstream skills}
---

{original document content}
```

4. Tell the user the saved file path.

**Update progress file now, then delete the progress file.**

## Consolidation Workflow

Reconcile accumulated amendments on a library document into a clean, updated version.

This action is invoked as `/cpm:library consolidate <file-path>`.

### Step 1: Read and Analyse

1. Read the specified library document with the Read tool. If it doesn't exist, tell the user and stop.
2. Parse the document into three parts:
   - **Front-matter**: The YAML block between `---` delimiters
   - **Original content**: Everything after front-matter up to the first `## Amendment` heading (or end of file if none)
   - **Amendments**: All `## Amendment` blocks, in order

3. If no amendments exist, tell the user there's nothing to consolidate and stop.

4. Present a summary: how many amendments, their dates and categories, any apparent contradictions.

### Step 2: Produce Reconciled Version

1. Analyse the original content and all amendments together.
2. Produce a reconciled version of the document that integrates amendment observations into the original content body. The goal is a clean, current document — not original-plus-patches.
3. **Flag contradictions**: If amendments contradict the original content or each other, flag these explicitly to the user rather than silently resolving them. Present the contradiction and ask the user which direction to take.
4. Update the front-matter:
   - `last-reviewed`: Today's date
   - `summary`: Refreshed to reflect the reconciled content
5. Remove all `## Amendment` blocks from the body (their content is now integrated).

### Step 3: User Approval and Save

1. Present the reconciled version to the user for review. Show a clear before/after summary of what changed.
2. Use AskUserQuestion to gate the save:
   - **Save the reconciled version** — Write the file
   - **Make adjustments** — Let the user request changes before saving
   - **Cancel** — Keep the original document unchanged
3. If approved, write the reconciled document using the Write tool (full replacement is appropriate here since the user is approving the complete new version).
4. Tell the user the updated file path.

## State Management

Maintain `docs/plans/.cpm-progress.md` during the intake workflow for compaction resilience.

**Create** the file before starting Step 1. **Update** it after each step completes. **Delete** it after saving the final library document.

Use the Write tool to write the full file each time (not Edit — the file is replaced wholesale). Format:

```markdown
# CPM Session State

**Skill**: cpm:library
**Action**: {intake or consolidate}
**Step**: {N} of 3 — {Step Name}
**Source**: {file path or URL being imported, or file being consolidated}
**Output target**: docs/library/{filename}.md

## Completed Steps

### Step 1: Read Source Document
{Summary — document type, length, key content areas}

### Step 2: Generate Front-Matter
{Summary — title, scope values chosen, summary generated}

### Step 3: Write Library Document
{Summary — file path written}

{...include only completed steps...}

## Next Action
{What to do next}
```

## Front-Matter Schema Reference

Every library document must have exactly these six fields in its YAML front-matter:

```yaml
---
title: {string, required}       # Human-readable document title
source: {string, required}      # Original file path or URL
added: {date, required}         # Date imported (YYYY-MM-DD)
last-reviewed: {date, required} # Date last reviewed or amended (YYYY-MM-DD)
scope:                          # Array of skill names this doc is relevant to
  - {string}                    # Valid: discover, spec, stories, do, party, all
summary: >                      # CPM-oriented actionable distillation
  {string}                      # Written for skills, not humans. 2-5 sentences.
---
```

**Consistency rules**:
- All fields are required — never omit any.
- Date format is always `YYYY-MM-DD`.
- Scope values are lowercase skill names. `all` is a shorthand for every skill — don't combine with individual names.
- Summary focuses on actionable constraints, decisions, and rules — not a description of what the document is about.

## Amendment Format Reference

When `/cpm:retro` amends a library document, it appends blocks in this format:

```markdown
## Amendment — {YYYY-MM-DD} (via retro)

**Source**: {path to retro file}
**Category**: {observation category}

{Observation text — what was learned and what should change}
```

The consolidation action reads and reconciles these blocks. This format is the contract between retro write-back and consolidation.

## Guidelines

- **Low friction intake.** The user provides a path or URL; CPM does the rest. Minimise questions — auto-suggest, then confirm.
- **Summaries are for machines.** The front-matter summary is read by other CPM skills during triage, not by humans browsing a docs folder. Write it as actionable constraints: "PSR-12 with Pint enforcement. Repository pattern for data access. No inline SQL outside migrations." Not: "This document describes the team's PHP coding standards."
- **One document, one file.** Don't split or merge source documents. Import them as-is with front-matter prepended.
- **Graceful on failure.** If a URL can't be fetched or a file doesn't exist, tell the user and stop. Don't partially import.
- **Consolidation is user-controlled.** Never auto-consolidate. The user decides when amendment accumulation warrants a clean-up pass.
