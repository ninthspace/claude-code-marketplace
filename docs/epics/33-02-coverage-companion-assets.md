# Coverage Matrix: Companion Asset Generation

**Source spec**: docs/specifications/33-spec-html-artifact-projection.md
**Epic**: docs/epics/33-02-epic-companion-assets.md
**Date**: 2026-06-02

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | Intrinsic companion-asset generation | Producing skills (`spec`, `architect`) generate an HTML companion artifact when an artifact's content is inherently visual (UI mockup, architecture/data-flow diagram). Generation is content-driven — triggered by the nature of the requirement, not by an explicit flag. | When a `spec` or `architect` ADR requirement is inherently visual (UI mockup, data-flow diagram), the skill generates an HTML companion asset and references it from the Markdown | Story 1 | `[manual]` | |
| 2 | Intrinsic companion-asset generation | (as above) | Generation is content-driven — triggered by the nature of the requirement, not by an explicit flag | Story 1 | `[manual]` | |
| 3 | Conservative generation heuristic | A skill generates a companion asset only when a visual genuinely earns its place, and records a one-line note in the Markdown explaining why the asset exists. | The skill must NOT generate a companion asset for non-visual requirements, and records a one-line note in the Markdown explaining why an asset exists | Story 1 | `[manual]` | |
| 4 | Stable, referenced asset storage | Companion assets are written to a conventional location (`docs/{type}/assets/{nn}-{slug}-{label}.html`) and referenced from the Markdown artifact by a stable relative path. | Generated companion assets are written to `docs/{type}/assets/{nn}-{slug}-{label}.html` and referenced by a relative path that resolves from the Markdown | Story 1 | `[integration]` | |
| 5 | Shared HTML template foundation | ... that every HTML output uses for styling and layout, so all generated HTML is visually consistent and no skill forks its own styling. | Companion assets consume the shared template asset, not a forked stylesheet | Story 1 | `[integration]` | |
| 6 | Downstream consumption as a design target | `epics` and `do` treat a referenced companion asset as "build to match this," never as data to parse. The Markdown still carries the machine-readable requirements. | An acceptance criterion that references a mockup is tagged `[manual]` or `[feature]` ("match the mockup"), never a markup-parsing test | Story 2 | `[manual]` | |
| 7 | Downstream consumption as a design target | (as above) | `epics` and `do` treat a referenced companion asset as a design target ("build to match this"), never as data to parse | Story 2 | `[manual]` | |
| 8 | Downstream consumption as a design target | (as above) | `do` must NOT parse the companion HTML to extract requirements | Story 2 | `[manual]` | |
