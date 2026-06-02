# Coverage Matrix: present HTML Output

**Source spec**: docs/specifications/33-spec-html-artifact-projection.md
**Epic**: docs/epics/33-04-epic-present-html-output.md
**Date**: 2026-06-02

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | `present` HTML output | `cpm2:present` can emit its reframed, audience-targeted communications (summary memo, onboarding guide, etc.) as styled HTML using the *same shared template foundation*, in addition to its existing Markdown output. This is `present`'s existing verb (reframe-for-audience) in a new medium — distinct from the faithful render (which preserves full fidelity). | `present` can emit a reframed communication (summary memo, onboarding guide, etc.) as styled HTML using the shared template, in addition to its existing Markdown output | Story 1 | `[manual]` | |
| 2 | Self-contained output | Rendered views, companion assets, and `present` HTML communications are single files with inline CSS/SVG — shareable by sending one file, openable in any browser, no server or build step. | `present` HTML output is self-contained and uses the shared template, not a forked stylesheet | Story 1 | `[integration]` | |
| 3 | Storage & reference convention | ... `present` HTML communications alongside its Markdown output in `docs/communications/`. | `present` HTML output is written alongside its Markdown output in `docs/communications/` | Story 1 | `[integration]` | |
