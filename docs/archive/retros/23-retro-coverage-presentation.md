# Retro: Spec-Scoped Coverage Presentation

**Date**: 2026-07-26
**Source**: docs/epics/44-02-epic-coverage-presentation.md
**Stories**: 3/3 complete

## Summary

The epic put spec 44's roll-up in front of a reader: a spec-scoped phase in `cpm:status`, a stakeholder page rendered from the same records, and a sweep labelling aggregated `✓` as aggregation rather than verification wherever it is shown. All eleven coverage rows are verified and the full suite is green at 1,024 assertions.

The through-line of the epic's findings is that the deliverable was **prose a model follows**, and almost every difficulty came from testing prose with tools built for code. Two assertions passed while measuring nothing, one existing invariant turned out to encode an assumption nobody had stated, and the retro-21 trap — a warning and the mistake it warns about being the same bytes — reproduced itself inside the test written to guard against it.

## Observations

### Scope Surprises

- **An invariant's subject was the output, not the skill, and nobody had noticed because every skill had one output.** The repo asserted the canonical Artifact Publishing line appears once per publishing *skill*, with a hand-maintained count. `cpm:status` now has two publishable outputs — the project-wide picture and the spec coverage page — separately requested, separately confirmed, published to separate URLs. Three suites encoded the conflation and had to be re-stated. Collapsing the two sites would have made the second page's publishing implicitly covered by the first page's confirmation, which is exactly what the line exists to prevent. When a rule is stated per-X and X has always had exactly one Y, the rule's real subject is worth naming before a second Y arrives.

### Codebase Discoveries

- **The worst-phrased site was in the existing code, not the new work.** FR7 was drafted with `cpm:status` and `cpm:ralph` in mind. The sweep found `cpm:do`'s batch summary reporting "Coverage matrix: 9/9 requirements verified" — a count of marks `cpm:do` had itself just placed, phrased as an outcome someone else confirmed. Read a cross-site rule against the *existing* sites first: their wording has been believed for longest.
- **An assertion named for a section counted across the whole file.** `test-status-artifact-pivot.sh`'s "Phase 4 carries the canonical reference line" had a `$PHASE4` slice in scope and grepped the file instead. It passed for months because there was one site anywhere in the file, so the two numbers agreed; a second site elsewhere made it fail while pointing at a section that had not changed. Count within the slice the assertion names, even when the file-wide answer agrees today.

### Testing Gaps

- **A test that runs a command extracted from a document goes vacuous when the extraction stops matching.** `bash -c ""` exits 0 and emits nothing, so "it produced records" and "it exited zero" both hold for a skill that invokes nothing at all. Mutation testing found three assertions in this state. The fix is one assertion, stated *before* the ones that depend on it, that the extraction is non-empty. Every test whose input is grepped out of a file needs it.
- **A mutation that reports no failures may not have been applied.** `perl -0pi -e 's/^### Phase 3b:.*?^### Phase 4://'` deleted nothing — with `-0` the file is one record and `^` matches only its start without `/m` — and the green run was indistinguishable from a missing control. Every mutation in this epic then printed a count of what it changed before the suite ran.
- **Retro 21's finding reproduced itself inside the test written to guard against it.** An `assert_not_contains` for the misleading phrasing failed because `cpm:do`'s item quotes that phrasing deliberately, in the sentence telling a model not to use it. Before writing any `assert_not_contains` over prose, ask whether there is a legitimate reason the text would contain the forbidden thing — and if so, narrow the haystack to where its presence would be an instruction rather than a caution.

### Patterns Worth Reusing

- **Say in the suite which assertions are oracles and which are regression nets.** For a deliverable that is prose, most `assert_contains` calls over that prose can only catch a rule being *dropped* — they cannot tell an honoured rule from a quoted one. Naming the distinction in the file header stops a later reader taking a green run for a quality verdict, and it is what gives the criteria that genuinely have oracles their weight. The same distinction was then written into the coverage matrix's Notes, so the epic's record says what verified each row.
- **An inventory that forces a human read beats a detector that guesses.** FR7's "every site" cannot be discovered by grep. `test-aggregation-labelling.sh` instead accounts for every `✓`-bearing line across `cpm/skills/` — each is either a rostered aggregation site carrying the statement, or a line explicitly classified as not presenting an aggregate. A skill that starts showing `✓` counts changes a count and fails until someone has read it and said which it is. The suite does not decide; it insists that someone does.

## Recommendations

- **Check whether any other skill is heading for a second publishable output** before the next one lands, so the per-output arity is stated deliberately rather than discovered by a failing suite.
- **Add the extraction-is-non-empty assertion wherever a test runs something grepped from a file.** `test-clean-invocation.sh` uses the same pattern and is worth a look.
- **Make "print what the mutation changed" the standing shape for mutation testing** in this repo — the cost is one line and it removes the failure mode where a no-op mutation reads as a missing control.
- **Epic 44-03 inherits a named site list for FR7**, not a guess: `cpm:status`'s Phase 3b, its stakeholder page, `cpm:do`'s batch summary, and the promise it is about to build. Its gate re-reads all four.
- **Neither 44-01 nor 44-02 had a retro until now.** 44-01 completed earlier in the same session with its observations recorded as breadcrumbs and no file written. Worth checking `cpm:do`'s Step 8 flag-set read on the next epic — the observations were there, so the gap was in generation rather than capture.
