# Coverage Matrix: Intent Adapters and the Join

**Source spec**: docs/specifications/42-spec-change-set-review.md
**Epic**: docs/epics/42-02-epic-intent-adapters-and-join.md
**Date**: 2026-07-25

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

> **Retired 2026-07-26.** Every file behind this matrix — both link adapters, the intent
> adapter, the link set, the join, the JSON record, the conformance harness and their seven
> suites — was deleted when spec 42's architecture was withdrawn. See the Retirement section
> of the source spec. The `✓` marks are left as they stand: they record what was verified on
> 2026-07-25, which is what this document is for, and not a claim about the current tree.
>
> **One row was already known to be over-marked before the retirement.** The branch-name row
> was verified against a fixture in which the branch signal linked the one file under test;
> in a real change set the same signal linked *every* file, which is the observation that
> retired the architecture. The criterion was satisfiable by a reading much weaker than it
> appeared to promise — retro 20's lesson, arriving a second time.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | R7 | The join reads every intent channel present and **owns none of them**. | Each adapter implements one contract: given a change set, return a link set | Story 1 | `[unit]` | ✓ |
| 2 | R7 | The join must produce a usable result with **zero** cooperating channels. | must NOT require any adapter to be present — zero active adapters is a valid configuration | Story 1 | `[unit]` | ✓ |
| 3 | AD2 | The **baseline adapter is git-native** — commit trailers, conventional-commit subjects, and branch names — and works in any repository with no configuration. | Commit trailers (`Refs:`, `Closes:`) resolve a changed file to an intent record | Story 2 | `[unit]` | ✓ |
| 4 | AD2 | commit trailers (`Refs:`, `Closes:`), conventional-commit subjects (`fix(scope):`), branch names (`feature/AUTH-123`) | Conventional-commit subjects (`fix(scope):`) resolve a changed file to an intent record | Story 2 | `[unit]` | ✓ |
| 5 | AD2 | commit trailers (`Refs:`, `Closes:`), conventional-commit subjects (`fix(scope):`), branch names (`feature/AUTH-123`) | Branch names (`feature/AUTH-123`) resolve a changed file to an intent record | Story 2 | `[unit]` | ✓ |
| 6 | AD2 | and works in any repository with no configuration | The adapter works in any repository with no configuration | Story 2 | `[unit]` | ✓ |
| 7 | R2 | Git-anchored selectors resolve **reverse** (files → intent). | Commit trailers (`Refs:`, `Closes:`) resolve a changed file to an intent record | Story 2 | `[integration]` | ✓ |
| 8 | AD2 | epic docs, `**Satisfies**` fields, coverage matrices, co-commit | Epic docs, `**Satisfies**` fields and coverage matrices resolve to intent records carrying their criteria | Story 3 | `[unit]` | ✓ |
| 9 | AD2 | **co-commit is the strongest derived signal** — a commit carrying both a change and a reference to intent links them | Co-commit links a changed file to an intent record when both land in one commit | Story 3 | `[unit]` | ✓ |
| 10 | AD2 | **Time-window derivation is explicitly rejected.** Inferring a link from a commit falling inside an intent record's active window does not survive contact with reality | must NOT infer a link from a time window | Story 3 | `[unit]` | ✓ |
| 11 | R7 | Each resolved link is labelled: **declared** — an explicit marker names the intent record; **derived** — inferred, principally from co-commit; **absent** — no adapter resolves it; the file is an orphan | Every resolved link carries exactly one of declared / derived / absent | Story 4 | `[unit]` | ✓ |
| 12 | R7 | A declared marker always wins over a derived one for the same (file, intent) pair | A declared marker always wins over a derived one for the same (file, intent) pair | Story 4 | `[unit]` | ✓ |
| 13 | R7 | must NOT label a derived link as declared under any adapter combination | must NOT label a derived link as declared under any adapter combination | Story 4 | `[unit]` | ✓ |
| 14 | R6 | Two runs against the same repository state produce byte-identical JSON | Two runs against the same repository state produce byte-identical JSON | Story 5 | `[integration]` | ✓ |
| 15 | R6 | The emitted document is valid JSON | The emitted document is valid JSON | Story 5 | `[unit]` | ✓ |
| 16 | R6 | The join emits a deterministic JSON document, committed alongside the work, which is the record. | The record is written to `docs/inspect/` in the repository, not to a scratch or published location | Story 5 | `[integration]` | ✓ |
| 17 | AD4 | The join emits JSON into the repository. The published page is regenerated from that JSON and treated as disposable. | The record is written to `docs/inspect/` in the repository, not to a scratch or published location | Story 5 | `[integration]` | ✓ |
| 18 | R7 | The join reads every intent channel present and **owns none of them**. | With both adapters active, a file resolved by each yields one link set with precedence applied across adapters, not within one | Story 6 | `[unit]` | ✓ |

## Notes

**R2's second half is covered here.** Epic 42-01 covers R2's forward direction (intent → files) and the round-trip equivalence; **row 7 above covers the reverse direction (files → intent)**, which is what the adapters do and which is impossible without them. R2 is therefore fully covered only across both epics — 42-01 rows 6–7 plus this matrix's row 7. Step 4's cross-epic gap check confirms the pair.

**`docs/inspect/` is a story-level decision, not spec text.** The spec says only "committed alongside the work" and "written to a repository path". The specific directory was chosen at the Step 3b gate to match the skill name (`/cpm:inspect`). Rows 16 and 17 quote the spec's general requirement against the story's specific one; that narrowing is deliberate and recorded here so it reads as a decision rather than a drift.

**AD3 has no row of its own.** The hard split between the deterministic join and the model-driven review ("The review consumes the join's **data**, never its **labels**") is a constraint on Epic 42-04, not an assertion this epic can test — nothing here consumes the labels. Story 5's `**Satisfies**` names AD3 because the JSON schema is what makes the split enforceable, but the property itself is verified where the review is built.

**Story 1's conformance-suite criterion has no row, and should not.** "A conformance suite exercises the contract, and any adapter must pass it" is a testing-infrastructure criterion with no spec sentence behind it — the spec's Integration Boundaries section names `adapter → link set` as a seam, but states no requirement that a shared harness exist. It is a story-originated criterion in the same sense as Epic 42-01's fixture-isolation one, and it is verified by `cpm/hooks/tests/linkset-conformance.sh` plus the ten positive controls in `test-linkset.sh` rather than by a row here. Recorded so that "two rows for a three-criterion story" reads as deliberate rather than as a dropped requirement.

**Story 6's third criterion was verified as a different property than it states, deliberately.** As written — "Disabling one adapter changes which links are present but never their labels" — no correct implementation can satisfy it, because Story 4's criterion makes a declared marker win for a (file, intent) pair, and whether that pair has a declared marker is precisely what disabling an adapter decides. `test-linkset-cross-adapter.sh` demonstrates the collision in both directions. It is verified instead as the two properties it was reaching for: **adapter-output stability** (an adapter's own emitted triples do not depend on which peers are registered) and **monotonicity** (removing an adapter only removes links or weakens a surviving pair — never strengthens one, never invents one). Row 18 covers the story's first criterion only; this note records why the third has no row asserting its literal text.

**Spec Test Approach tags differ from story tags in several rows.** The spec's Acceptance Criteria Coverage table tags R7's criteria `[unit]`, and the stories carry `[integration]` on the adapter stories because an adapter cannot be exercised without a real repository fixture. The stronger tag was kept. Rows 1–6 and 8–10 show this divergence explicitly rather than silently re-tagging.
