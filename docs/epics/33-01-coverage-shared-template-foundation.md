# Coverage Matrix: Shared Template Foundation

**Source spec**: docs/specifications/33-spec-html-artifact-projection.md
**Epic**: docs/epics/33-01-epic-shared-template-foundation.md
**Date**: 2026-06-02

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | Shared HTML template foundation | A single shared HTML/CSS asset (e.g. under `cpm2/assets/html/`) that every HTML output uses for styling and layout, so all generated HTML is visually consistent and no skill forks its own styling. This is the load-bearing asset Spec 2 and `present` also reuse. | A single shared HTML/CSS template asset exists under the plugin (`cpm2/assets/html/`) and is valid, self-contained HTML | Story 2 | `[integration]` | ✓ |
| 2 | Shared HTML template foundation | (as above) | The template must NOT require any external network resource to render | Story 2 | `[integration]` | ✓ |
| 3 | Shared HTML template foundation | (as above) | HTML output conventions are documented in the shared skill conventions: companion-asset path `docs/{type}/assets/{nn}-{slug}-{label}.html`, render path `docs/{type}/html/{nn}-{slug}.html`, the self-contained rule, generate-from-source-never-replace, and "consume the shared template, do not fork it" | Story 2 | `[manual]` | ✓ |
| 4 | Self-contained output | Rendered views, companion assets, and `present` HTML communications are single files with inline CSS/SVG — shareable by sending one file, openable in any browser, no server or build step. | A self-containment validator detects external CSS/JS/image/font references in an HTML file and fails when any are present | Story 1 | `[integration]` | ✓ |
| 5 | Generate-from-source, never replace | No HTML generation step ever mutates the source Markdown. Markdown remains the parsed source of truth. | A source-immutability check verifies a Markdown file's content hash is unchanged after a generation step runs | Story 1 | `[integration]` | ✓ |
| 6 | Test Infrastructure | Reuse the existing bash test runner (`test-helpers.sh`, isolated temp dirs) from the hook test suites ... New automatable checks needed: (1) a self-containment validator (no external refs in generated HTML), (2) a source-immutability check (Markdown hash unchanged after generation), (3) template-asset validity check. No new framework required. | All tooling is added to the existing bash test runner using `test-helpers.sh`, with no new test framework introduced | Story 1 | `[integration]` | ✓ |
