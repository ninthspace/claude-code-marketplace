# Spec: HTML Tracking Dashboards (Tier 2)

**Date**: 2026-06-02
**Brief**: docs/discussions/19-discussion-html-artifact-projection.md
**Depends on**: docs/specifications/33-spec-html-artifact-projection.md (Spec 1 — the shared HTML template foundation must exist first)

## Problem Summary
CPM2's *tracking* surfaces are text. `cpm2:status` prints a deliberately terse, one-screenful narrative to stdout; `cpm2:epics` holds nested story/task lists with dependencies in Markdown. Both answer "where do things stand?" — but a quick glance summary can't hold the full picture, and reading state is not the same as *seeing* it. This spec keeps `status`'s fast inline output exactly as it is and adds an optional **standalone HTML document** that presents the comprehensive picture — full epic/story grid, blocked-work panel, dependency view, git activity, next steps — built on Spec 1's shared template foundation. The HTML may be **interactive or static** ("copy as prompt" affordances are an enhancement, not the point). **This remains a value-to-validate bet:** the first deliverable is a prototype evaluated against "does the full-picture document materially help tracking versus the inline narrative?" before the full build proceeds.

## Functional Requirements

### Must Have

- **`status` inline output unchanged.** `cpm2:status` continues to generate its existing terse stdout narrative as the default, primary behaviour — no regression.
- **Standalone full-picture HTML document.** `cpm2:status` can *additionally* generate a self-contained standalone HTML document presenting the comprehensive project picture: full epic/story completion grid, in-progress + blocked panel, RAG indicators, recent git activity, and recommended next steps. HTML-**native** — synthesised directly from the same read-only scan, no Markdown intermediate; ephemeral (regenerated on demand). The HTML holds the detail the one-screen narrative intentionally omits.
- **`epics` dependency view.** A projection over the Markdown epic docs rendering story/task dependencies (graph or unblocked-first ordering) showing what is ready to pick up. Epic docs remain the Markdown source of truth and are read-only.
- **Reuse the Spec 1 foundation.** The HTML document and the `epics` view consume Spec 1's shared HTML/CSS template asset for styling/layout — no forked or divergent scaffolding.
- **Build-free output.** Each document is a single self-contained file (inline CSS/SVG, and inline vanilla JS only where interactive) — no framework, bundler, server, or build step.

### Should Have

- **Interactive affordances (optional enhancement).** Where it adds value, the HTML document offers copy-as-prompt / copy-as-JSON export turning a selection (e.g. "next: `/cpm2:do docs/epics/05-…`") into copy-pasteable text — the article's "stay in the loop" pattern. "Interactive or otherwise": a purely static full-picture document is an acceptable deliverable.
- **Graceful schema tolerance.** When an epic doc's structure varies (missing status field, partial completion data), the document renders what it can and visibly flags what it couldn't parse, rather than breaking.
- **Read-only, export-only behaviour.** The document never writes back to epic docs; the only way state leaves it is an export. Mutation of epic docs stays exclusively with `cpm2:do`.
- **Saved on request, ephemeral by default.** The HTML document isn't persisted unless the user asks; otherwise it's regenerated on demand, matching `status`'s stateless nature.

### Could Have

- Filter/sort controls on the epic/story grid (by status, by epic).
- A combined project-overview document linking the `status` picture and the `epics` dependency view.

### Won't Have (this iteration)

- Write-back / in-document editing of epic docs (would break the Markdown-source-of-truth invariant; mutation is `do`'s job).
- Persisted document state or server-backed live updates.
- Removing or altering the existing `status` stdout behaviour.
- Tracking documents for non-tracking artifacts (Spec 1's faithful render covers those).
- A JS framework, bundler, or build pipeline.

## Non-Functional Requirements

**Validation-first** — The added value is unproven. The first story is a prototype evaluated against "does the full-picture document materially help tracking versus the inline narrative?" Full build is gated on that outcome. (Jordan's bet-framing.)
**Schema resilience** — The `epics` view parses epic-doc Markdown; it must tolerate reasonable structural drift and degrade gracefully (Bella/Tomas's coupling concern).
**No regression** — Adding HTML generation must not change or slow the default stdout path.
**Portability / shareability** — Self-contained single files, no external requests, no server (inherited from Spec 1).
**Operational simplicity** — No new runtime dependency or toolchain at generation time.

## Architecture Decisions

### `status` native + inline preserved; `epics` projected
**Choice**: `status` keeps its stdout narrative and *additionally* synthesises a standalone HTML document directly (no stored Markdown). The `epics` view is a projection over the existing Markdown epic docs.
**Rationale**: `status` is already ephemeral with no Markdown substrate, so a Markdown intermediate would be a fiction; epic docs are machine-consumed by `do`, so they stay the Markdown source of truth with HTML as a read-only projection. (The two-mode artifact model from Spec 1.) Preserving the inline output avoids any regression to the fast path.
**Alternatives considered**: Replacing stdout with HTML (rejected — Chris's explicit requirement to keep inline output); a stored Markdown status artifact then rendered (rejected — invents a substrate nothing consumes); HTML epic docs (rejected — `do` mutates them).

### Extend Spec 1's foundation; interactivity is a thin optional layer
**Choice**: The documents build on Spec 1's shared styling/layout asset; interactivity, where present, is inline vanilla JS as a thin optional layer.
**Rationale**: Avoids divergent scaffolding (retro-01); keeps Tiers 1 and 2 visually consistent; isolates the new risk (JS state) to a thin, well-bounded, *optional* layer so a static document is always a valid fallback.
**Alternatives considered**: A JS framework/SPA (rejected — breaks single-file shareability and build-free constraint); mandatory interactivity (rejected — Chris's "interactive or otherwise").

### Read-only + export-only reconciles interactivity with the invariant
**Choice**: Documents never mutate source docs; any interaction only ever produces an export (copy-as-prompt/JSON).
**Rationale**: This is how an interactive HTML view stays compatible with "HTML is never the consumed substrate" — the user acts by copying a prompt back into a CPM skill, not by the document editing artifacts.
**Alternatives considered**: In-document editing with write-back (rejected — couples HTML to the substrate, exactly what Spec 1 forbids).

## Scope

### In Scope

- Preserving `status`'s existing inline stdout output unchanged.
- The standalone full-picture `status` HTML document (native synthesis) — including a **validation prototype as the first deliverable**.
- The `epics` dependency / unblocked-work view (projection).
- Optional copy-as-prompt / copy-as-JSON export.
- Reuse of Spec 1's shared template + a thin optional inline-JS layer.
- Graceful schema-tolerance and read-only/export-only guarantees.

### Out of Scope

- Changing or replacing the `status` stdout behaviour.
- Write-back / editing of epic docs from a document.
- Persisted or server-backed live state.
- Tracking documents for non-tracking artifacts (Spec 1's job).
- Frameworks, bundlers, build pipelines.

### Deferred

- Combined project-overview document.
- Advanced filtering/sorting.
- Tracking views for additional artifact types.
- A browser/JS test harness for automated interaction testing (decide post-validation — see Testing).

## Testing Strategy

### Tag Vocabulary
Test approach tags used in this spec:

- `[unit]` — Unit tests targeting individual components in isolation
- `[integration]` — Integration tests exercising boundaries between components
- `[feature]` — Feature/end-to-end tests exercising complete user-facing workflows
- `[manual]` — Manual inspection, observation, or user confirmation
- `[tdd]` — Workflow mode: red-green-refactor loop. Composable with any level tag. Orthogonal.

Honesty note: visual/interactive behaviour and "does the document help" are `[manual]`. Deterministic data work (parsing completion counts, valid JSON export, self-containment, no source mutation, stdout-unchanged) is automatable via the existing bash runner. Automated *interaction* testing would need a new browser/JS harness — deliberately deferred until validation proves the feature worth that investment.

### Acceptance Criteria Coverage

| Requirement | Acceptance Criterion | Test Approach |
|---|---|---|
| Inline output unchanged | `cpm2:status` still produces its stdout narrative; the default path is unchanged | `[integration]` — assert stdout path produces narrative without HTML |
| Standalone HTML document | `cpm2:status` can emit a self-contained full-picture HTML document using the Spec 1 shared template | `[integration]` — self-containment + template use are mechanical |
| Standalone HTML document | The document's completion counts agree with the data the stdout narrative reports | `[integration]` — same scan data, deterministic |
| Standalone HTML document | must NOT save the document unless the user asks (ephemeral default) | `[manual]` |
| `epics` view | The dependency view renders unblocked vs blocked stories correctly from epic-doc data | `[integration]` — dependency resolution is deterministic |
| `epics` view | must NOT modify the source epic Markdown (read-only) | `[integration]` — source hash unchanged |
| Schema tolerance | Given an epic doc with a missing/partial field, the view renders what it can and flags the gap rather than erroring | `[integration]` |
| Export (optional) | When present, an export action produces a valid, copy-pasteable prompt / well-formed JSON | `[integration]` — output validation |
| Export (optional) | Clicking export in a browser copies the expected content | `[manual]` — interaction; browser harness deferred |
| Build-free output | Documents use inline assets only — no external script/CSS, framework, or build artifact | `[integration]` — scan for external refs |
| Read-only/export-only | No document interaction writes back to any source doc | `[manual]` + `[integration]` (source immutability) |
| Validation prototype | The prototype is evaluated against "materially helps tracking vs the narrative" before full build proceeds | `[manual]` — explicit go/no-go judgement |

### Integration Boundaries

- **Epic-doc Markdown → `epics` view**: read-only parse of story/task/status/dependency fields; the seam where schema drift bites — must degrade gracefully.
- **`status` scan data → (stdout narrative AND HTML document)**: both draw from one read-only scan; their numbers must agree and the stdout path must be unaffected.
- **Document → CPM skills**: one-directional via export only (copy-as-prompt); never a write-back path.
- **Spec 1 shared template → Tier 2 documents**: consumed, never forked.

### Test Infrastructure
Reuse the existing bash test runner (`test-helpers.sh`) for the automatable checks (stdout-unchanged, self-containment, data-agreement, source immutability, JSON validity, schema-tolerance fixtures). **A browser/JS interaction harness (e.g. Playwright/jsdom) is *not* adopted now** — flagged as a deferred decision contingent on the validation prototype proving the documents worth that investment. Until then, interaction is `[manual]`.

### Unit Testing
Handled at the `cpm2:do` task level — story acceptance criteria drive coverage during implementation.
