# Retro: Partial-Set Reporting and Convergence Visibility

**Date**: 2026-07-27
**Source**: docs/epics/45-04-epic-resume-and-convergence.md
**Stories**: 3/3 complete

## Summary

Epic 45-04 is spec 45's safety net: report a partial phase 1 rather than resuming it (FR9), detect
a leftover `cpm:epics` progress file across sessions (FR12), and make a run that is neither
stalled nor finished visible while it is running (FR11). Three stories, three new suites, 62
suites and 1,663 assertions green at close, from 1,615 at 46-03's close.

The epic began the day after a pivot on its own source spec, and that pivot is what makes it
unusual: FR9's resume path had been made *unreachable* by a repair shipped for a different
problem (`69320ef`), and FR11's threshold had been delivered structurally by the same commit. Two
of three stories were therefore already half-done before any work started, and the epic's real
content turned out to be the parts nobody had noticed were missing — that the partial-set report
named only the uncovered side, and that the counts the loop already reads were never printed.

Two themes run through the observations. The first is that assertions written to honour a past
lesson keep re-committing the failure they guard against, one layer down: an ordering control
pinned to wording, a union that swallowed the divergence it existed to catch. The second is that
this repository's prose is now dense enough that documentation lands *inside* other suites' slices
— a paragraph added in the wrong section broke an unrelated suite, correctly.

## Observations

### Scope Surprises

- **A predicted staleness fired on the very next change, and its recorded remedy did not exist.**  
  Epic 46-03 shipped an NFR6 delta table whose `After` column pins live skill-file sizes, wrote  
  down that any later change would fail it, and named the remedy: *"a fresh baseline row, not a  
  looser assertion."* Story 1 grew `ralph/SKILL.md` by 294 bytes and the assertion fired one day  
  later. The remedy turned out to be unavailable: `budget_rows()` collects every row in the doc  
  beginning `` | ` ``, so a second table cannot be added, and the only shape left was an in-place  
  rewrite restating epic 46-03's delta as a figure including another spec's work. **Predicting a  
  failure is not the same as having a repair for it** — the prediction was correct in every  
  detail and still left the next author with a choice between falsifying a figure and deleting a  
  check. Raised through the Change Type Decision gate; Chris retired the point-in-time half. The  
  durable half — the table's internal arithmetic and its correspondence with the separately-written  
  prose baseline — was kept, and coverage row 12 keeps its ✓ because its criterion is about epic  
  46-03's *delta*, which is still accurate. Re-measuring live files forever was more than the  
  criterion asked for, which is worth noticing about the original criterion too.

### Criteria Gaps

- **A requirement phrased in vocabulary its own data source does not use.** FR11 asks each  
  iteration to report "the traced and verified counts it read from the roll-up". The roll-up emits  
  neither word: its spec-scope `SUMMARY` record carries `requirements`, `untraced`, `delivered`  
  and `in-progress`. Producing a *traced* figure is a subtraction and a *verified* figure is a  
  choice about which of two states counts — both forbidden by `ralph/SKILL.md`'s own "the loop  
  relays; it does not compute" rule (NFR2). The criterion is satisfiable because of its qualifier  
  — *it read from the roll-up* — so the clause prints all four fields verbatim and leaves the  
  arithmetic to the reader. But the requirement and the record were written months apart in words  
  that do not meet, and only reading the script's output settled it. **When a requirement names a  
  count, check the emitter uses that name before the criterion is written**, not at implementation.

### Codebase Discoveries

- **Documentation lands inside other suites' slices.** A paragraph explaining why the new `COUNTS`  
  line names four fields was added next to the rule it depends on — inside the *phase predicate*  
  section — and broke `test-ralph-phase-predicate.sh`, which asserts that section names exactly  
  one record type. It extracts types as backticked all-caps tokens, so the printed label `COUNTS`  
  read as a second record. The assertion was right and the prose was in the wrong place: that  
  section documents what the predicate *reads*, and a label the loop *prints* is not a record.  
  The paragraph moved to sit with the clauses, and says so. **Before adding prose to a  
  much-asserted skill, ask which slices the insertion point falls inside** — the cost of getting  
  it wrong is an unrelated suite failing in a way that reads as a regression.

- **`--verdict` emits the full record set, not just an exit code.** Story 3 assumed a second  
  invocation might be needed to read counts; running it showed the loop's existing single  
  `--verdict` call already produces `SUMMARY` and every `ROW` record. That is what makes the  
  per-iteration report free, and it is also why the clause insists on *that same* `SUMMARY` record:  
  a line assembled from two runs is a reading of neither.

- **`test-progress-classify.sh` reports `33/26 passed`.** Its `test_pass` calls outnumber its  
  `test_start` calls, so its own summary line is wrong while its failures count is right. Noticed  
  in passing, not touched — recorded so the next person to see it knows it predates this epic.

### Testing Gaps

- **An ordering control pinned to the full sentence it reorders.** Story 3's must-NOT is an  
  ordering claim, asserted as retro 27 prescribes: `grep -bo` offsets, plus a control that swaps  
  the two sentences. The first control did the swap with a `sed` of both sentences' complete text  
  — so a mutation renaming one *count field*, which an ordering control has no business noticing,  
  made the substitution silently miss and the control report "the swap did not apply". It was  
  found by the expected-to-stay-green mutation, not by a firing one. The control now exchanges two  
  *positions* in the clause's sentence list, located by short substrings. **A control coupled to  
  more than the property it controls for fails for reasons outside its subject**, which is retro  
  27's own lesson arriving inside the assertion written to honour it.

- **`sort -u` across two copies of a document hides their disagreement.** Story 3 derives the  
  `SUMMARY` field list from `coverage-rollup.sh`'s header, which states it twice. Deduplicating  
  across both copies was justified as "a future third copy must not change the answer" — and it  
  also meant a copy that *disagreed* changed nothing: deleting a field from one line left the  
  union intact and the suite green. Found by a one-sided mutation. The fix asserts the copies  
  agree with each other *first*, then uses one. This is retro 30's `sort -u` vacuity in the place  
  it mattered most, and the tell is the same: a dedup introduced for tidiness is a claim that the  
  inputs are interchangeable, which is exactly what the assertion should be checking.

### Patterns Worth Reusing

- **The reachability oracle is available whenever the branch predicate is a real script.** Retro  
  31 recorded that retro 29's "run the real thing" remedy had nothing to run, because no  
  executable read test-approach tags. Here it had two. Story 1 builds a fixture in FR9's exact  
  situation, runs `coverage-rollup.sh` for its *real* exit code, and asserts the records it  
  actually emits contain **both** the covered and the untraced side — a clause instructing the  
  loop to name covered requirements is unfulfillable if nothing emits them, and no amount of  
  reading the clause would find that. Story 2 does the sharper version: in one fixture holding  
  both leftovers, `cleancheck-guard.sh` returns `SUPPRESS` *and* `progress-classify.sh` still  
  emits the record — the criterion ("detected even when the guard suppresses") asserted as a  
  property of two real scripts rather than as prose. **Check availability per story, not per  
  epic**: the same epic that had no oracle for one story had a strong one for another.

- **The stated-length guard confirmed twice more, and paid for itself twice.** Editing the  
  spec-mode phase clause fails `test-ralph-two-phase-prompt.sh` until the stated figure is  
  updated. Both Story 1 and Story 3 watched it fail before updating and pass after. A length edit  
  that never failed first would mean the guard was not watching — and the unguarded prose  
  arithmetic four lines below it went stale twice in the same epic and had to be corrected by  
  hand both times, which is the contrast in one file.

- **Assert a rule at its failure mode, not by demonstrating the rule.** NFR6's "renumbers none"  
  needed a test that distinguishes a preserved gap from a renumber. The tempting version computes  
  `max + 1` over `{01, 03}` and shows it yields `04` — arithmetic that cannot fail, since the test  
  implements the rule it is checking. What *can* fail is `cpm:epics`' stated rule drifting to one  
  that reuses a gap, or dropping the archive from its glob so an archived number returns. Both are  
  pinned; both were mutation-confirmed. When a rule has no executable, the honest assertion is on  
  the sentence whose drift causes the defect.

## Recommendations

1. **A recorded prediction should name a repair that exists.** Epic 46-03 predicted its own  
   staleness precisely and left no usable remedy. When a criterion is written knowing it will fire  
   later, write the fix down and check it is reachable — "record a fresh baseline row" was not,  
   and finding that out cost a gate mid-story.

2. **Check the emitter's vocabulary when a requirement names a count.** FR11's "traced and  
   verified" met a record that emits neither. Two minutes running the script at spec time would  
   have produced a requirement phrased in the four words the data actually uses.

3. **Every control needs its own expected-to-stay-green mutation.** Both testing gaps above were  
   found by mutations expected *not* to fire — the consistent rename and the one-sided doc edit.  
   Neither would have been found by a firing mutation, and both were in code written to honour a  
   previous retro. Controls are assertions; they get the same treatment.

4. **Before inserting prose into a heavily-asserted skill, grep which slices contain the  
   insertion point.** `ralph/SKILL.md` now has at least three suites taking `sed` ranges over its  
   prose sections. This cost one debugging cycle and will cost more.

5. **`test-progress-classify.sh`'s assertion counter is wrong** (`33/26 passed`). Small,  
   self-contained `/cpm:quick`. It predates this epic and misreports every run of the full suite.

6. **The delta-table question is now settled for NFR6 but open in general.** Point-in-time  
   measurements of live files, recorded inside a *completed* epic's document, cannot be kept true  
   without editing delivered work. If another spec wants a byte budget, the durable half —  
   internal arithmetic plus correspondence with a separately-written prose baseline — is what  
   carried the value here, and it is worth designing to that shape from the start.
