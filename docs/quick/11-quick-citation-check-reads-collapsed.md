# A citation check that a line break could blind

**Number**: 11  
**Status**: complete — All five criteria met. Shipped in 0.7.4. Raised as the outstanding issue on quick 10 and fixed at the helper level rather than by re-wrapping the one file that tripped it.  

**Closed**: 2026-09-02T11:00:00.000Z  

## What changed, and how it was verified

Three files: a new helper, the check that needed it, and the one file that tripped it.

**The defect was a check that could not see its subject, and it failed in the direction that passes.** `the Disposition rule reaches the corpus through Conversational Output` decides which skills name that section by testing `/\*\*Conversational Output\*\*/` against the raw source. `ralph` has named it since spec 47 — its startup paragraph lists it among the sections it uses — but with a hard wrap between the two words, so the pattern never matched. The skill was filed as the one skill the rule did not reach, the assertion said `['ralph']`, and the suite was green. Nobody was misled about ralph in particular; what was wrong was that the corpus-wide reach claim rested on a line break, and any other skill whose citation wrapped would have joined it silently.

**Fixed at the helper rather than at the file.** Re-wrapping `ralph`'s line makes the pattern match again and leaves the trap in place for the next file. `unwrapped(source)` collapses a whole file's whitespace, and the two filters in that test now read through it. This is `prose`'s own argument one scope up: its docblock already says that a SKILL.md is hard-wrapped, that an assertion written against the current wrapping fails on an edit that did not touch it, and — worse — that one written *with* a wrap in it stops constraining anything the moment the wrap moves. That reasoning was in the file the whole time and applied to sections; nothing had applied it to a citation.

**The `**Disposition**` filter in the same test matters more than the one that was caught.** It asserts no skill cites the subsection directly, and a wrapped direct citation would make that set falsely empty — so the check would report the placement intact at exactly the moment it had been undone. Both filters were changed, not just the one with a known failure.

The assertion is now an empty set of exceptions, and the comment explaining why `ralph` was deliberately outside the reach is removed. It was a reasonable claim — ralph instructs a loop how to verify rather than how to report — but the file has disagreed with it since spec 47, and 0.7.2's own commit message asserts all 23 skills cite the section. The file is what the reach is about.

**Verified by driving both directions rather than by reading.** With the original line break restored the reach test passes, which is what proves the helper carries the claim and the reflow is cosmetic. With `**Conversational Output**` deleted from `ralph` outright the test fails with `actual: ['ralph'], expected: []`, which is what proves the collapse widened what the check can see without weakening what it refuses — the obvious wrong fix being to relax the assertion until it stopped complaining. An inline control in the test asserts the wrap-insensitivity directly, so the property does not depend on someone repeating those two experiments. 968 of 968.

## Acceptance Criteria

| Met | Criterion | Note |
| --- | --- | --- |
| ✓ | A whole-file whitespace collapse exists as a named helper, documented with the failure it closes, so a citation check has something to read other than the raw source. | `unwrapped(source)` in `tests/support/skills.js`, placed beside `prose` because it is the same reasoning one scope up — `prose` collapses a section for a phrase, this collapses a file for a citation. Its docblock names the actual incident rather than describing a hazard in the abstract. |
| ✓ | The reach check reads collapsed source for both citations it looks for, and the corpus now reports every skill as naming `Conversational Output` — an empty set of exceptions rather than a named one. | Both filters in `the Disposition rule reaches the corpus through Conversational Output` pass through `unwrapped`. The `**Disposition**` filter matters as much as the other and for the worse reason: a wrapped direct citation would make that set falsely empty, so the check would report the placement intact precisely when it had been undone. The exceptions assertion is now `[]` and the comment claiming ralph was deliberately outside is gone, because the file has said otherwise since spec 47. |
| ✓ | The check no longer depends on how any file happens to wrap: restoring the original line break in `ralph` leaves the suite green. | Driven, not reasoned about. The citation was put back across two lines and the reach test passed, so the helper is what carries the claim and the reflow is a readability change rather than the fix. An inline control in the test asserts the same property directly: a re-wrapped citation must still be found once collapsed. |
| ✓ | A skill that genuinely stops citing the section still fails the check, so the fix widened what the check can see without weakening what it refuses. This is the must-NOT. | Driven by deleting `**Conversational Output**` from `ralph` outright: the test failed with `actual: ['ralph'], expected: []`. Without this the collapse would be indistinguishable from having relaxed the assertion to accept anything, which is the obvious way to make a stubborn test pass and the outcome this rules out. |
| ✓ | The release is consistent: dpm at 0.7.4 across the four sites the version-agreement suite compares, marketplace at 3.22.3, and `npm test` green. | 968 of 968. `git fetch` was run before any of it this time, per quick 10's observation, and `origin/main` was level — so unlike the previous run this work is not a rebuild of something already shipped. |
