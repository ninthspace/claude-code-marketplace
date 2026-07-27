# Retro: Environmental Constraint Traceability

**Date**: 2026-07-27
**Source**: docs/epics/46-01-epic-constraint-traceability.md
**Stories**: 4/4 complete

## Summary

Epic 46-01 gave `coverage-rollup.sh` a single definition of what makes a requirement label
environmental, and closed the route by which a Scope deferral could silently retire one. The code
change was four lines across two files; everything else was evidence. Three of the four stories
found something the plan had not: the mechanism AD2 asked for already existed, a criterion had been
verified against the wrong requirement class, and the verification artefact captured to prove
nothing regressed turned out to be measuring the epic itself.

## Observations

### Scope Surprises

- **A baseline captured inside the change ended up measuring the change.** The 46-spec record  
  baseline was taken at Task 1.1, before any code moved — correct sequencing, and it still went  
  wrong, because the baseline covered spec 46, whose records the epic then altered by ticking rows  
  in its own coverage matrix. It surfaced at Task 3.1 as a dirty diff with no regression behind it.  
  The fix was to split records by what they depend on: `REQ` and `EXCLUDED` are functions of the  
  spec document and belong in a committed fixture; `STATE`, `SUMMARY` and `ROW` depend on matrix  
  contents and are only meaningful as a before/after diff at the moment of a change. The general  
  rule to carry forward — before committing a repository-wide baseline, ask which part of the  
  repository the work is about to change, because that part will drift for reasons that are not  
  regressions and every future epic will hit the same wall.

### Criteria Gaps

- **A criterion naming one class was verified against the other, and everything passed.** Story 3's  
  third criterion is written about an `ENV1`-shaped label under a `Won't Have` heading; the suite  
  covered that route with `ENVX1` only — the restriction class, not the requirement class named.  
  The code was correct either way, so no test failed and no mutation caught it. It was found at the  
  gate by re-reading the criterion text against the fixture rather than against the passing run.  
  That re-read is the practice worth keeping: a green suite tells you the assertions you wrote hold,  
  never that they are the assertions the criterion asked for.

### Codebase Discoveries

- **The single-definition mechanism AD2 demanded was already built.** `_COVERAGE_AWK_LIB` in  
  `coverage-parse.sh` exists precisely so a label is resolved by one piece of code, and its header  
  states the rationale AD2 restates. Story 1 carried `[plan]` because "one definition" looked like  
  a real design question given that a bash function cannot be called from awk; it turned out to be a  
  one-token change. Reading the component's source before planning around its description would have  
  cost minutes and saved a planning gate.

- **A lone apostrophe in a comment silently empties an entire shared awk library.**  
  `_COVERAGE_AWK_LIB` is one single-quoted shell string, so an apostrophe closes it and bash then  
  rejects the whole file at parse time — the variable is never assigned and its length is **0**.  
  Measured, after an initial assumption that truncation would spare functions defined earlier proved  
  wrong. Every awk program built from the variable silently becomes a pattern-less program that  
  prints nothing, which is a failure mode no classification assertion would catch. The library now  
  carries a warning; a callability control now guards it.

### Testing Gaps

- **A must-NOT about record arity needed two forms of the same assertion.** Criterion 4 forbade  
  `SUMMARY` gaining a field. A literal arity check catches a field added unconditionally; a derived  
  comparison between a spec with `ENV` labels and one without catches a field added *only* when the  
  new class is present. Neither catches the other's case, and mutation testing proved it — the two  
  mutations each defeated exactly one form. Where a must-NOT is about a conditional behaviour,  
  assert both the absolute and the differential.

- **The load-bearing assertions were the controls, not the criteria.** Story 3's positive criterion  
  is satisfied by a guard that excludes nothing at all: delete the whole deferral branch and `ENV1`  
  is untraced, exactly as asserted. Only the two controls — an ordinary `NFR1` deferred by the same  
  bullet is still excluded, an environmental label under `Won't Have` is still excluded — distinguish  
  the change wanted from the change that removes the feature. Mutation-testing confirmed the  
  prediction the epic's plan made before the tests were written.

### Patterns Worth Reusing

- **Promote on the second call site, but only when the shared thing carries a contract.** This epic  
  applied retro 25's lesson twice and declined it once, and the discriminator was consistent. Declined:  
  a one-line `printf | awk` idiom, where extracting it would have traded two self-evident lines for an  
  indirection. Applied: `coverage_rollup_run`, `coverage_count_type`, `coverage_states_in` and  
  `coverage_partition_errors`, promoted into `coverage-fixture-helpers.sh`. The reason was not drift  
  between existing copies — two test runners that diverge produce no wrong answers — but that the next  
  suite would call `bash coverage-rollup.sh` plainly and silently lose the `run_without_env  
  CLAUDE_PROJECT_DIR` contract while still passing. Ask what a *third* caller would get wrong.

- **A mutation that prints a checksum change before the suite runs.** Every load-bearing assertion  
  group in this epic was proved discriminating by a mutation applied to a scratchpad copy, each  
  printing the file checksum before and after so the mutation is visibly real rather than asserted.  
  Nine mutations across four suites; every one was caught, and two revealed that an assertion was  
  weaker than it read. Cheap, and it converts "the tests pass" into "the tests would notice."

## Recommendations

- **Spec 46's NFR1 clause is still wrong at source.** It names `docs/specifications/` (7 files) and  
  says "all 45 existing specs"; the other 39 are archived, and the durable/volatile split now means  
  the check is over `REQ` and `EXCLUDED` rather than all records. The epic and its coverage matrix  
  both document the departure, but the spec has not been corrected. Fix it before epic 46-02 reads it.

- **Spec 46's `### Test Infrastructure` section is inaccurate and nothing reads it.** It claims FR6's  
  cases need `--env`/`--envx` options on `coverage-fixture-helpers.sh`; they do not — `--nfr` already  
  takes an arbitrary label. This is the second time this section has been found wrong, and spec 46's  
  own problem statement notes that grepping for "Test Infrastructure" outside `spec/SKILL.md` returns  
  nothing. Consider whether the section should exist at all.

- **Epics 46-02 and 46-03 inherit an untested assumption.** Epic 46-03's FR7 asserts that `cpm:epics`  
  names the same two prefixes as `cov_environmental_class`. That correspondence is currently prose  
  agreeing with code by inspection. Make the assertion mechanical if it can be.

- **Carry the durable/volatile distinction into any future baseline fixture.** The pattern is not  
  specific to spec records: any artefact this repository commits as a "nothing changed" oracle should  
  be filtered to the parts that depend only on inputs the work is not editing.
