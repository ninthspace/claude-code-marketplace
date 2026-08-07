# Retro: Convention Relocation and Description Review

**Date**: 2026-07-26
**Source**: docs/epics/43-03-epic-convention-relocation.md
**Stories**: 2/2 complete

## Summary

The Change Type Decision convention moved out of `cpm/shared/skill-conventions.md` — injected in full into every session in this repo — and into `cpm/skills/do/SKILL.md`, its only consumer. The shared file dropped 1,844 bytes (55,082 → 53,238), all of it the relocated section. All eight of the section's rules came across, and `do`'s frontmatter description gained the one thing it was missing.

Both stories were short and both found a defect the criteria did not name. That is the epic's pattern: the criteria were about *moving text correctly* and *reading sentences for falsehood*, and in each case the real defect was one category over — a false claim inside the text being moved, and a true sentence with something missing after it.

## Observations

### Criteria Gaps

- **A convention named a consumer that does not exist — again.** The relocated inline-edit breadcrumb rule claimed its trail is read by "drift detection, retro synthesis". `cpm:retro` does read it; nothing does drift detection, and the only occurrence of that phrase anywhere in `cpm/skills/` was the sentence making the claim. This is the second epic running (retro 21, `cpm:status`) where a field's documented consumer turned out not to consume it. Both were inherited claims nobody had rechecked, and both survived because a named consumer reads as evidence rather than as an assertion.
- **"Any that misdescribes it is corrected" is satisfied on arrival.** Reading `do`, `ralph` and `clean`'s descriptions for text that was *present and wrong* found nothing — all three sentences were true. The only defect was text *absent and needed*: `do`'s description said nothing about the autonomous change resolution 43-02 had added, so neither a reader nor the skill-selection matcher had any signal that `do` can now rewrite an acceptance criterion under guard. Retro 19 predicted this shape exactly, and the criterion as written could not have found it.

### Codebase Discoveries

- **A relocation breaks tests that pinned a rule's file while claiming to assert its content.** `test-autonomous-change-resolution.sh`'s "the `**Inline change**` field definition is unchanged" grepped `skill-conventions.md`. The definition moved verbatim and the assertion failed anyway — a move and a mutation failed identically. An assertion about whether text is unchanged should follow the definition, not the file that happened to hold it when the test was written. Worth sweeping for before the next relocation: the shared file still has sections referenced by three skills or fewer.

### Patterns Worth Reusing

- **A rule inventory taken before the first edit turns a must-NOT into arithmetic.** Eight named rules enumerated before the move, eight asserted by name after it, plus a control proving each literal discriminates. The before/after review then had something to check against instead of a judgement to make. Retro 18's baseline lesson transfers from suite counts to prose rules without modification.
- **Pair every absence assertion with its inverse.** "The section no longer appears in the shared file" is satisfied equally by a clean move and by a deletion that lost half its rules. Retro 18 named this for validator pruning; it applies unchanged to relocating prose, and it is what the eight by-name presence assertions exist for.

### Smooth Deliveries

- **`clean`'s description needed no change, and confirming that took two minutes.** The claim "Exhaustively lists every progress file" was false in practice before 43-01 and is now true. It was cheap to verify because `test-clean-invocation.sh` extracts the documented command from the SKILL.md and runs it verbatim — the fix and its evidence live in the same place, so the read had something executable behind it rather than a promise.

## Recommendations

- Before the next section is relocated out of `cpm/shared/skill-conventions.md`, sweep the suites for assertions that grep that file by path while claiming to test content. They will fail on the move and read as regressions.
- Treat a documented consumer as a claim to verify, not evidence. Two epics running, a field's named consumer did not consume it. A one-line grep at the moment the claim is written costs nothing; found later it costs a criterion.
- When a story's criteria are all of the form "X is corrected if wrong", add the paired "X says Y" for whatever recently landed. Three descriptions were true and one was incomplete, and only the paired form finds the second kind.
- `CLAUDE.md`'s guidance section is now stale in two ways: it lists Change Type Decision among the sections awaiting relocation, and its stated 49,704-byte baseline disagrees with the committed 55,082. Both are Chris's file to correct; flagged rather than edited.
