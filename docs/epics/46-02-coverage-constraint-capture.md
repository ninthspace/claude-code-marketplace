# Coverage Matrix: Constraint Capture and Transmission

**Source spec**: docs/specifications/46-spec-environmental-requirements.md
**Epic**: docs/epics/46-02-epic-constraint-capture.md
**Date**: 2026-07-27

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | FR8 | `cpm:brief` carries constraints forward. Its output template gains the section, so the preferred spec input stops discarding them. | The product brief output template carries a `## Constraints` section | Story 1 | `[manual]` | |
| 2 | FR8 | *(as row 1)* | must NOT — constraints are added to the skill's facilitation questions only, leaving the output template unchanged (the current defect, at `brief/SKILL.md:66` and `:75`) | Story 1 | `[manual]` | |
| 3 | FR8 | *(as row 1)* | A product brief produced by `cpm:brief` from a problem brief with constraints carries them into its output | Story 1 | `[manual]` | |
| 4 | FR1 | `cpm:spec` elicits environmental requirements and restrictions. A dedicated step covering both development and production: what must be available, and what must not be required. Runs whether or not any upstream document exists. | A spec authored with no upstream documents still reaches the constraints step, and produces either labelled entries or an explicit "none apply" | Story 2 | `[manual]` | |
| 5 | FR1 | *(as row 4)* | The step covers both development and production, and both what must be available and what must not be required | Story 2 | `[manual]` | |
| 6 | FR3 (partial) | Restrictions are a distinct class from requirements … The distinction survives into the document, not just the conversation. | The spec output template documents `ENVn` for requirements and `ENVXn` for restrictions under `## Non-Functional Requirements` | Story 2 | `[integration]` | |
| 7 | AD1 | A new `## Environmental Constraints` section with a parser change — distinguishable, but redesigns the requirement grammar that the Won't Have list explicitly rules out. | must NOT — a new `## Environment` section is introduced, which AD1 rejected and `coverage-parse.sh` cannot read | Story 2 | *(architecture decision — no row in the spec's table)* | |
| 8 | FR9 | Greenfield is covered. When no dependency manifest exists, the constraints are what drive installation, rather than `cpm:do`'s Test Runner Discovery finding nothing and an autonomous run proceeding with `Test command: none`. | The step asks about development tooling explicitly — test runner, browser automation — not only production environment | Story 2 | *(should-have — no row in the spec's table)* | |
| 9 | FR4 | Every constraint is falsifiable. It states a condition something can check — `PHP >= 8.2`, not "should be efficient". Unfalsifiable entries are refused or refined at authoring time. | The step refuses an entry with no checkable condition, naming which entry | Story 3 | `[manual]` | |
| 10 | NFR3 | Fail closed on a constraint that cannot be handled. An entry that is unparseable, unfalsifiable, or of an unrecognised class is reported and blocks, never silently dropped. | An entry that is unparseable, unfalsifiable, or of an unrecognised class is reported and blocks, never silently dropped | Story 3 | *(no row in the spec's table)* | |
| 11 | FR5 | The step inherits rather than re-asks. It reads the problem brief's `## Constraints` and any ADRs, presents what is already known, and facilitates only the gaps. | With a problem brief carrying `## Constraints`, the step presents those entries rather than re-asking | Story 4 | `[manual]` | |
| 12 | FR5 | It must reach **past** the product brief, which is where the information is currently lost. | must NOT — reads the product brief as the constraint source | Story 4 | `[manual]` | |
| 13 | FR5 | *(as row 11)* | The inheritance glob targets `docs/plans/[0-9]*-plan-*.md` and `docs/architecture/[0-9]*-adr-*.md` | Story 4 | `[manual]` | |
| 14 | AD5 | A startup check that globs the problem brief, presents what's known, facilitates only gaps, and degrades silently when absent — the shape `spec/SKILL.md:21-29` already uses. | The problem brief is located by following the product brief's `**Source**` field, not by "most recent" | Story 4 | *(architecture decision — no row in the spec's table)* | |
| 15 | NFR2 | Graceful degradation when upstream documents are absent. No problem brief, no ADRs, or a brief with no `## Constraints` — the new step still runs and facilitates from scratch, silently, exactly as ADR Discovery does today (`spec/SKILL.md:29`). Absence is never an error and never a prompt. | With no problem brief, no ADRs, or a brief with no `## Constraints`, the step still runs and facilitates from scratch, silently — absence is never an error and never a prompt | Story 4 | *(no row in the spec's table)* | |
| 16 | NFR2 | *(as row 15)* | The documented chain resolves: `cpm:spec`'s inheritance glob targets the directory `cpm:discover` writes problem briefs to, and the field it follows is the field `cpm:brief` writes | Story 5 | *(no row in the spec's table)* | |
| 17 | NFR2 | *(as row 15)* | Both extractions in the assertion above are non-empty before they are compared | Story 5 | *(no row in the spec's table)* | |
| 18 | FR8, FR5 | *(rows 1 and 11 combined — the end-to-end path)* | A problem brief carrying `## Constraints` reaches a spec's `## Non-Functional Requirements` as `ENV`/`ENVX` labels, verified hop by hop | Story 5 | `[manual]` | |

## Notes

**Rows 12 and 13 claim more verifiability than the spec did.** Spec 46 tags FR5's criteria
`[manual]`. Following the product brief's `**Source**` field makes the resolution path structural
fact rather than facilitation behaviour, so the story tags them `[integration]`. This is the only
place in epic 46-02 where a story strengthens a spec tag rather than matching it.

**Row 6 covers FR3 only partially.** The record-level half — that `ENV` and `ENVX` are separable
from the emitted records — is covered by epic 46-01, rows 3 and 4. Neither epic covers FR3 alone.

**Rows 7, 14 trace to architecture decisions, not to table rows in the spec.** AD1's rejection of a
separate section and AD5's inheritance shape both carry implementation constraints that would
otherwise have no home in any story.

**Story 3 has no automated criteria and no testing task.** FR4 asks whether a constraint states a
checkable condition; that judgement is the thing being specified. An assertion that the rule is
present in the prose would be a regression net presented as an oracle. Recorded here so the epic's
record says what verified each row — retro 23's pattern.
