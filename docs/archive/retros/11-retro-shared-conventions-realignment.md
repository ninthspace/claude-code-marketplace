# Retro: Shared Conventions Realignment

**Date**: 2026-07-24
**Source**: docs/epics/40-01-epic-shared-conventions-realignment.md
**Stories**: 6/6 complete

## Summary

The first epic of spec 40's Opus 5 alignment landed all five shared-convention changes (R1, R3, R4, R5, R9) plus their propagation into eleven skill files. The dominant lesson is about *reach*: a convention only takes effect where a skill points at it, and drifted language only disappears where you look for every instance of it. Both cost more sites than the epic's task breakdown anticipated.

## Observations

### Smooth Deliveries
Story 3's two-task split fell out of the criteria themselves — one criterion specified *placement* ("near the end of the conventions document"), which made the second edit site self-evident. Criteria that name a location decompose into tasks without effort; criteria that name only a property do not.

### Scope Surprises
Story 6's cross-reference check pulled in work from a downstream epic. Amending the shared `Subagent Delegation` convention immediately invalidated a line in `review/SKILL.md` that epic 40-03 owned, and the integration story surfaced it a full epic before its planned slot. Shared-first sequencing creates these dangling contradictions by construction — when a convention changes, every skill quoting the old position is stale the moment the edit lands, not when its own epic runs. Worth scheduling per-skill fixes as close to their shared-convention change as the dependency graph allows, or accepting that integration stories will reach across epic boundaries.

### Criteria Gaps
"The ten `xhigh` facilitation skills are re-assessed" set a direction without destinations, so seven new effort levels were chosen during implementation rather than agreed during planning. A criterion satisfiable by *any* outcome is not testable as written. When a story's work is a judgement call, the criterion should either carry the decision or name the rule that produces it.

### Codebase Discoveries
Two findings, both about reach. Emphatic framing was duplicated across a section intro *and* its list lead-in, so a single-site reading of the criterion would have left half the drift standing — relevant directly to R10's sweep, where a grep-and-fix pass will hit the same duplication. Separately, session-start loading of the shared conventions does not make a new section bite: skills apply conventions they explicitly reference, so an added convention needs a one-line pointer at each point of use or it is inert text.

### Patterns Worth Reusing
Story 4's shape transferred to Story 5 unchanged and is worth treating as the default for any shared convention needing propagation: one section in `skill-conventions.md`, plus a byte-identical one-line reference at each point of use. A single `grep | sort | uniq -c` then verifies both the count and the identity that the Consistency NFR asks for — the propagation and its test come free together.

## Recommendations

- Treat "add a shared convention" as *section + per-skill pointer + grep check*, not as a single edit. Size the story accordingly.
- Before R10's sweep, expect emphatic language at multiple sites per rule; a per-instance pass beats a per-rule one.
- When a criterion asks for re-assessment, judgement, or calibration, pin the expected outcome or the deciding rule into the criterion during `cpm:epics` — otherwise the decision silently relocates to execution.
- Epics 40-02 and 40-03 both quote conventions this epic changed. Re-read their stories against the amended text before starting, rather than at their own integration gates.
- 40-03 Story 1 is already delivered. Start 40-03 at Story 2.
