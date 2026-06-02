# Companion Asset Generation

**Source spec**: docs/specifications/33-spec-html-artifact-projection.md
**Date**: 2026-06-02
**Status**: Pending
**Blocked by**: Epic 33-01-epic-shared-template-foundation

## Add intrinsic companion-asset generation to spec and architect
**Story**: 1
**Status**: Pending
**Blocked by**: Epic 33-01-epic-shared-template-foundation
**Satisfies**: Intrinsic companion-asset generation; Stable, referenced asset storage; Conservative generation heuristic

**Acceptance Criteria**:

- When a `spec` or `architect` ADR requirement is inherently visual (UI mockup, data-flow diagram), the skill generates an HTML companion asset and references it from the Markdown [manual] — LLM-driven generation judgement; no deterministic oracle
- Generation is content-driven — triggered by the nature of the requirement, not by an explicit flag [manual] — behavioural judgement
- The skill must NOT generate a companion asset for non-visual requirements, and records a one-line note in the Markdown explaining why an asset exists [manual] — judgement of "earns its place"
- Generated companion assets are written to `docs/{type}/assets/{nn}-{slug}-{label}.html` and referenced by a relative path that resolves from the Markdown [integration]
- Documentation companion assets (diagrams that explain the artifact) consume the shared template asset, not a forked stylesheet; deliverable-functionality mockups (system UI previews) are system-specific — built standalone with the target system's own design, not the shared template — but are still self-contained (single file, inline CSS/SVG, no external resources, no JS) [integration]

### Add companion-asset generation guidance to the spec skill
**Task**: 1.1
**Description**: Emit a mockup when a requirement is visual; reference it from the Markdown; apply the conservative heuristic and the one-line "why this asset exists" note. A deliverable-functionality mockup is system-specific — styled to the target system, standalone, not the shared template.
**Status**: Pending

### Add companion-asset generation guidance to the architect skill
**Task**: 1.2
**Description**: Emit a diagram asset when an ADR is inherently visual; same reference/heuristic/note rules as the spec skill.
**Status**: Pending

### Write tests for companion-asset storage and reference
**Task**: 1.3
**Description**: Assert generated assets land at the convention path and the Markdown reference resolves; assert documentation diagrams consume the shared template, while deliverable-functionality mockups are self-contained (no external refs) without requiring the shared template. Covers the story's [integration] criteria.
**Status**: Pending

---

## Establish the downstream consumption contract in epics and do [plan]
**Story**: 2
**Status**: Pending
**Blocked by**: Story 1
**Satisfies**: Downstream consumption as a design target

**Acceptance Criteria**:

- An acceptance criterion that references a mockup is tagged `[manual]` or `[feature]` ("match the mockup"), never a markup-parsing test [manual] — verified by reviewing `epics` output
- `epics` and `do` treat a referenced companion asset as a design target ("build to match this"), never as data to parse [manual]
- `do` must NOT parse the companion HTML to extract requirements [manual]

### Add design-target consumption guidance to the epics skill
**Task**: 2.1
**Description**: Tag mockup-referencing criteria `[manual]`/`[feature]`; treat referenced assets as design targets, not parsed data.
**Status**: Pending

### Add design-target consumption guidance to the do skill
**Task**: 2.2
**Description**: Build to match a referenced asset; must not parse companion HTML to extract requirements.
**Status**: Pending

---
