# Retro: Pivot the Three Interpretations

**Date**: 2026-07-25
**Source**: docs/epics/41-02-epic-pivot-interpretations.md
**Stories**: 4/4 complete

## Summary

`status`, `epics` and `present` now publish their human-facing outputs as artifacts instead of writing local HTML, and AD5's open clipboard question is settled empirically rather than assumed. All 11 coverage rows verified, full suite green throughout. Two lessons dominate: **the epic surveyed the skill surface but not the test surface**, and **a criterion quoting spec text was copied to three stories whose skill shapes made it unsatisfiable in two different directions**.

## Observations

### Criteria Gaps

- **A criterion quoting spec text still has to be checked against each skill it lands on.** R5's *"a row in `docs/artifacts/index.md` and an `**Artifacts**:` backlink on the source artifact"* was copied verbatim onto all three pivot stories. It failed twice, oppositely: `status` and `epics` have **no** source artifact — their inputs are every epic in the project, and writing a backlink into those would break the read-only guarantee both skills state — while `present` already had one under a *different name*, the singular `**Artifact**` field predating the register and holding the same URL for the same reason. The spec's phrase presupposes a skill shape only one of the three has. Verbatim propagation is right for *preserving* specificity (that is why the fidelity rule exists) and wrong as a substitute for checking that the sentence is true where it lands. Both resolutions needed a user decision mid-execution, which is exactly the cost of finding this at execution time rather than at breakdown.

### Scope Surprises

- **The surface survey covered `cpm/skills/` and stopped there.** Story 1's breakdown correctly found four secondary sites beyond the one the spec named — and missed `test-status-dashboard.sh` entirely, an archived-epic suite asserting the retired behaviour end to end, which turned the runner red four assertions deep the moment Phase 4 changed. A behaviour worth pivoting is almost always a behaviour someone already wrote tests for; `cpm/hooks/tests/` belongs in the same survey as the skill files. This is the fourth consecutive epic where the named site was not the only site, and the first where the extra sites were executable.

### Patterns Worth Reusing

- **Surveying the test surface ahead of the work changes the outcome, not just the timing.** Applying Story 1's own lesson before Story 2 found `test-epics-dependency-view.sh` and `test-epics-schema-tolerance.sh` before they broke — and unlike the status suite, most of their content (readiness classification, schema tolerance, the epic-docs-unchanged proof) tests rules the story had to **preserve**. Re-pointing their fixtures at a body fragment validated by `check_valid_fragment` kept coverage that deletion would have thrown away. Discovering a doomed suite at survey time gets you a choice; discovering it at test-run time gets you a cleanup. The two outcomes in one epic — one suite deleted, two reworked — are the evidence that the judgement is worth making rather than defaulting either way.

- **A validator built one epic ahead earned its place on first use.** `check_valid_fragment` was written in 41-01 with no caller, which is normally a smell. It became the mechanism that let two suites survive the medium change rather than be deleted.

- **Publish the diagnostic, don't reason about it.** AD5 was written as *"unverified, with a stated fallback"* — a hedge that would have shipped into ten propagation sites in 41-03. One published page and two clicks settled it in minutes. Where a question has no local oracle and the cost of testing is one artifact, test it.

### Codebase Discoveries

- **`docs/artifacts/index.md` did not exist.** Three epics had been enforcing a register-and-backlink invariant — the one AD1 calls the *only* durable trace for `status` and `epics` — against a file nobody had ever created. Story 4's publish wrote the first row. A rule with no instance is indistinguishable from a rule nobody follows, and nothing in the pipeline noticed.

- **`permissions.query("clipboard-write")` is a diagnostic, not a gate.** The probe reported that query **unsupported** on the tested engine while `writeText` succeeded inside the cross-origin frame and the paste confirmed it. Code that branched on the permissions query to decide whether to render a copy control would have disabled a working affordance on exactly the engines where it works.

## Recommendations

- **Add `cpm/hooks/tests/` to the surface survey in `cpm:epics`.** For any story that changes documented behaviour, glob the test directory for suites referencing the behaviour and decide per suite: rework (it covers surviving rules) or delete (it covers only the retired path). Both outcomes occurred in this epic.
- **`test-dashboard-export.sh` should be added to epic 41-04's scope.** It builds its fixture from `template.html` and asserts `check_uses_shared_template` / `check_valid_html`, so it breaks when 41-04 prunes those — not when 41-02 acted, which is why it was left alone here. Rework rather than delete: its payload-well-formedness, inline-only-JS and no-write-back assertions cover affordances that survive and are now verified working.
- **Check `check_counts_agree` and `check_communication_path` together in 41-04.** Both are now callerless: 41-04 already owns `check_communication_path`, and `check_counts_agree` lost its only caller when `test-status-dashboard.sh` was deleted here.
- **At breakdown, read each spec-quoted criterion once per story it lands on** and ask whether its nouns exist in that skill. Two of three failed that test here, and both failures were visible from the skill file alone.
- **Register the first artifact early in any project adopting the register.** An empty invariant is not a verified one.
