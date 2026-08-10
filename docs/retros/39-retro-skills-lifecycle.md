# Retro: Skills — Lifecycle

**Date**: 2026-08-10  
**Source**: docs/epics/47-09-epic-skills-lifecycle.md  
**Stories**: 9/9 complete

## Summary

The last four of FR25's twenty-two conversions, two substrate stories that landed five amendments
the earlier epics had asked for, and the two closing stories that assert the corpus is complete and
that dpm can hold dpm's own planning corpus. Nine of the fourteen observations are testing gaps, and
they are not nine separate lessons: almost every one is a test that passed for a reason other than
the one it claimed, found only because something else went looking. That is the epic's finding.

## Observations

### Codebase Discoveries

- **Schema gaps keep arriving from consumers rather than from reading the schema.** Retro 38 said  
  the next gap was already sitting in an unconverted file; it was, and the first conversion of this  
  epic found it. `document_kind_parent` looked covered from every angle because its *upward* half  
  was already in use — the downward half a cascade needs had no reader. A table with one direction  
  exercised is not an exercised table.
- **Two shapes read backwards from the intuition, and both cost a debugging session.** The session  
  chain's foreign key lives on the *predecessor* (`superseded_by`), so it is the live end that  
  cannot be deleted, and oldest-first is the only sweep order that never meets the refusal. And a  
  fixture spreading a shared helper's return silently rebound its own keys — `...startup` last meant  
  the fixture's `retro` was the helper's, and the failure surfaced as a wrong traversal.
- **A test that transcribes its source is only testing the transcription.** The integrity register's  
  own numbering had drifted twice with nothing able to see it: the spec's table is prose, and the  
  test asserts contiguity over its own copy of the list rather than against the source. "Itself the  
  thing under test" holds only as far as the copy is honest.

### Testing Gaps

- **A green assertion is not evidence until the wrong answer is known to be excluded.** Four  
  separate instances, one mechanism: a control cleared by a second write in the same run; a decoy  
  that was not the row an *unfiltered* read would return, so the filter could be emptied and the  
  test still passed; an archival criterion observable only when the archived document holds the  
  *highest* number; an assertion naming the database that never reached it, because the tool's enum  
  and the schema's `CHECK` are the same list written twice. Each was fixed by making the wrong answer  
  return something different — not by adding assertions.
- **A mutation is only caught when the mutation ran.** One did not parse and the file failed to  
  load; one silently matched nothing and read as a survivor; one changed no output at all, because  
  the block assembler drops empty strings and the corpus held no case that would have differed. The  
  first two are false catches, the third a false survivor, and none is distinguishable from the test  
  result alone. Verify the diff applied and the render changed before recording a verdict.
- **A fidelity walk that compares what the fixture recorded measures the fixture.** It read clean  
  while a template dropped a column, because nothing had recorded that column — and the gap is  
  invisible from inside the walk, since a value never recorded is a value never missed. Deriving the  
  swept set from the live read surface closed it; the count of values swept, asserted against the  
  count recorded, is what stops the derivation passing by reading nothing.
- **Tests can pin a defect in place.** Two suites cited `entityTools` dropping nulls as the mechanism  
  of retirement durability and of the waiver being unliftable — asserting a false pass as a feature.  
  What actually carries durability is that no tool is named for lifting either, and that the  
  vocabularies keep `retired_at` off `mutable` entirely.
- **Cross-epic failures are the signal that a wide edit is genuinely covered.** Thirteen mutations,  
  thirteen caught, four of them failing a test belonging to an earlier epic as well as this one —  
  which is what a story editing eight finished skills should look like.

### Patterns Worth Reusing

- **Drive a must-NOT rather than sweep for it, when the file forbids its workaround by naming it.**  
  A pattern sweep reports the prohibition as the offence — the same trap `sentinel` and `basename`  
  sprang two stories earlier. Both criteria were restated as claims about rows (no artifact row  
  exists; no section body holds what the column holds), checkable against what a run wrote, each  
  with a control that is wrong on purpose.

## Recommendations

- **Write the decoy before the assertion.** For each new test, state in one line what the wrong  
  answer would be and why this test would not return it. Most of this epic's testing gaps are that  
  line going unwritten; the fix was never a missing assertion.
- **Give every mutation a two-part verdict** — did the diff apply, and did the output change — before  
  recording caught or survived. A survivor that changed nothing is a missing corpus case, not a  
  missing test, and the two want different work.
- **Derive completeness claims from the live surface and guard them with a count.** A set built from  
  what a fixture recorded, or transcribed from a document, tests the fixture or the transcription. A  
  non-vacuity count is what makes the derivation load-bearing.
- **Keep expecting the next schema gap to arrive from a consumer.** Two epics running, the gap was  
  found by the first thing that tried to use the table, not by reading it. Walk the consumer before  
  the schema, and treat a table exercised in one direction as unexercised.
