# Coverage Matrix: Environmental Constraint Traceability

**Source spec**: docs/specifications/46-spec-environmental-requirements.md
**Epic**: docs/epics/46-01-epic-constraint-traceability.md
**Date**: 2026-07-27

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | FR2 | Environmental constraints are traceable. They land somewhere `coverage-rollup.sh` reads, so an uncovered one holds `untraced > 0` and blocks `SPEC_DELIVERED`. This states the property, not the mechanism — AD1 decides where they live. | A fixture spec carrying `ENV1` under `## Non-Functional Requirements` emits a `REQ` record and appears in `SUMMARY`'s untraced count | Story 2 | `[integration]` | ✓ |
| 2 | FR2 | *(as row 1)* | must NOT — an `ENV` label is dropped silently when no matrix covers it | Story 2 | `[integration]` | ✓ |
| 3 | FR3 (partial) | Restrictions are a distinct class from requirements. "Pest available" and "must not require a queue worker" are not interchangeable: the first is satisfied by adding something, the second invalidates a design and cannot be retrofitted. The distinction survives into the document, not just the conversation. | `ENV` and `ENVX` labels are reported as distinguishable classes, not merged into one count | Story 2 | `[integration]` | ✓ |
| 4 | FR3 (partial) | *(as row 3)* | must NOT — `SUMMARY`'s field arity changes; the classes are separable from the labels already present | Story 2 | `[integration]` | ✓ |
| 5 | FR6 | A Scope deferral cannot silently exclude an environmental constraint. *(Hazard A.)* | A fixture spec naming `ENV1` in a `### Deferred` bullet leaves `ENV1` untraced, not `EXCLUDED` | Story 3 | `[integration]` | ✓ |
| 6 | FR6 | *(as row 5)* | control — an ordinary `NFR1` named the same way **is** still excluded | Story 3 | `[integration]` | ✓ |
| 7 | FR6 | *(as row 5)* | control — an `ENV1` under a `Won't Have` heading **is** still excluded; only the Scope route is blocked | Story 3 | `[integration]` | ✓ |
| 8 | AD2 | the Scope-deferral exclusion refuses to exclude a label whose prefix marks it environmental, independent of its heading … the class check must have **one** definition shared by `coverage-rollup.sh` and `cpm:epics`. Two places that decide "is this environmental" will drift. | A predicate classifying a label as environmental lives in exactly one file under `cpm/hooks/lib/`; `coverage-rollup.sh` calls it rather than restating the prefixes | Story 1 | *(architecture decision — no row in the spec's table)* | ✓ |
| 9 | AD1 | Constraint discovered while testing: the label must match `[A-Z]+[0-9]+` (`coverage-parse.sh:84` and `:380`), so no underscores or hyphens in the prefix. | `ENV1` and `ENVX1` classify as environmental; `NFR1`, `FR1`, `ENVIRONMENT1` do not | Story 1 | *(architecture decision — no row in the spec's table)* | ✓ |
| 10 | AD1 | `ENVn` for requirements ("PHP 8.2 or later available"), `ENVXn` for restrictions ("must not require a queue worker"). | The predicate distinguishes the requirement class from the restriction class, so a caller can ask for either | Story 1 | *(architecture decision — no row in the spec's table)* | ✓ |
| 11 | NFR1 | Existing specs parse identically. A spec written before this change produces the same `REQ` set and the same untraced count afterwards. Checkable by running `coverage-rollup.sh --spec` across all 45 existing specs in `docs/specifications/` before and after and diffing the records. | `REQ` and `EXCLUDED` records, and exit codes, are byte-identical before and after across every spec under `docs/specifications/` **and** `docs/archive/specifications/` (46 files) | Story 4 | `[integration]` | ✓ |
| 11b | NFR1 | *(as row 11)* | control — the baseline still covers every spec on disk, its count read from the artefact rather than pinned | Story 4 | `[integration]` | ✓ |
| 12 | NFR4 | `REQ = STATE ∪ EXCLUDED` remains an exact partition with the new requirement class in play, asserted from the records themselves rather than from the parser's intent. Spec 44's property, which FR6 modifies the exclusion rules underneath. | `REQ = STATE ∪ EXCLUDED` is an exact partition with `ENV`/`ENVX` in play, asserted against the repo's real specs and not only fixtures | Story 4 | `[integration]` | ✓ |
| 13 | NFR5 | No new runtime dependencies. Bash and awk only, no `jq` or `python3` on any hook path. Spec 44's NFR3; checkable by running the suites with stubs for both first on `PATH`. | Suites pass with failing `jq` and `python3` stubs first on `PATH` | Story 4 | `[integration]` | ✓ |

## Notes

**Row 11 is the one deliberate departure from spec text.** NFR1's verification clause names
`docs/specifications/`, which holds 7 files; the other 39 are in `docs/archive/specifications/`.
Taking the baseline as the spec describes it would pass while 39 specs regressed silently. The
spec's clause is worth correcting at source.

**Rows 11 and 11b were rewritten during Story 4** — the criterion now names `REQ` and `EXCLUDED`
rather than every record, and row 11b is new. The reason is in the epic doc under Story 4: those
two record types are functions of the spec document alone, which is what NFR1 actually claims,
while the rest depend on matrix contents that legitimately move as work proceeds. Row 11's
verification status was never `✓` before the rewrite, so nothing was reset by it.

**Rows 3 and 4 cover FR3 only partially.** They establish that the two classes are separable from
the emitted records. FR3's other half — that the distinction survives into the authored document —
belongs to epic 46-02, where `cpm:spec` teaches the two classes. Step 4's cross-epic gap check must
not read FR3 as fully covered by this epic.

**Rows 8–10 trace to architecture decisions, not to table rows in the spec.** The spec's Acceptance
Criteria Coverage table has no entries for AD1 or AD2, because they are decisions rather than
requirements. The criteria exist because AD2 carries an implementation constraint (Margot's
single-definition rule) that would otherwise have no home in any story.

**Spec 46's `### Test Infrastructure` is inaccurate for this epic.** It states that FR6's cases
extend `coverage-fixture-helpers.sh` with `--env`/`--envx` options. They do not: `--nfr` already
accepts an arbitrary label and `--deferred` already lifts `ENV1`, verified empirically before this
epic was written. No builder change is in scope here.
