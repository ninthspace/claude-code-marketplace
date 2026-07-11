# Retro: Shared Template Foundation (HTML Artifact Projection)

**Date**: 2026-06-02
**Source**: docs/epics/33-01-epic-shared-template-foundation.md
**Stories**: 2/2 complete

## Summary

Epic 33-01 delivered the foundation for HTML artifact projection: a bash HTML test toolkit (self-containment validator, source-immutability check, template-validity check) and the single shared, self-contained HTML template asset plus its consume-don't-fork conventions. Both stories landed cleanly. The one lesson worth feeding forward emerged *after* delivery, during human review of the `[manual]` documentation criterion: the spec's "every HTML output uses the shared template" was too absolute, and the gap triggered a pivot.

## Observations

### Smooth Deliveries

- Story 1: The self-containment and source-immutability checks slotted into the existing bash runner as a sourceable helper library plus one test suite — the mature `test-helpers.sh` harness carried the `[integration]` coverage with no new framework. Reusing established test infrastructure keeps new automatable checks cheap.

### Criteria Gaps

- Cross-cutting (surfaced at the Story 2 `[manual]` gate, then pivoted): the shared-template requirement read as an absolute — "every HTML output uses the shared template" / "consume the shared template, do not fork it" — but it was only ever true for *artifact-presentation* output. Human review caught that a companion asset previewing **deliverable functionality** (a mockup of the system being built) is system-specific and must wear the target system's design, not CPM2's documentation chrome. The fix was an explain-vs-preview carve-out cascaded into the spec, epic 33-02, and the shared conventions doc. The `[manual]` documentation criterion was the right place to catch it — but only because a human actually read the prose, not just confirmed the elements were present.

### Patterns Worth Reusing

- Story 2: Authoring design quality *once* into a single canonical template (frontend-design-guided) with placeholder tokens — and forbidding per-render forks — gives downstream epics a consume-don't-fork foundation. The hard self-containment constraint cleanly resolved the "distinctive fonts vs no external requests" tension via a characterful system-serif stack and CSS-gradient texture rather than web fonts.

## Recommendations

- **State absolutes with their scope.** When a spec says "every X does Y," pressure-test it for carve-outs before it cascades. Here, "every HTML output uses the shared template" needed the qualifier "presenting a CPM2 artifact." Catching scope-of-absolute issues at spec time avoids a downstream pivot.
- **Treat `[manual]` documentation criteria as genuine review gates.** The carve-out was invisible to the automated checks (the conventions doc had every required element); only reading the prose surfaced it. For `[manual]` criteria, schedule the human read explicitly rather than letting structural-presence checks stand in for it.
- **Distinguish "explains the artifact" from "is a preview of the deliverable."** This explain-vs-preview line is the reusable test for any future visual-output decision: documentation visuals inherit shared chrome; deliverable previews stay system-specific. Carry it into epic 33-02's companion-asset work.
- **Author shared design assets once, under the hardest constraint.** Baking design quality into a single self-contained template (no external fonts/CDN) up front is cheaper than per-render styling and is what makes the no-fork rule enforceable downstream.
