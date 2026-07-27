# Coverage Matrix: Phase Detection and the Completion Promise

**Source spec**: docs/specifications/45-spec-delivery-autonomy.md
**Epic**: docs/epics/45-03-epic-phase-detection.md
**Date**: 2026-07-26

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|---|---|---|---|---|---|
| 1 | FR7 | The loop **distinguishes "no epics yet" from "the check could not run"**. Both are `exit 1` today; one means keep working, the other means stop. | `--verdict` returns a distinct exit code when the spec is readable and zero matrices name it | Story 1 | `[tdd] [unit]` | ✓ |
| 2 | FR7 | The prompt branches on that code as "phase 1 not started" and on the read-failure code as "stop" | The prompt branches on that code as "phase 1 not started" and on the read-failure code as "stop" | Story 3 | `[integration]` | ✓ |
| 3 | FR7 (must NOT) | must NOT treat a read failure as phase 1 not started | must NOT treat a read failure as phase 1 not started | Story 3 | `[integration]` | ✓ |
| 4 | FR8 | **Phase-1 completion is a recorded fact**, not inferred from the presence of epic files. A partially-generated set must be distinguishable from a complete one. | The phase judgement comes from the roll-up's records | Story 2 | `[integration]` | ✓ |
| 5 | FR8 (must NOT) | must NOT infer phase from the presence or count of epic files | must NOT infer phase from the presence or count of epic files | Story 2 | `[integration]` | ✓ |
| 6 | NFR2 | **Single source of the phase judgement.** `cpm:ralph` relays the script's records; it never derives traced / untraced / verified state itself. | The loop relays named record fields; it counts no rows itself | Story 2 | `[integration]` | ✓ |
| 7 | NFR2 (must NOT) | must NOT derive traced or verified state from the records | must NOT derive traced or verified state from the records | Story 2 | `[integration]` | ✓ |
| 8 | FR6 | **Two completion conditions, never conflated.** Phase 1 is *every requirement traced to a matrix row*; phase 2 is *every row verified*. A spec with no epics is phase one, and phase one is never "done". | The prompt states phase 1's predicate (0 untraced) and phase 2's (all rows verified) separately | Story 3 | `[integration]` | ✓ |
| 9 | FR6 (must NOT) | must NOT emit the completion tag while any requirement is untraced | must NOT emit the completion tag while any requirement is untraced | Story 3 | `[integration]` | ✓ |
| 10 | NFR1 | **Fail closed on every phase decision.** Uncomputable means *not complete*, and never advances a phase. | Every phase decision defaults to *not complete* when the roll-up cannot compute | Story 3 | `[integration]` | ✓ |
| 11 | NFR5 | **Prompt budget.** The template is **2,736 characters** today and is fed back verbatim on every iteration. New clauses stay to a sentence, and the stated figure is asserted against the actual length. | The template's stated `**Length: N characters**` figure matches its actual length | Story 3 | `[integration]` | ✓ |
| 12 | FR10 | **One promise per mode, fixed at launch** — not a choice offered to the loop. Epic mode asks "are these matrices fully verified"; spec mode asks that *plus* "are all the spec's requirements traced". | Spec mode's `completion_promise` differs from epic mode's, is fixed at launch, and the emitted tag matches it exactly | Story 4 | `[integration]` | ✓ |
| 13 | FR10 (must NOT) | must NOT put evidence inside the promise tag | must NOT put evidence inside the promise tag | Story 4 | `[integration]` | ✓ |
| 14 | FR6, FR7 (story-originated) | — | The command the prompt names, extracted from the prompt and executed, returns the exit codes the prompt's own branches name — for all four codes | Story 5 | —  | ✓ |
| 15 | FR13 | **`[plan]` tags are stripped from every epic doc before `/cpm:do` runs over it**, not only from the docs that existed at pre-flight. | Epics generated during phase 1 are stripped before phase 2 begins, by the same rule Step 1b applies at pre-flight | Story 6 | `[integration]` | ✓ |
| 16 | FR13 (must NOT) | must NOT begin phase 2 while an epic the run generated still carries the tag | must NOT begin phase 2 while an epic the run generated still carries the tag | Story 6 | `[integration]` | ✓ |
| 17 | FR13 (must NOT) | must NOT strip tags from epic docs the run did not generate | must NOT strip tags from epic docs the run did not generate | Story 6 | `[integration]` | ✓ |

## Notes

**FR7 has three rows because it has two halves and a boundary.** Row 1 is the script returning the code; row 2 is the prompt branching on it; row 3 forbids the two failure codes collapsing into one. Rows 1 and 2 can both hold while the branch never fires — which is what row 14 exists to catch.

**Row 14 is `(story-originated)`** and is the most important row in this matrix. It comes from retro 24, not from spec 45: in epic 44-03, changing the prompt's `on 3` to `on 4` — a code the script never returns — left every assertion green, because nothing compared what the document claimed to what the program did. With four codes, that failure is four times as available. The row asserts the correspondence itself: extract the command from the prompt, run it against fixtures built for each outcome, compare the returned codes to the codes the prompt's branches name.

**Row 1 is the only `[tdd] [unit]` row in spec 45.** Everything else in the spec is prose asserted across a boundary; this is the one genuinely unit-testable piece, and spec 44 showed exit-code semantics are where the subtle errors live — an awk field off-by-one silently reported every verdict as outstanding.

**Row 13 is carried forward from a spec-44 finding, not invented here.** The ralph-wiggum stop hook compares `<promise>` contents to `completion_promise` with literal string equality after whitespace normalisation, so anything appended inside the tag never matches and the loop runs to its iteration cap on finished work. Spec 44's AD4 assumed the tag could carry payload; it cannot. The evidence goes beside the tag.

**Rows 15–17 were added by a pivot on 2026-07-26**, after FR13 and AD6 were added to the spec. Row 16's must-NOT says "still carries the tag" rather than naming `[plan]`, and that wording is the spec's own — the clause implementing the rule has to write the tag repeatedly, so a must-NOT phrased against the token would be unsatisfiable on arrival. Retro 21 recorded that failure; the spec's Testing Strategy now names this as one of three criteria phrased deliberately against it, and this row inherits the phrasing verbatim rather than paraphrasing it back into the trap.

**Row 17 is the more testable of the two must-NOTs.** "Do not strip tags from docs the run did not generate" bounds the write surface to the epics phase 1 wrote, and a fixture holding a pre-existing epic doc beside the generated ones discriminates it. Row 16, by contrast, is a claim about ordering that nothing in the suite can observe without a live loop — it is asserted as an instruction present in the operative site, which is evidence rather than proof, and Story 6's task description says so.

**Rows 2, 3, 5, 7, 9 and 13 quote the spec's testing-strategy table**, where those criteria and every `must NOT` line originate. The rest quote the requirements section, which is authoritative where the two differ.
