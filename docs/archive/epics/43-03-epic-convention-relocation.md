# Convention Relocation and Description Review

**Source spec**: docs/specifications/43-spec-ralph-autonomous-stalls.md
**Date**: 2026-07-26
**Status**: Complete
**Blocked by**: Epic 43-02-epic-autonomous-change-resolution (Complete 2026-07-26)
**Retro applied**: 21 · Criteria gaps · Applied — task 1.2 verifies the `cpm:quick` consumer claim in both directions (does the convention name it; does `quick/SKILL.md` reference it) before choosing add-the-reference or drop-the-claim, rather than assuming the criterion's premise
**Retro applied**: 21 · Testing gaps · Applied — five of this epic's seven criteria are `[manual]`; each is verified by a read with a named output, and the two `[integration]` criteria are never treated as covering the must-NOT
**Retro applied**: 18 · Codebase discoveries · Applied — criterion 1's absence assertion is paired with a by-name presence assertion for every relocated rule, so a lossy move fails rather than passing as a clean one
**Retro applied**: 18 · Patterns worth reusing · Applied — the Change Type Decision section's rules are enumerated as a named inventory before task 1.1 touches anything, turning the must-NOT into arithmetic; a rule inventory, not a byte count
**Retro applied**: 19 · Criteria gaps · Applied — Story 2 reads each `description` field for text that is absent and needed (the behaviours 43-01 and 43-02 added) as well as text that is present and wrong
**Retro applied**: 19 · Patterns worth reusing · Applied — every criterion's premise is checked at hydration: does each named file actually say what its criterion says it says

## Relocate the Change Type Decision convention into `cpm:do`
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: FR11, NFR5
**Retro**: [Codebase discoveries] A relocation breaks tests that pinned the rule's *file* while claiming to assert the rule's *content*. `test-autonomous-change-resolution.sh`'s "the `**Inline change**` field definition is unchanged" greps `skill-conventions.md`; the definition moved verbatim and the assertion failed anyway. An assertion about whether text is unchanged should follow the definition, not the file that happened to hold it when the test was written — otherwise a move and a mutation fail identically.
**Retro**: [Criteria gaps] The relocated inline-edit breadcrumb rule claimed its trail is read by "drift detection, retro synthesis". `cpm:retro` does read it; nothing does drift detection — the only occurrence of that phrase anywhere in `cpm/skills/` was the sentence making the claim. This is retro 21's lesson finding a live instance inside the very text being moved, two epics running. Corrected during the move and recorded here so the before/after read stays honest: this was the one change beyond relocation, and it removes a false claim rather than a rule.
**Retro**: [Patterns worth reusing] The rule inventory taken before task 1.1 made the must-NOT arithmetic. Eight named rules in, eight asserted by name out, plus a control proving each literal discriminates — so the diff review had something to check against rather than a judgement to make. Retro 18's baseline lesson transfers cleanly from suite counts to prose rules.
**Inline change**: criterion 2 identified its target as `do/SKILL.md:476`; the reference had moved to `:478` under epic 43-02 and task 1.1 moves it again. Restated to identify the reference by its quoted text and enclosing bullet, which survives the relocation the criterion is about. The `:476` pins in the spec and in 43-02's coverage matrix are records of what was true when written and are left alone (2026-07-26)

**Acceptance Criteria**:

- The **Change Type Decision** section no longer appears in `cpm/shared/skill-conventions.md`, and its content — decision matrix and inline-edit breadcrumb rule — appears in `do/SKILL.md` [integration]
- `do/SKILL.md`'s **Surface change moments explicitly** bullet no longer says "invoke the shared **Change Type Decision** procedure" and instead points at the local section [integration]
- `cpm/shared/skill-conventions.md` is smaller, with the reduction attributable to the relocated section rather than removed rules [manual] — spec 40's guard clause; only a human can confirm no rule was dropped
- The convention's claim that `cpm:quick` is a consumer is resolved — either `quick/SKILL.md` gains the reference or the claim is dropped [manual] — which of the two is right is a judgement about whether `quick` should have the gate at all
- must NOT drop any rule in the move — every rule present before the relocation is present after it [manual] — a rule-count grep would be a proxy for the thing that matters, not the thing itself

### Move the section into `do/SKILL.md`
**Task**: 1.1
**Description**: Decision matrix, inline-edit breadcrumb, skill-responsibility paragraph. Covers criteria 1 and 2.
**Status**: Complete

### Resolve the `cpm:quick` consumer claim
**Task**: 1.2
**Description**: The convention names `cpm:quick` as a consumer; `quick/SKILL.md` never references it. Covers criterion 4.
**Status**: Complete

### Read the moved section against the original
**Task**: 1.3
**Description**: Rule by rule, before against after. Covers criterion 3 and the must-NOT.
**Status**: Complete

### Write tests for the relocation
**Task**: 1.4
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`.
**Status**: Complete

---

## Read the changed skills' frontmatter descriptions against their new behaviour
**Story**: 2
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: FR13
**Retro**: [Criteria gaps] Reading the three descriptions for text that is *present and wrong* found nothing — all three sentences were true. The only defect was text *absent and needed*: `do`'s description said nothing about the autonomous change resolution 43-02 added, so neither a reader nor the skill-selection matcher had any signal that `do` can now rewrite an acceptance criterion under guard. Retro 19's lesson held exactly as stated, and a criterion phrased only as "any that misdescribes it is corrected" would have been satisfied on arrival by all three.
**Retro**: [Smooth deliveries] `clean`'s "Exhaustively lists every progress file" needed no change. The claim was false in practice before 43-01 and is now true, and confirming it was a two-minute read because `test-clean-invocation.sh` extracts the documented command and runs it verbatim — the fix and its evidence were already in the same place.

**Acceptance Criteria**:

- The `description` fields of `do`, `ralph` and `clean` are read against the behaviour those skills now have, and any that misdescribes it is corrected [manual] — the oracle is whether a sentence is true of a skill
- `clean`'s "Exhaustively lists every progress file" is read against its now-working enumeration [manual] — the claim was false in practice before 43-01; confirming it is now true is a read, not an assertion

### Read and correct the three `description` fields
**Task**: 2.1
**Description**: Covers both criteria. Retro 18 promoted this from lesson to rule after it recurred twice, both times as a frontmatter straggler that no criterion named. No testing task — the story is fully manual by design.
**Status**: Complete

---
