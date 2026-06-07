# Shared Template Foundation

**Source spec**: docs/specifications/33-spec-html-artifact-projection.md
**Date**: 2026-06-02
**Status**: Complete
**Blocked by**: —

## Build shared HTML test tooling
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: Test Infrastructure; Self-contained output; Generate-from-source, never replace

**Acceptance Criteria**:

- A self-containment validator detects external CSS/JS/image/font references in an HTML file and fails when any are present [integration]
- A source-immutability check verifies a Markdown file's content hash is unchanged after a generation step runs [integration]
- All tooling is added to the existing bash test runner using `test-helpers.sh`, with no new test framework introduced [integration]

### Add self-containment validator to the bash test tooling
**Task**: 1.1
**Description**: Scans generated HTML for external references; provides the self-contained-output check every HTML epic reuses.
**Status**: Complete

### Add source-immutability check to the bash test tooling
**Task**: 1.2
**Description**: Hashes source Markdown before/after a generation step; enforces generate-from-source-never-replace for downstream epics.
**Status**: Complete

### Write tests for the HTML test tooling
**Task**: 1.3
**Description**: Fixture-based tests proving the validator and immutability check flag violations and pass clean inputs. Covers the story's [integration] criteria.
**Status**: Complete

**Retro**: [Smooth delivery] Validators slotted cleanly into the existing bash runner as a sourceable helper library plus one test suite; the mature test-helpers.sh harness made the [integration] coverage straightforward with no new framework.

---

## Create the shared HTML template asset and output conventions [plan]
**Story**: 2
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: Shared HTML template foundation

**Acceptance Criteria**:

- A single shared HTML/CSS template asset exists under the plugin (`cpm2/assets/html/`) and is valid, self-contained HTML [integration]
- The template must NOT require any external network resource to render [integration]
- HTML output conventions are documented in the shared skill conventions: companion-asset path `docs/{type}/assets/{nn}-{slug}-{label}.html`, render path `docs/{type}/html/{nn}-{slug}.html`, the self-contained rule, generate-from-source-never-replace, and "consume the shared template, do not fork it" [manual] — documentation content requires human review

### Create the shared HTML/CSS template asset
**Task**: 2.1
**Description**: The single styling/layout file every HTML consumer uses; self-contained, no external refs.
**Status**: Complete

### Document HTML output conventions in the shared conventions doc
**Task**: 2.2
**Description**: Storage paths, self-contained rule, generate-from-source-never-replace, no-fork — the contract epics 33-02/03/04 consume.
**Status**: Complete

### Write tests for the shared template asset
**Task**: 2.3
**Description**: Runs the Story 1 validator plus a template-validity check against the real asset. Covers the story's [integration] criteria.
**Status**: Complete

**Retro**: [Pattern worth reusing] Authoring design quality once into a single canonical template (frontend-design-guided) with placeholder tokens — and forbidding per-render forks — gives epics 33-02/03/04 a consume-don't-fork foundation; the hard self-containment constraint cleanly resolved the "distinctive fonts vs no external requests" tension via a characterful system-serif stack and CSS-gradient texture.

---

## Lessons

### Smooth Deliveries

- Story 1: Validators slotted cleanly into the existing bash runner as a sourceable helper library plus one test suite; the mature `test-helpers.sh` harness made the `[integration]` coverage straightforward with no new framework.

### Patterns Worth Reusing

- Story 2: Authoring design quality once into a single canonical template (frontend-design-guided) with placeholder tokens — and forbidding per-render forks — gives epics 33-02/03/04 a consume-don't-fork foundation; the self-containment constraint resolved the "distinctive fonts vs no external requests" tension via a system-serif stack and CSS-gradient texture.
