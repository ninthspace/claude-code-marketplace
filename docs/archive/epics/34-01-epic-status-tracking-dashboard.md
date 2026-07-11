# status Tracking Dashboard

**Source spec**: docs/specifications/34-spec-interactive-tracking-dashboards.md
**Date**: 2026-06-02
**Status**: Complete
**Blocked by**: Epic 33-01-epic-shared-template-foundation

## Build and evaluate the status dashboard validation prototype [plan]
**Story**: 1
**Status**: Complete
**Blocked by**: Epic 33-01-epic-shared-template-foundation
**Satisfies**: Validation-first

**Acceptance Criteria**:

- A prototype standalone HTML dashboard is produced from a real `status` scan and evaluated against "does the full-picture document materially help tracking versus the inline narrative?" [manual] — explicit go/no-go judgement
- The full build must NOT proceed until the prototype evaluation records a go decision [manual]

### Build the status dashboard prototype from a real status scan
**Task**: 1.1
**Description**: A minimal full-picture HTML document built from real status data to test the value hypothesis; throwaway, not production-wired.
**Status**: Complete

### Evaluate the prototype and record a go/no-go decision
**Task**: 1.2
**Description**: Assess "materially helps vs the narrative"; the recorded decision gates Story 2 and the rest of the Tier 2 build.
**Status**: Complete

**Evaluation**: [go] The full-picture dashboard (RAG glance, blocked panel, complete 50-epic grid, git activity, next-step copy-as-prompt) materially helps tracking versus the terse stdout narrative — Tier 2 build proceeds (Story 2, then epics 34-02/34-03). (2026-06-03)

**Retro**: [Validation paid off] The throwaway-prototype-plus-go/no-go shape worked exactly as designed: a real scan built against the Spec 1 shared template surfaced the value proposition concretely (the copy-as-prompt affordance, in particular, let the go/no-go judge the genuine Tier-2 idea rather than a static strawman), and the user's go was an informed call on a working artifact, not a spec paragraph. Both criteria were `[manual]` by design — no test task — and the existing self-contained/valid-HTML/shared-template validators doubled as a free sanity gate on the prototype, so Story 2 inherits proven build mechanics. (2026-06-03)

---

## Generate the standalone full-picture status HTML document
**Story**: 2
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: Standalone full-picture HTML document; status inline output unchanged; Reuse the Spec 1 foundation; Build-free output; Saved on request, ephemeral by default

**Acceptance Criteria**:

- `cpm2:status` can additionally generate a self-contained full-picture HTML document presenting epic/story completion grid, in-progress + blocked panel, RAG indicators, recent git activity, and recommended next steps, using the Spec 1 shared template [manual] — visual/content judgement
- The document is self-contained — a single file with no external script/CSS references — and uses the shared template, not a forked stylesheet [integration]
- The document's completion counts agree with the data the stdout narrative reports [integration]
- `cpm2:status` still produces its stdout narrative; the default path is unchanged [integration]
- The HTML document must NOT be saved unless the user asks (ephemeral default) [manual]

### Add full-picture HTML document generation to cpm2:status
**Task**: 2.1
**Description**: Emit the document (completion grid, blocked panel, RAG, git activity, next steps) via the shared template, alongside the unchanged stdout narrative.
**Status**: Complete

**Retro**: [Reused the prototype's shape] Phase 4 of the status skill is essentially the validated prototype's structure promoted to a documented behaviour — RAG/blocked/grid/git/next-step sections, shared-template consumption, Tier 2 inline-JS export affordance. Two design calls: made it strictly opt-in (skip-by-default, triggered by an `html`/`dashboard`/"full picture" argument) so the stdout default path is provably untouched, and explicitly deferred the file-path + ephemeral/save lifecycle to Task 2.2's State Management edit so this task stayed scoped to generation. HTML-native synthesis (no Markdown intermediate) is the key distinction from Spec 33's renders — there is no stored status artifact to render from.

### Wire ephemeral / save-on-request behaviour
**Task**: 2.2
**Description**: Document not saved unless the user asks; regenerate on demand by default, matching status's stateless nature.
**Status**: Complete

**Retro**: [Resolved the "saved vs rendered" ambiguity] The criterion "must NOT be saved unless the user asks" tensions against needing a file on disk to open HTML in a browser. Resolved by reading the spec's own words ("isn't persisted… otherwise regenerated on demand"): the ephemeral scratch write to `docs/plans/status-dashboard.html` is the *rendering mechanism* (overwritten in place, untracked, no `{nn}`, never committed), explicitly distinct from *persisting* a durable user-owned artifact — which happens only on a second, explicit request. Two gates protect the stateless default: the user must ask for HTML at all, then ask again to keep it.

### Write tests for the status document
**Task**: 2.3
**Description**: Assert self-containment, shared-template use, data-agreement with the narrative, and that the stdout path is unchanged. Covers the story's [integration] criteria.
**Status**: Complete

**Retro**: [Testing gap surfaced, then closed] Two criteria resisted pure data tests because a bash suite can't invoke the skill: "stdout path unchanged" and the ephemeral default. Rather than skip them, guarded the *documented contract* against the SKILL.md source (greps for the preserved Report Format, the opt-in gating, and the ephemeral/scratch-path wording) — these catch a real regression (someone making HTML the default). For self-containment, the suite deliberately exercises a document carrying inline Tier 2 JS plus an external-script negative control, proving `check_self_contained` passes inline scripts and rejects external ones. Data-agreement got a new reusable `check_counts_agree` helper plus an independent fixture scanner, so the rendered figure is checked against scan-derived counts (not a self-referential constant) with a disagreement negative control. New suite test-status-dashboard.sh; whole runner stays green.

**Verification gate (Story 2)**: [All 5 criteria met] 3 `[integration]` criteria (self-containment + shared-template, count-agreement, stdout-unchanged) verified by test-status-dashboard.sh (20 asserts, 0 failures; full runner 11 suites green). 2 `[manual]` criteria (full-picture document via shared template; ephemeral-default not-saved-unless-asked) self-assessed against the Phase 4 + State Management additions to the status skill. Coverage rows 3–7 marked ✓. (2026-06-03)

---

## Lessons

### Smooth Deliveries

- **Story 1**: The throwaway-prototype + explicit go/no-go shape validated the Tier 2 bet on a working artifact rather than a spec paragraph — the copy-as-prompt affordance let the go/no-go judge the genuine interactive proposition, and the existing self-contained/valid-HTML/shared-template validators doubled as a free sanity gate.
- **Story 2**: Phase 4 reused the validated prototype's structure wholesale, so implementation was mostly promoting a proven shape to documented behaviour. Making HTML strictly opt-in (skip-by-default) gave a provably-untouched stdout path with almost no extra wording.

### Surprises & Discoveries

- **HTML-native, no Markdown intermediate**: Unlike Spec 33's faithful renders (which read a source Markdown), `status` has no stored substrate — the document is synthesised from the same live scan that feeds the narrative. This made the source-immutability validator irrelevant here and shifted the integrity check to *count-agreement between two outputs of one scan* instead.

### Testing Gaps Closed

- **Skill-behaviour criteria with no runtime harness**: "stdout unchanged" and "ephemeral default" can't be exercised by a bash suite that doesn't run the skill. Guarding the documented contract against the SKILL.md source (grepping for the load-bearing guarantees) is a pragmatic substitute that still catches the regression that matters — a future change making HTML the default or dropping the stdout report. Worth reusing for the upcoming 34-02 `epics` dependency view (also skill-driven).

### Patterns Worth Reusing

- **Reusable count-agreement validator**: `check_counts_agree` + an independent fixture scanner checks a rendered figure against scan-derived counts (not a self-referential constant), with a disagreement negative control giving it teeth. Directly applicable to 34-02/34-03's tracking views.
