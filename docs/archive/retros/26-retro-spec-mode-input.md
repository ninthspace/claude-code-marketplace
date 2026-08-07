# Retro: Spec Mode Input

**Date**: 2026-07-27
**Source**: docs/epics/45-02-epic-spec-mode-input.md
**Stories**: 4/4 complete

## Summary

`cpm:ralph` gained a fourth input shape. A path under `docs/specifications/` now resolves
**spec mode**, decided by the directory the path sits in rather than by a flag; Step 1a
resolves `{mode}` and `{spec_path}` once and later steps read them; and step 3's zero-epic
stop branches, so *"No incomplete epics found. Nothing to run."* survives verbatim for the
three shapes that predate spec mode and never fires for the fourth. All seven coverage rows
are verified and the hook suite runs green with the new file at 91 assertions.

The epic found four defects and **every one of them was in its own assertions, not in
`cpm:ralph`** — and not one announced itself as a failure. A regression net that would have
defended the exact sentence being fixed. A classifier that read only the first directory a
table row named. A flag extractor that counted five flags where three are documented. A
cross-story measurement that reads like the discriminating one and is not. Three were caught
by reading — output, or a control that refused to trip — and the fourth by writing a control
expecting it to fail and then checking whether it had.

This is the mirror of retro 25. There, three defects were claims about *another part of the
system* asserted without opening it. Here the subject was open the whole time and the
unexamined artefact was the test — which is worse-placed, because a test is the thing that is
supposed to be doing the examining. A wrong claim in prose is inert until someone reads it; a
wrong assertion is actively reporting that it checked.

## Observations

### Codebase Discoveries

- **A verbatim regression net pins the defect along with the behaviour.** `test-ralph-promise.sh`  
  asserted *"If no epic paths are provided, auto-discover all incomplete epics"* verbatim, as  
  epic 44-03's FR9 net over the shapes that must not change. That sentence is exactly the  
  bug the moment a fourth shape exists: a spec path is not an epic path, so it satisfies the  
  condition and falls through to auto-discovery — FR2's failure mode reached through FR1. The  
  net was doing its job and its job was wrong. Nothing distinguishes "this wording is load-  
  bearing" from "this wording is what we happened to write", so the net that protects a  
  surface from change is the first thing to re-read when the surface legitimately changes,  
  not the last thing to update after.

- **Two copies of "the directories a table row names" disagreed, and the disagreement was a  
  bug.** `dir_named_by` took the first `docs/*/` token per row; `classify` took all of them.  
  A row naming two directories was therefore ambiguous to one reader and unambiguous to the  
  other, which is precisely the state the ambiguity control existed to detect. Found by the  
  Story 2 refactoring pass, not by a failing test — both functions passed everything asked of  
  them individually. Consolidated to one `row_dirs` and one `row_mode`.

- **An extractor that matches every occurrence counts mentions, not things.** `input_flags`  
  grepped each Input item for `` `--… ``, and the `--story-filter` item names itself three  
  times in its own examples. Five flags counted where three are documented — and every count  
  built on it *agreed with itself*, including the control asserting the flag list was  
  non-empty, which passed on 5 ≥ 3. The label is the definition; the examples are prose. It  
  surfaced from three identically-named PASS lines in the output, which is to say from  
  reading rather than from any assertion.

### Patterns Worth Reusing

- **When a must-NOT forbids a string a neighbouring rule requires, assert it from three  
  directions.** Story 3's must-NOT forbids the stop message in spec mode; the epic-mode  
  bullet two lines above must carry that message verbatim or FR2 breaks. One assertion is  
  satisfiable by a wrong edit in every case: *absent from the spec bullet* passes if the  
  message is deleted outright, *present in the epic bullet* passes if a copy is added to the  
  spec bullet, and *exactly once in the step* passes if the one copy is in the wrong branch.  
  All three together pin it to one place. This generalises to any rule whose violation shares  
  its tokens with its statement — retro 21's shape, given an assertion form rather than only  
  a caution.

- **Pick the measurement that moves under the specific wrong edit, not the one that describes  
  the property.** Story 4's first cross-story count was *how many of the four shapes are  
  sensitive to the disk state* — an accurate description of what the matrix is for, and blind  
  to the failure it was written for. A spec branch that wrongly stops is still different from  
  the same branch with epics present, so the count reads 2 either way. What moves is *how many  
  shapes stop on an empty disk*: one, and it is auto-discovery. Name the wrong edit first,  
  then choose the count that changes under it — the reverse order produces measurements that  
  are true and useless.

- **Build the classifier from the document rather than re-typing its rule.** `classify` reads  
  the mode table's own rows and is fed real paths out of the repository, so changing the table  
  changes what the test does. The assertion with an oracle outside the document falls out of  
  it for free: the directories the table names are globbed for the artefacts they claim to  
  hold, and a table naming `docs/specs/` reads perfectly while classifying nothing.

### Testing Gaps

- **The one retro signal that fired, fired on the wrong thing.** `cpm:do`'s signal set  
  recorded a single trigger this epic: a test command returned failures during Task 2.1. That  
  failure was a *control refusing to trip* — the suite working correctly, mid-task, on a  
  defect in its own helper. Meanwhile the finding that makes this retro worth writing (four  
  defects, none of which surfaced as a failure) produced no signal at all. Retro 25 found the  
  set under-fires on story-gate reads; this epic adds that when it does fire, what it points  
  at need not be related to what was learned. A signal set whose one entry is uncorrelated  
  with the epic's actual content is not a weaker version of the right instrument.

- **Nothing here launches a loop, and the epic's central claim is about one.** Every  
  assertion in `test-ralph-spec-mode.sh` is over prose in a SKILL.md: that the mode is stated,  
  that the branches exist, that the directories are real. Whether `cpm:ralph` actually  
  resolves a spec path at runtime is unasserted and unassertable by this suite. The  
  correspondence assertions narrow the gap — the classifier runs, the repository is the  
  oracle — but the gap is there and the epic's Notes should have said so as plainly as  
  epic 45-03's do.

### Criteria Gaps

- **One cell of the four-by-two matrix has no documented outcome, and Story 4's criterion  
  passes anyway.** Explicit epic paths or a range resolving to *zero* files reach "resolve  
  them (expand globs)" and nothing else — the zero-epic stop lives in the auto-discovery  
  branch, which explicit paths bypass, so a mistyped path launches a loop over an empty list.  
  The criterion says each shape "reaches its documented pre-flight outcome", and it does: the  
  instruction that fires is documented. What is missing is a stop, not a sentence, and a  
  criterion phrased around *reaching an outcome* cannot see the difference. Left unrepaired  
  deliberately — the behaviour predates spec mode, so changing it is the mode-blind edit FR2  
  forbids — and recorded in the epic's Notes.

## Recommendations

1. **When a change makes an existing sentence wrong, re-read the nets that pin that sentence  
   before writing the fix.** The FR9 net asserted the defective wording verbatim and would  
   have defended it through review. Grep the test suites for the sentence you are about to  
   change, first — the same discipline CLAUDE.md already records for relocating a shared  
   convention, applied to rewording rather than moving.

2. **Write each control expecting it to fail, then check that it did.** Two of this epic's  
   four defects surfaced only because a control did not trip when it should have. A control  
   that passes on the first run has told you nothing; a control that fails has told you where  
   the predicate is blind. Both of this epic's blind predicates were mine, in the test.

3. **Name the wrong edit before choosing the measurement.** Story 4 wrote the accurate count  
   first and the discriminating one second. Writing the concrete mutation first — "what does  
   a mode-blind change actually look like in this file" — would have produced the right count  
   directly, and is the same move retro 24 recommended for exit codes.

4. **Extend retro 25's signal-set recommendation rather than restating it.** Retro 25 asked  
   for story-gate reads to be a signal. This epic adds that a mid-task control failure is  
   currently a signal and should probably not be one on its own — it fires on the test working  
   as intended. Both changes point the same way: the set should track *what was learned*, not  
   *what exited non-zero*.

5. **Run the refactoring pass looking for two readers of the same thing.** Two of the three  
   Step 5b passes found exactly that — `row_dirs`/`row_mode` open-coded twice and disagreeing,  
   and `discovery_slice` open-coded four times. Neither was findable by a test, because each  
   copy was individually correct. "Is this read anywhere else, and does the other reader agree  
   with me" is the question that pays at a story gate.
