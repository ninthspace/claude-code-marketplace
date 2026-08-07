# Retro: Review Skill Re-shaping

**Date**: 2026-07-25
**Source**: docs/epics/40-03-epic-review-skill-reshaping.md
**Stories**: 3/3 complete

## Summary

Spec 40's R1 (review half) and R8, both landing in `cpm/skills/review/SKILL.md`. Story 1 was delivered early during epic 40-01, so this run covered the find/filter separation and its integration check. Both surviving observations are about **seams** — one behaviour stated in more than one place, one behaviour split across two owners — and both were caught by looking wider than the site the epic named. Neither would have been found by editing where the epic pointed.

## Observations

### Codebase Discoveries

The epic named `:149` as the site of `review`'s 2–5 finding cap. The cap was actually stated at three: `:149` (per-agent), `:461` ("Not every story needs 5 findings"), and `:465`, which carried a **different** pair of numbers — 3-8 for a story review, 5-15 for an epic — scoped to totals rather than per agent.

That third site changed the work. Criterion 2 said curation to "2–5 findings" moves to the filtering step, but the filtering step sees the *consolidated* set. Applied literally it would have cut the surfaced total from today's 6–20 down to 2–5 — fewer than before, and fewer than the file's own guidance, making R8 *reduce* what surfaces when R8 exists because Opus 5 already surfaces too little. Surveying before editing turned a silent inversion of the requirement's purpose into a decision Chris made explicitly (re-scope to `:465`'s targets). Had the cap been edited only where the epic pointed, the change would have shipped looking correct and behaving backwards.

### Patterns Worth Reusing

The integration story found a defect that was structurally invisible to both stories that created it. Story 1 owned the subagent prompt-contents list at `:142`; Story 2 owned the coverage-first finding instruction at `:149`. Each passed its own gate. But the prompt list never carried the finding instruction, so a spawned subagent would still have curated on its own and Step 2b would have received a pre-filtered set — defeating the separation the epic exists to create.

Worth stating as a general shape: when two stories edit *different* parts of one control flow, the bug lives in the handoff between them, and neither story's criteria can reach it. This is the second consecutive epic where the integration story earned its cost this way (see retro 12), which is enough to stop treating those stories as ceremony.

## Recommendations

- Keep writing integration stories with criteria phrased as *end-to-end* properties ("the full finding set is captured somewhere the filtering step can read"), not as a checklist of the prior stories' outputs. The end-to-end phrasing is what made the `:142` gap visible.
- When a requirement moves a number from one step to another, check the number's **scope** as well as its value. Per-agent and per-review are different units, and a value that is correct in one is wrong in the other.
- Treat an epic doc's named site as the starting point of a survey, not its result. Two epics running (retro 11, and this one) have found more sites than the doc listed, and this time the extra site held contradictory content rather than a duplicate.
- Uncurated findings are deliberately session-only — R8's must-NOT froze `review`'s document schema, so the full set is read by Step 2b and never written to disk. If a future spec wants an audit trail of what was cut, that needs a schema change and should be raised as such rather than assumed.
