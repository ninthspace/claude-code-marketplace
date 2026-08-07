# Coverage Matrix: Convention Relocation and Description Review

**Source spec**: docs/specifications/43-spec-ralph-autonomous-stalls.md
**Epic**: docs/epics/43-03-epic-convention-relocation.md
**Date**: 2026-07-26

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|---|---|---|---|---|---|
| 1 | FR11 | Relocate the Change Type Decision convention into `cpm:do` (verified single consumer; the convention names `cpm:quick` as a second, but `quick/SKILL.md` never references it). | The **Change Type Decision** section no longer appears in `cpm/shared/skill-conventions.md`, and its content — decision matrix and inline-edit breadcrumb rule — appears in `do/SKILL.md` | Story 1 | — | ✓ |
| 2 | FR11 | Relocate the Change Type Decision convention into `cpm:do` (verified single consumer…). | `do/SKILL.md`'s **Surface change moments explicitly** bullet no longer says "invoke the shared **Change Type Decision** procedure" and instead points at the local section | Story 1 | — | ✓ |
| 3 | FR11 | …the convention names `cpm:quick` as a second, but `quick/SKILL.md` never references it | The convention's claim that `cpm:quick` is a consumer is resolved — either `quick/SKILL.md` gains the reference or the claim is dropped | Story 1 | — | ✓ |
| 4 | NFR5 | Net reduction in `cpm/shared/skill-conventions.md`, attributable to *relocated* content rather than removed rules. The file is 49,704 bytes / ~12.4k tokens and is injected in full into every session in this repo. | `cpm/shared/skill-conventions.md` is smaller, with the reduction attributable to the relocated section rather than removed rules | Story 1 | `[manual]` | ✓ |
| 5 | NFR5 (story-originated) | — | must NOT drop any rule in the move — every rule present before the relocation is present after it | Story 1 | — | ✓ |
| 6 | FR13 | Review frontmatter `description` fields of every changed skill. | The `description` fields of `do`, `ralph` and `clean` are read against the behaviour those skills now have, and any that misdescribes it is corrected | Story 2 | — | ✓ |
| 7 | FR13 | Review frontmatter `description` fields of every changed skill. | `clean`'s "Exhaustively lists every progress file" is read against its now-working enumeration | Story 2 | — | ✓ |

## Notes

**Row 2, inline change (2026-07-26).** The criterion identified its target as `do/SKILL.md:476`. Epic 43-02's edits moved that reference to `:478`, and Story 1 task 1.1 moves it again — so the criterion named a line that did not hold it and could not hold it once satisfied. Restated to identify the reference by its quoted text and enclosing bullet. The spec text in this row is unaffected: FR11 pins no line. The `:476` references elsewhere in spec 43 and in 43-02's coverage matrix are records of what was true when written and are deliberately left alone. Breadcrumb on Story 1.

Rows 1–3 and 5–7 show `—` for Spec Test Approach because FR11 and FR13 are should-haves, and spec 43's Acceptance Criteria Coverage table tags its must-haves plus the NFRs it named. That is the spec being internally consistent rather than a coverage gap.
