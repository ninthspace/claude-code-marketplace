# Dashboard Export & Interactivity

**Source spec**: docs/specifications/34-spec-interactive-tracking-dashboards.md
**Date**: 2026-06-02
**Status**: Complete
**Blocked by**: Epic 34-01-epic-status-tracking-dashboard, Epic 34-02-epic-epics-dependency-view

## Add copy-as-prompt / copy-as-JSON export
**Story**: 1
**Status**: Complete
**Blocked by**: Epic 34-01-epic-status-tracking-dashboard, Epic 34-02-epic-epics-dependency-view
**Satisfies**: Interactive affordances (optional enhancement); Build-free output; Read-only, export-only behaviour

**Acceptance Criteria**:

- When present, an export action produces a valid, copy-pasteable prompt / well-formed JSON [integration]
- Export uses inline vanilla JS only — no external script, framework, or build artifact [integration]
- No document interaction writes back to any source doc (read-only/export-only) [integration]
- Clicking export in a browser copies the expected content [manual] — interaction; browser harness deferred per spec

### Add copy-as-prompt/JSON export to the status document and epics view
**Task**: 1.1
**Description**: Inline-JS export buttons that turn a selection (e.g. "next: `/cpm2:do …`") into a prompt or JSON; export-only, never a write-back path.
**Status**: Complete

**Retro**: [One pattern, two consumers — specified once] The export affordance applies to *both* tracking documents (status full-picture doc and epics dependency view), so hand-rolling the JS in each skill would have forked the very thing Spec 1 forbids forking. Instead the canonical pattern lives once in the shared HTML Output convention as a new **Tier 2 export affordances** subsection — copy-as-prompt + copy-as-JSON, inline-only, read-only/export-only, data embedded at generation time, with a minimal data-attribute + delegated-handler shape — and both skills now reference it rather than restating it. Carefully scoped the Tier 2 carve-out to the two tracking surfaces so it doesn't contradict the existing "Tier 1: static only — no JavaScript" rule that still governs renders/communications/companion assets. The earlier ad-hoc copy-as-prompt mentions (added in 34-01/34-02) were replaced by the shared reference, which also folds in copy-as-JSON.

### Write tests for export output and isolation
**Task**: 1.2
**Description**: Assert valid prompt/JSON output, inline-JS-only (no external refs), and source immutability. Covers the story's [integration] criteria.
**Status**: Complete

**Retro**: [Tested the three deterministic criteria; left the genuinely-manual one manual] Three of the four criteria are `[integration]` and fell out cleanly: valid output (a new `check_valid_json` helper — python3 with a node fallback — over the JSON extracted by `extract_json_block`, plus a malformed negative control, and a grep that the data-prompt is a runnable `/cpm2:` command); inline-JS-only (`check_self_contained` on a doc with a real inline export handler + an external-script negative control); and read-only/export-only, proven two ways — source immutability across a fixture epic (with a mutation negative control) *and* a static check that the handler uses `navigator.clipboard.writeText` but contains no `fetch(`/`XMLHttpRequest` write-back path. The 4th criterion ("clicking export in a browser copies the expected content") stays `[manual]` because the spec deliberately defers a browser/JS interaction harness — no fake automation was invented for it. New suite test-dashboard-export.sh; full runner 14 suites green.

**Verification gate (Story 1)**: [All 4 criteria met] The 3 `[integration]` criteria (valid prompt/JSON output, inline-JS-only, read-only/export-only) verified by test-dashboard-export.sh (18 asserts, 0 failures; full runner 14 suites green). The 1 `[manual]` criterion (browser click copies expected content) met by inspection — the shared delegated handler copies the embedded `data-prompt`/JSON payload via `clipboard.writeText`; the actual in-browser click is the spec-deferred harness item, not invented automation. Coverage rows 1–4 marked ✓. (2026-06-03)

---

## Lessons

### Smooth Deliveries

- **Story 1**: Because 34-01 and 34-02 had already introduced copy-as-prompt as ad-hoc mentions, the cleanest move was to *lift* the pattern into the shared HTML Output convention once (a Tier 2 export-affordances subsection) and point both skills at it — folding in copy-as-JSON and erasing the incipient duplication in a single edit.

### Surprises & Discoveries

- **The Tier 1 "static only" rule needed an explicit carve-out, not a contradiction**: Tier 2 export JS coexists with the still-binding "renders/communications/companion assets are static" rule only because the new subsection is scoped precisely to the two tracking surfaces. Stating the boundary explicitly avoided a convention that says both "no JavaScript" and "here is JavaScript" without reconciliation.

### Testing Gaps Closed

- **Read-only/export-only proven two independent ways**: source immutability (generation/export never mutates a source doc) *and* a static-analysis check that the handler is clipboard-only (`writeText` present; no `fetch`/`XMLHttpRequest`). Either alone is weaker — together they cover both "the skill doesn't write back" and "the shipped JS *can't* write back."
- **Deferred-harness honesty**: the one `[manual]` criterion was met by inspection and explicitly recorded as such rather than dressed up with a fake automated test — matching the spec's deliberate deferral of a browser/JS harness.

### Patterns Worth Reusing

- **`check_valid_json` + `extract_json_block`**: extract an embedded `<script type="application/json">` snapshot and validate it (python3 → node fallback). Reusable for any future embedded-data export.
