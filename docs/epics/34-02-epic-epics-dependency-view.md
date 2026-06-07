# epics Dependency View

**Source spec**: docs/specifications/34-spec-interactive-tracking-dashboards.md
**Date**: 2026-06-02
**Status**: Complete
**Blocked by**: Epic 33-01-epic-shared-template-foundation, Epic 34-01-epic-status-tracking-dashboard

## Build the epics dependency view
**Story**: 1
**Status**: Complete
**Blocked by**: Epic 33-01-epic-shared-template-foundation, Epic 34-01-epic-status-tracking-dashboard
**Satisfies**: epics dependency view; Reuse the Spec 1 foundation; Build-free output; Read-only, export-only behaviour

**Acceptance Criteria**:

- The dependency view renders unblocked vs blocked stories correctly from epic-doc data [integration]
- The view is a self-contained HTML file using the Spec 1 shared template, generated from the Markdown epic docs [integration]
- The view must NOT modify the source epic Markdown (read-only) [integration]

### Add dependency-view generation to the epics skill
**Task**: 1.1
**Description**: Read the epic docs, render an unblocked/blocked dependency HTML view via the shared template, read-only on the source.
**Status**: Complete

**Retro**: [Inverse-of-production framing] The clean mental model was that `cpm2:epics` *writes* epic docs from a spec, and the dependency view is its inverse — a read-only projection over docs that already exist — so it slots in as an on-request mode (mirroring Spec 33's "Faithful Render (on request)" pattern) with a mutually-exclusive Input branch, not a change to the production loop. Two deliberate calls: pinned the readiness computation to `cpm2:do`'s exact hydration rule (Blocked-by all Complete → ready) so the view never disagrees with what `do` would actually pick up; and reused 34-01's ephemeral-scratch decision (`docs/plans/epics-dependency-view.html`, regenerated/untracked) rather than the numbered render path, because the view spans all epics and has no single `{nn}-{slug}`. Read-only is stated as a hard no-Edit/Write-to-docs/epics rule, directly satisfying the criterion.

### Write tests for the dependency view
**Task**: 1.2
**Description**: Assert correct unblocked/blocked rendering, self-containment + shared-template use, and source immutability. Covers the story's [integration] criteria.
**Status**: Complete

**Retro**: [A negative control earned its keep] The "ready story must NOT appear under blocked" assertion failed first time — not a fixture mistake but a real defect in the new `check_section_contains` helper: its line-based awk extraction grabbed every section at once when the HTML was single-line (as minified output is). Fixed the helper to flatten newlines and slice from the id marker to the first `</section>` via parameter expansion, so it's now newline-agnostic. The "renders unblocked vs blocked correctly" criterion was made testable without a browser by splitting it: a reference classifier (mirroring cpm2:do's hydration rule) proves the readiness logic from fixture epic-doc data, and `check_section_contains` proves the rendered view places each story under the right section — paired positive + negative (misplacement / absent section) assertions give it teeth. Source immutability reused the md_content_hash/check_source_unchanged pair across all three fixture epics + a mutation negative control. New suite test-epics-dependency-view.sh; reusable check_section_contains added to html-test-helpers.sh.

**Verification gate (Story 1)**: [All 3 criteria met] All three `[integration]` criteria verified by test-epics-dependency-view.sh (26 asserts, 0 failures; full runner 12 suites green): unblocked-vs-blocked correctness (reference classifier + section-placement with negative controls), self-containment + shared-template from Markdown epics, and source immutability across all fixture epics. Coverage rows 1–3 marked ✓. (2026-06-03)

---

## Add graceful schema tolerance
**Story**: 2
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: Graceful schema tolerance

**Acceptance Criteria**:

- Given an epic doc with a missing or partial field, the view renders what it can and visibly flags the gap rather than erroring [integration]

### Add schema-tolerant parsing to the dependency view
**Task**: 2.1
**Description**: Render partial data and flag unparseable fields instead of erroring.
**Status**: Complete

**Retro**: [Three failure modes, one "Needs attention" group] Schema drift takes a few concrete shapes — a story missing `**Status**`, a story missing/garbled `**Blocked by**`, and a file with no parseable stories at all — so the rule was specified per-shape rather than as a vague "be tolerant": missing status goes to a dedicated Needs-attention group (never silently guessed into ready/blocked, which would be worse than an obvious gap), unparsed deps render-and-flag, and an unparseable file costs one named line, not the view. The load-bearing invariant is "always emit a valid self-contained document, even if every epic is malformed" — that is what makes "renders what it can rather than erroring" testable as a not-broken output.

### Write tests for schema tolerance
**Task**: 2.2
**Description**: Fixture with missing/partial fields renders and flags the gap with no error. Covers the story's [integration] criterion.
**Status**: Complete

**Retro**: [Split "tolerant" into parse-side and render-side] The criterion bundles two guarantees, so the suite tested them separately. Parse-side: scanning a partial/unparseable tree exits 0 and the headless story surfaces with an *empty* status (proven by the tab-tab record) — plus a classify check that empty status → "unknown", which is the assertion that we don't silently mis-bucket a gap as ready/blocked. Render-side: the view is still valid + self-contained despite malformed input (the operational meaning of "rather than erroring"), and `check_section_contains` confirms the flagged story, the "status unparsed" badge, and the unparseable filename all land under Needs-attention, with a negative control that the flagged story is NOT under ready. Reused check_section_contains across both 34-02 stories. New suite test-epics-schema-tolerance.sh; full runner 13 suites green.

**Verification gate (Story 2)**: [Criterion met] The single `[integration]` criterion verified by test-epics-schema-tolerance.sh (15 asserts, 0 failures; full runner 13 suites green): the parser tolerates missing/partial fields without erroring, the view renders a valid self-contained document, and the gaps are visibly flagged under a Needs-attention group (flagged story + "status unparsed" badge + named unparseable file) rather than mis-bucketed. Coverage row 4 marked ✓. (2026-06-03)

---

## Lessons

### Smooth Deliveries

- **Story 1**: Framing the dependency view as the *inverse* of `cpm2:epics` (read-only projection over docs it normally writes) made it slot in cleanly as an on-request mode mirroring Spec 33's faithful-render pattern — a mutually-exclusive Input branch, not a change to the production loop.
- **Story 2**: Specifying schema tolerance per concrete failure-shape (missing status / unparsed deps / unparseable file) rather than as a vague "be tolerant" gave each shape a testable behaviour and a clear home in the Needs-attention group.

### Surprises & Discoveries

- **A negative control caught a real helper defect**: the "ready story must NOT be under blocked" assertion failed first run because `check_section_contains`'s line-based extraction grabbed all sections at once on single-line (minified) HTML. The fix — flatten newlines, slice via parameter expansion — makes the helper robust to both pretty-printed and minified output. Without the paired negative control, the helper would have shipped subtly broken.

### Patterns Worth Reusing

- **Reference-classifier + section-placement testing**: pin a readiness/classification rule to a small reference function (mirroring `cpm2:do` hydration), prove the rule from fixture data, then prove the rendered document places each item under the right section via `check_section_contains` with paired positive/negative assertions. This makes "renders X vs Y correctly" testable without a browser — directly reusable for 34-03's interactive/export views.
- **Don't-guess-on-gaps**: routing a missing field to an explicit "Needs attention / unknown" bucket (and asserting it is NOT silently classified) is a cleaner contract than best-effort guessing — the gap stays visible and trustworthy.
