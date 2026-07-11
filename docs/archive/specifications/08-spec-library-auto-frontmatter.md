# Spec: Library Auto Front-Matter

**Date**: 2026-02-11
**Brief**: User description — enhance cpm:library consolidate for batch front-matter generation

## Problem Summary

The `cpm:library` skill has an intake workflow that imports documents with generated front-matter, and a consolidate workflow that reconciles amendments on a single named file. But users who manually place markdown files into `docs/library/` — or copy them from another project — have no way to get front-matter added. These bare documents can't be properly discovered or scope-filtered by other CPM skills. Running `/cpm:library consolidate` with no file argument should batch-scan the library, identify documents missing front-matter, and generate it using the same auto-scope analysis as intake.

## Functional Requirements

### Must Have

- **No-arg consolidate scan** — `/cpm:library consolidate` (no file path) globs `docs/library/*.md`, reads each file, and identifies documents with missing front-matter.
- **Front-matter generation for bare documents** — For each document missing front-matter, analyse content and generate all six required fields (`title`, `source`, `added`, `last-reviewed`, `scope`, `summary`) using the same logic as intake.
- **Auto-scope suggestion** — Reuse the existing content-analysis heuristics to suggest scope values for each bare document.
- **User approval per document** — Present generated front-matter for each document and let the user confirm or adjust before writing. No silent overwrites.
- **Write front-matter in place** — Prepend the approved front-matter to the existing document content. The original body is not modified.

### Should Have

- **Batch summary upfront** — Before processing individual files, show the user a summary: "Found N documents without front-matter: {filenames}. Proceed?"
- **`source` field inference** — Set `source` to the document's current file path (since the original source is unknown for manually-placed files).

### Could Have

- **Partial front-matter detection** — If a document has front-matter but is missing some required fields, offer to fill in the gaps rather than treating it as fully complete.

### Won't Have (this iteration)

- Fully automatic mode (no user approval)
- Non-markdown file handling
- Recursive subdirectory scanning

## Non-Functional Requirements

### Graceful Degradation
- If `docs/library/` doesn't exist or is empty, tell the user and stop — no errors.
- If a document has malformed content that can't be analysed, skip it with a warning rather than aborting the entire batch.

### Consistency
Generated front-matter uses the exact same schema and format as intake-produced documents. No divergence between "imported via intake" and "tagged via consolidate."

### Context Window Efficiency
Documents are read one at a time during processing, not all loaded upfront. Each document is read, front-matter generated, user approves, then move to the next.

## Architecture Decisions

### Front-Matter Detection
**Choice**: Binary detection — a file either starts with `---` (has front-matter, skip it) or doesn't (bare, process it).
**Rationale**: Simple and reliable. A regex check for `^---` on the first line is trivial. Trying to validate YAML structure or check for missing fields adds complexity that isn't needed for v1. The "Could Have" partial detection can layer on later.
**Alternatives considered**: Three-state detection (complete/partial/bare) — rejected for v1 as it adds edge cases without clear immediate value. YAML parsing to validate field presence — rejected as over-engineered for the detection step.

### Consolidate Action Routing
**Choice**: Extend the existing `consolidate` verb. No file path = batch front-matter scan. With file path = existing amendment reconciliation. A new routing branch in the Input section.
**Rationale**: The mental model for "consolidate" is "tidy up my library." Whether that means reconciling amendments or adding missing metadata, it fits under the same verb. Adding a new action name would mean another command to learn with marginal benefit.
**Alternatives considered**: New verb like `tag` or `enrich` — rejected because it fragments the UX for a closely related operation. Making it a separate skill — rejected as overkill for a workflow that shares infrastructure with the existing consolidate.

## Scope

### In Scope
- New routing branch in the Input section: `consolidate` (no arg) → batch front-matter workflow
- Batch scan of `docs/library/*.md` to find files without front-matter
- Front-matter generation for bare documents (same six fields, same auto-scope heuristics as intake)
- User approval flow: batch summary → per-document front-matter review → write
- Graceful handling of empty library, no bare files found, and unreadable files
- State management (progress file) for the new workflow

### Out of Scope
- Changes to the existing consolidate-with-file-path workflow
- Changes to the intake workflow
- Partial front-matter repair
- Non-markdown files
- Recursive subdirectory scanning

### Deferred
- **Partial front-matter detection** — Filling in missing fields on documents that have some but not all required front-matter. Binary detection is enough for now; add when a real need emerges.
- **Batch approval mode** — Generating all front-matter upfront and presenting it as a single review. Per-document is simpler and matches the existing interaction pattern.
