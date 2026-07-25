# Retro: Execution Skill Behavioural Edits

**Date**: 2026-07-24
**Source**: docs/epics/40-02-epic-execution-skill-behaviour.md
**Stories**: 5/5 complete

## Summary

Spec 40's R2 verification triage and R6 scope constraint, across `do`, `quick`, and `epics`. Four of the five stories turned on the same thing: **the edit surface was not where the plan said it was**, in both directions. One story expected coupled sites and found none; one expected three and found six; one expected a phrase grep to identify removals and found the phrase sitting on a gate that had to stay. In every case a grep settled it in seconds and the prose estimate was wrong. The plan is a hypothesis about the surface, not a description of it.

## Observations

### Codebase Discoveries

Two findings, opposite in direction, same lesson. Retro 03's coupled-restatement warning was applied to Story 1 and came back empty: Step 5b is genuinely single-sourced in `do`, with no restatement in `ralph`. The warning was still worth acting on — it just resolved to "no work" rather than "hidden work", and confirming that took one grep.

The second is sharper. R2 names its removal target partly by *phrasing* — "confirm/re-check before reporting" — but `epics/SKILL.md:274` opens "Before presenting the task tree, read all per-epic coverage matrices" while being a gate that must be retained. A phrase-matching sweep would have deleted it. The artefact-production test, not the wording, has to do the classifying; the phrase is a hint about where to look, never the verdict. Directly relevant to R10's sweep in epic 40-04, which is specified in similarly phrase-shaped terms.

### Scope Surprises

Story 2's epic doc said the removal "cascades into three places". It was six textual sites, and the two tasks meant to split the work — remove the verification, re-anchor the proof recording — turned out to be one inseparable text region, because the block being removed and the block being re-anchored were contiguous prose. The task split described the *reasoning* correctly and the *edit boundary* not at all. Worth naming because it is a specific failure mode of decomposing prose edits: paragraphs do not partition the way functions do.

### Patterns Worth Reusing

Retro 11's propagation shape transferred a third time and should now be treated as settled practice: a byte-identical instruction at each site, verified by a single `grep | sort | uniq -c` that proves count and identity together. Story 4 added one refinement worth carrying forward — pairing the identical text with **one skill-specific siting sentence** at each end. That sentence is what let `do` satisfy its must-NOT (scope constraint vs. the inline-change breadcrumb gate) explicitly rather than by hope, and it costs nothing that the shared text has to give up.

Separately, the integration story earned its slot on evidence rather than convention. Criterion 3 — "every removal across Stories 2–3 carries an inline rationale" — spans two stories, so no per-story gate could evaluate it, and both stories passed their own gates with the gap present. A deliberate plan-level decision to consolidate rationales into one site was only falsifiable once both stories were done and checkable together.

## Recommendations

- Before an epic that edits prose across skills, grep the surface first and treat the epic doc's site count as an estimate. The cost is one command; the failure mode is a half-finished sweep that reads as complete.
- Going into R10's emphatic-language sweep (40-04): classify by consumer, not by matched token. Retro 11 already flagged multi-site duplication; this epic adds that a matched phrase can sit on something that must stay.
- When decomposing a prose edit into tasks, expect the task boundaries to be reasoning boundaries rather than edit boundaries, and record it plainly when two tasks collapse into one Edit rather than inventing a split that isn't there.
- Keep writing cross-story criteria into integration stories. This epic is a worked example of one catching what four story gates structurally could not.
- `do`'s Step 8 changes take effect only after the plugin is republished and reinstalled — this run executed the cache copy (v2.7.1), which still performed epic-level verification. Any check of whether the removal "worked" has to happen after a reinstall, not by reading the source.
