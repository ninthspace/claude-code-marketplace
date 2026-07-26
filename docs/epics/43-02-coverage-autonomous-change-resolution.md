# Coverage Matrix: Autonomous Change Resolution

**Source spec**: docs/specifications/43-spec-ralph-autonomous-stalls.md
**Epic**: docs/epics/43-02-epic-autonomous-change-resolution.md
**Date**: 2026-07-26

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|---|---|---|---|---|---|
| 1 | FR1 | Autonomous branch on `do:476`: inline edit / retro observation / amend the epic under execution. `/cpm:pivot` is never invoked. | `do:476` carries an autonomous branch naming all three dispositions (inline edit / retro observation / amend the epic under execution) and stating `/cpm:pivot` is never invoked | Story 1 | `[integration]` | ✓ |
| 2 | FR1 | Autonomous branch on `do:476`: inline edit / retro observation / amend the epic under execution. `/cpm:pivot` is never invoked. | End-to-end read of the finished `:476` block: the three dispositions do not overlap or leave a change type unhandled | Story 1 | `[manual]` | ✓ |
| 3 | FR1 (must NOT) | must NOT introduce any `AskUserQuestion` in that gate's autonomous path | must NOT introduce any `AskUserQuestion` in that gate's autonomous path | Story 1 | `[integration]` | ✓ |
| 4 | FR2 | Wrong-vs-unmet guard: only a *wrong* criterion may be amended, never a merely *unmet* one. This is the load-bearing safety property — without it the loop has a legal move that converts a failing story into a passing one. | Amendment requires a citable contradiction — a `file:line`, a named spec requirement, or a conflicting criterion in the same epic | Story 1 | `[manual]` | ✓ |
| 5 | FR2 | Wrong-vs-unmet guard: only a *wrong* criterion may be amended, never a merely *unmet* one. | A worked separating case — a criterion plausibly both wrong and unmet — is stated with its correct disposition (decline, mark blocked) | Story 1 | `[manual]` | ✓ |
| 6 | FR2 (must NOT) | must NOT permit amendment on evidence of the form "tests fail" or "could not implement" | must NOT permit amendment on evidence of the form "tests fail" or "could not implement" | Story 1 | `[manual]` | ✓ |
| 7 | AD3 | the epic doc `cpm:do` currently has open, plus its companion coverage matrix (`docs/epics/{parent}-{seq}-coverage-{slug}.md`) — both files `cpm:do` already writes to | The blast radius is stated as the open epic doc plus its companion coverage matrix, with everything upstream deferred | Story 1 | — | ✓ |
| 8 | FR3 | `**Pivot deferred**` breadcrumb carrying change, target artefact, story number, date, citation. | The `**Pivot deferred**` format is defined once and names all five fields: change, target artefact, story number, date, citation | Story 2 | `[integration]` | ✓ |
| 9 | FR5 | Resolve the `do:64` contradiction. | `do:64` permits the epic-scoped amendment and still forbids edits to the spec and other upstream artefacts | Story 2 | `[manual]` | ✓ |
| 10 | NFR7 | existing `.cpm-progress-*.md` files, existing `.claude/ralph-loop.local.md` files, and the `**Retro applied**` / `**Inline change**` formats parse unchanged | The `**Retro applied**` and `**Inline change**` field definitions are unchanged, and `**Pivot deferred**` is a distinct field name that `cpm:retro`'s `**Inline change**` scan cannot match | Story 2 | `[integration]` | ✓ |
| 11 | FR4 | Amendments reported as their own run-summary block, distinct from the deferred-retro list. | `do` Step 8's Report step defines an amendments block distinct from the deferred-retro list | Story 3 | `[integration]` | ✓ |
| 12 | FR4 (must NOT) | must NOT fold amendments into the existing `**Retro applied**` deferred list | must NOT fold amendments into the existing `**Retro applied**` deferred list | Story 3 | `[manual]` | ✓ |
| 13 | FR6 | All four encoding sites change together; the generated prompt is operative. | `ralph`'s override table has a Change Type Decision row **and** `ralph:91`'s generated prompt contains the clause — asserted together in one test, so neither can land alone | Story 4 | `[integration]` | ✓ |
| 14 | FR6 | All four encoding sites change together; the generated prompt is operative. | The four encoding sites are asserted present together in one test, so a partial landing fails | Story 5 | `[integration]` | ✓ |
| 15 | AD5 | a short clause in `ralph:91` naming the behaviour and its guard, with the detail living in `cpm:do` | The prompt clause names the behaviour and its guard, with detail deferred to `cpm:do` | Story 4 | — | ✓ |
| 16 | AD5 (must NOT) | restate the full rule in the prompt (rejected — budget, and it creates the drift FR14 exists to prevent) | must NOT restate the full rule in the generated prompt | Story 4 | — | ✓ |
| 17 | FR12 | Make the `ralph:91` prompt budget honest (claims ~1100 chars, measures 1,477). | `ralph:91`'s stated character budget matches its actual length | Story 4 | — | ✓ |
| 18 | NFR6 | same epics plus same config yields the same prompt. | The generated prompt remains a pure function of its interpolated variables — same epics plus same config yields the same prompt | Story 4 | — | ✓ |
| 19 | FR6 (cross-site) | All four encoding sites change together; the generated prompt is operative. | A single end-to-end read of `do:476`, `do:64`, `do` Step 8, the `ralph` override row and the `ralph:91` prompt clause confirms they describe one coherent behaviour with no contradiction between sites | Story 5 | `[integration]` | ✓ |

## Notes

**Row 10, inline change (2026-07-26).** The criterion originally read *"…parse unchanged in `cpm:status` and `cpm:retro`"*. `cpm:status` reads neither field (it reads `**Retro waived**` and story-level `**Retro**:`), and `**Retro applied**` is read by no skill — it is written by `cpm:do` and `cpm:ralph` and never scanned back. The spec text in this row is unaffected: NFR7 asserts the formats parse unchanged without naming a consumer, so the false claim lived only in the epic's paraphrase. Restated as the no-regression guarantee the row's spec text actually supports; breadcrumb on Story 2.

**Rows 4–6, fidelity note (raised at breakdown, accepted by Chris without amendment).** The spec states FR2 as a *prohibition* — "only a wrong criterion may be amended, never a merely unmet one". The story states it as a *procedure* — "amendment requires a citable contradiction". These are not identical claims: the citation rule is the mechanism AD4 chose to make the prohibition checkable, so the story criterion is the mechanism and the spec text is the intent. Both are recorded verbatim rather than harmonised. Row 6 carries the prohibition itself, which is why it is `[manual]` — no static assertion can prove a model did not amend on bad evidence.
