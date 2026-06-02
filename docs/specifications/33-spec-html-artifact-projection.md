# Spec: HTML Artifact Projection & Companion Assets (Tier 1)

**Date**: 2026-06-02
**Brief**: docs/discussions/19-discussion-html-artifact-projection.md

## Problem Summary
CPM2 artifacts are Markdown — ideal as machine-consumed source of truth, but with two gaps for human and downstream value. First, **visual content can't live in Markdown**: a UI spec needs a mockup, an ADR needs a data-flow diagram — today that intent is omitted, crudely ASCII-approximated, or exiled to a Figma link that dies, so it never travels downstream to the people building it. Second, **large structured artifacts are hard to navigate** as raw Markdown: ADR option comparisons, severity-sorted review findings, 200-line specs. This spec adds HTML in distinct, explicitly-bounded roles — *companion assets* (visual content the Markdown references), *faithful renders* (navigable views of a whole artifact), and *HTML communications* (`present`'s reframed output) — over one shared template foundation, while keeping Markdown the parsed source of truth. It is the foundation Spec 2 (interactive tracking dashboards) reuses.

## Functional Requirements

### Must Have

- **Shared HTML template foundation.** A single shared HTML/CSS asset (e.g. under `cpm2/assets/html/`) that every HTML output **presenting a CPM2 artifact** uses for styling and layout, so all such generated HTML is visually consistent and no skill forks its own styling. This is the load-bearing asset Spec 2 and `present` also reuse. **Carve-out — deliverable-functionality mockups.** A companion asset that represents *deliverable functionality* (a mockup of the UI of the system being built) is *system-specific*: it must represent the target system's own design language, **not** CPM2's documentation chrome. Such mockups are built standalone and do **not** consume, embed, or inherit the shared template (they remain self-contained per the rule below, and are stored at the same companion-asset path). The distinction is explain-vs-preview: documentation visuals that *explain* an artifact (architecture/data-flow diagrams) use the shared template; a visual that *is a preview of the deliverable* wears the deliverable's own design.
- **Intrinsic companion-asset generation.** Producing skills (`spec`, `architect`) generate an HTML companion artifact when an artifact's content is inherently visual (UI mockup, architecture/data-flow diagram). Generation is content-driven — triggered by the nature of the requirement, not by an explicit flag.
- **Stable, referenced asset storage.** Companion assets are written to a conventional location (`docs/{type}/assets/{nn}-{slug}-{label}.html`) and referenced from the Markdown artifact by a stable relative path.
- **Downstream consumption as a design target.** `epics` and `do` treat a referenced companion asset as "build to match this," never as data to parse. The Markdown still carries the machine-readable requirements.
- **Faithful render of substrate artifacts.** On request, a whole `spec`, `architect` ADR, or `review` is rendered to a navigable HTML view generated *from* its Markdown, written to a conventional location, without modifying or replacing the Markdown.
- **Generate-from-source, never replace.** No HTML generation step ever mutates the source Markdown. Markdown remains the parsed source of truth.

### Should Have

- **`present` HTML output.** `cpm2:present` can emit its reframed, audience-targeted communications (summary memo, onboarding guide, etc.) as styled HTML using the *same shared template foundation*, in addition to its existing Markdown output. This is `present`'s existing verb (reframe-for-audience) in a new medium — distinct from the faithful render (which preserves full fidelity).
- **Artifact-appropriate navigation in faithful renders** — contents sidebar for large specs; side-by-side option/trade-off columns for ADRs; severity grouping/sorting for review findings. Static only (no stateful JS).
- **Conservative generation heuristic.** A skill generates a companion asset only when a visual genuinely earns its place, and records a one-line note in the Markdown explaining why the asset exists.
- **Self-contained output.** Rendered views, companion assets, and `present` HTML communications are single files with inline CSS/SVG — shareable by sending one file, openable in any browser, no server or build step.
- **Regeneration in place.** Re-rendering after the source Markdown changes updates the existing HTML view rather than spawning duplicates; traceable to its source artifact.

### Could Have

- Light "copy as Markdown" affordance on rendered views (no heavy interactivity — that's Tier 2).
- A small manifest linking an artifact to its companion assets for discovery.

### Won't Have (this iteration)

- Interactive / stateful JS dashboards, sliders, copy-as-prompt editors — **Spec 2 (Tier 2)**.
- HTML rendering of prose artifacts (`brief`, `discover`, `retro`, `quick`) — nothing to navigate.
- HTML as a parsed/consumed data substrate — downstream skills never parse markup for requirements.
- A new top-level `cpm2:render` skill. (Faithful render is per-skill; `present` gains HTML output for its *own reframed* communications only — it does not host the faithful render.)
- A build pipeline, bundler, or JS framework dependency.

## Non-Functional Requirements

**Maintainability** — All HTML output draws from the one shared template asset; skills must not fork divergent CSS/layout (directly addresses retro-01's "avoid divergent scaffolding" warning).
**Portability / shareability** — Output is self-contained (inline CSS/SVG), no external requests, no build step; a file opens correctly when sent to someone or double-clicked.
**Operational simplicity** — No new runtime dependency, server, or toolchain. Pure HTML/CSS/inline SVG (Sable's constraint).
**Token cost** — Acknowledged (the article's caveat): HTML costs more tokens than Markdown. Accepted for these artifacts, and bounded by the conservative-generation heuristic so HTML is produced only when it earns its place.
**Accessibility** — Renders use semantic HTML (headings, landmarks) and provide text alternatives for diagrams where feasible (Priya).

## Architecture Decisions

### Capability home: per-skill generation + shared template asset
**Choice**: Each producing skill (`spec`, `architect`, `review`) generates its own HTML, drawing styling/layout from one shared template asset under the plugin. `present` consumes the same asset for its HTML communications. No new central skill.
**Rationale**: Generation lives closest to the skill that knows *what* in its content is visual or navigable. A shared template asset gives consistency without a central renderer, satisfying retro-01's "share via a common template asset to avoid divergence." **Carve-out:** companion assets that preview *deliverable functionality* (system UI mockups) are the deliberate exception — they are system-specific and built standalone without the shared template, since they must look like the target system being built, not CPM2's documentation chrome. The shared-template rule governs artifact-presentation output (faithful renders, `present` communications, and documentation diagrams that explain the artifact).
**Alternatives considered**: Dedicated `cpm2:render` skill (rejected — re-implements discovery/regeneration plumbing and divorces generation from the content knowledge that decides what to render); hosting the *faithful render* inside `cpm2:present` (rejected — `present` is an audience-aware *transform* that reframes/drops content; a faithful render is a different verb. Note `present` emitting HTML for its *own* reframed output is consistent with its verb and is in scope); fully independent per-skill HTML with no shared asset (rejected — divergence risk).

### Three roles for HTML
**Choice**: HTML serves three distinct, explicitly-bounded roles: **substrate** (never — Markdown only), **companion asset** (visual content referenced by the Markdown, consumed downstream as a design target), **faithful render / HTML communication** (navigable view of a whole artifact, or `present`'s reframed output — both pure presentation, not consumed as data).
**Rationale**: Keeps the source-of-truth invariant intact while admitting the genuinely useful cases. Distinguishing "reference as a companion asset" from "consume as parsed data" resolves the apparent conflict with "never consume HTML."
**Alternatives considered**: Single role "HTML is only ever a projection" (rejected — couldn't accommodate mockups as first-class content); HTML-as-substrate (rejected — breaks `git diff`, couples downstream skills to markup parsing).

### Self-contained, build-free output
**Choice**: All HTML is a single self-contained file (inline CSS/SVG), no JS framework, no server, no build.
**Rationale**: Maximises shareability and operational simplicity; Tier 1 is static by definition. Interactivity is deliberately deferred to Spec 2.
**Alternatives considered**: Shared external stylesheet (rejected — breaks single-file shareability); bundled JS (rejected — that's Tier 2).

### Storage & reference convention
**Choice**: Companion assets at `docs/{type}/assets/{nn}-{slug}-{label}.html`; faithful renders at `docs/{type}/html/{nn}-{slug}.html`; `present` HTML communications alongside its Markdown output in `docs/communications/`. Markdown references assets by relative path. (Numbering globs match `*.md`, so HTML siblings never collide with the numbering scheme.)
**Rationale**: Predictable, stable paths downstream skills can resolve; keeps generated HTML out of the way of the Markdown artifact globs.
**Alternatives considered**: HTML as a sibling of the `.md` (rejected — clutters artifact directories); a single top-level `docs/html/` (rejected — loses per-type locality).

## Scope

### In Scope

- The shared HTML/CSS template asset (foundation reused by Spec 2 and `present`).
- Intrinsic companion-asset generation in `spec` and `architect`.
- On-request faithful render for `spec`, `architect` (ADR), and `review`.
- `present` HTML output for its reframed communications, consuming the shared template.
- The downstream consumption contract (`epics`/`do` treat assets as design targets) and the criteria-tagging guidance that goes with it.
- Regeneration-in-place and the generate-from-source-never-replace guarantee.

### Out of Scope

- Interactive / stateful dashboards (Spec 2).
- HTML for prose artifacts (`brief`, `discover`, `retro`, `quick`).
- HTML as a parsed data substrate.
- A new top-level skill; hosting the faithful render inside `present`.

### Deferred

- "Copy as Markdown/JSON" affordances on renders (revisit with Tier 2's export work).
- Companion-asset generation in skills beyond `spec`/`architect`.
- A companion-asset manifest/index.

## Testing Strategy

### Tag Vocabulary
Test approach tags used in this spec:

- `[unit]` — Unit tests targeting individual components in isolation
- `[integration]` — Integration tests exercising boundaries between components
- `[feature]` — Feature/end-to-end tests exercising complete user-facing workflows
- `[manual]` — Manual inspection, observation, or user confirmation
- `[tdd]` — Workflow mode: red-green-refactor loop. Composable with any level tag. Orthogonal — describes how to work, not what kind of test.

Note on honesty: much of this spec's behaviour is **LLM-driven skill behaviour** (does a skill choose to emit a mockup when content is visual?) and **visual output** — genuinely not unit-testable, so those criteria are `[manual]` with justification. Deterministic, mechanical parts (path conventions, self-containment, no-mutation) get automated tags via the existing bash test runner.

### Acceptance Criteria Coverage

| Requirement | Acceptance Criterion | Test Approach |
|---|---|---|
| Shared template foundation | A single shared HTML/CSS template asset exists under the plugin and is valid, self-contained HTML | `[integration]` |
| Shared template foundation | must NOT require any external network resource to render | `[integration]` |
| Companion-asset generation | When a spec/ADR requirement is inherently visual, the skill emits an HTML companion asset and references it from the Markdown | `[manual]` — LLM-driven generation judgement; no deterministic oracle |
| Companion-asset generation | must NOT generate a companion asset for non-visual requirements (conservative heuristic) | `[manual]` — judgement of "earns its place" |
| Stable asset storage | Generated companion assets are written to `docs/{type}/assets/{nn}-{slug}-{label}.html` and referenced by a relative path that resolves from the Markdown | `[integration]` — path/reference resolution is mechanical |
| Downstream consumption | An acceptance criterion that references a mockup is tagged `[manual]` or `[feature]` ("match the mockup"), never a markup-parsing test | `[manual]` — verified by reviewing `epics` output |
| Downstream consumption | `do` must NOT parse the companion HTML to extract requirements | `[manual]` |
| Faithful render | A spec/ADR/review renders to a navigable HTML view generated from its Markdown | `[manual]` — visual/navigational judgement |
| `present` HTML output | `present` can emit a reframed communication as styled HTML using the shared template | `[manual]` — reframed-content + visual judgement |
| `present` HTML output | `present` HTML output is self-contained and uses the shared template (not a forked stylesheet) | `[integration]` |
| Generate-from-source | A render or asset-generation step must NOT modify or replace the source Markdown file | `[integration]` — assert source file unchanged (hash) after generation |
| Self-contained output | A rendered view is a single file with no external CSS/JS/image references | `[integration]` — scan output for external refs |
| Regeneration in place | Re-rendering after a Markdown change updates the existing HTML rather than creating a duplicate | `[integration]` |

### Integration Boundaries

- **Markdown artifact → companion asset reference**: the relative path written into the Markdown must resolve to the asset on disk. (The seam `epics`/`do` rely on.)
- **Producing skill / `present` → shared template asset**: each consumer uses the one shared template; the contract is "use this asset, don't fork it."
- **Source Markdown → generated HTML**: one-directional (read-only on the Markdown); enforced by the no-mutation criterion.

### Test Infrastructure
Reuse the existing bash test runner (`test-helpers.sh`, isolated temp dirs) from the hook test suites — retro-01 confirms it's mature and extensible. New automatable checks needed: (1) a self-containment validator (no external refs in generated HTML), (2) a source-immutability check (Markdown hash unchanged after generation), (3) template-asset validity check. No new framework required.

### Unit Testing
Handled at the `cpm2:do` task level — story acceptance criteria drive coverage during implementation.
