# Coverage Matrix: Spec-Scoped Coverage Presentation

**Source spec**: docs/specifications/44-spec-coverage-rollup.md
**Epic**: docs/epics/44-02-epic-coverage-presentation.md
**Date**: 2026-07-26

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|---|---|---|---|---|---|
| 1 | FR6 | `cpm:status` gains a spec-scoped phase rendering the roll-up organised by the spec's **MoSCoW structure**… | The invocation extracted verbatim from `status/SKILL.md` produces records when run with `CLAUDE_PROJECT_DIR` unset | Story 1 | `[integration]` | ✓ |
| 2 | FR6 | …organised by the spec's **MoSCoW structure**… with untraced requirements surfaced first. | Output is organised by the spec's MoSCoW headings, with untraced requirements before delivered ones | Story 1 | `[integration]` | ✓ |
| 3 | FR6 | …quoting each requirement's verbatim text… | Each requirement is presented with its verbatim text from the spec | Story 1 | `[integration]` | ✓ |
| 4 | AD5 | **Choice**: The script sources `resolve-project-root.sh`; tests extract the invocation from `status/SKILL.md` and run it with `CLAUDE_PROJECT_DIR` unset. | The invocation extracted verbatim from `status/SKILL.md` produces records when run with `CLAUDE_PROJECT_DIR` unset | Story 1 | — | ✓ |
| 5 | NFR5 | **Single source of the computation.** `cpm:status` and `cpm:ralph` call the script; neither reimplements the union, the matching, or the state derivation. | `cpm:status` calls the script; it does not reimplement the union, the matching, or the state derivation | Story 1 | — | ✓ |
| 6 | FR6 (must NOT) | A project-wide roll-up — this is spec-scoped, and `cpm:status` keeps its existing project view | must NOT change `cpm:status`'s existing project-wide view | Story 1 | — | ✓ |
| 7 | FR11 | Stakeholder artifact published through the existing shared **Artifact Publishing** procedure. No second publishing path. | The stakeholder artifact is published through the existing shared **Artifact Publishing** procedure, with no second publishing path | Story 2 | — | ✓ |
| 8 | FR11 | Stakeholder artifact published through the existing shared **Artifact Publishing** procedure. No second publishing path. | The artifact renders the same records the spec-scoped phase renders, organised by the spec's MoSCoW structure, with untraced requirements first | Story 2 | — | ✓ |
| 9 | FR11 (story-originated) | — | Publishing is separately confirmed and never the default | Story 2 | — | ✓ |
| 10 | FR7 | `✓` aggregation is labelled as **aggregation, not verification**, at every site presenting it. | Every site presenting aggregated `✓` also states that aggregation is not verification | Story 3 | `[integration]` | ✓ |
| 11 | FR7 | A wall of green must not read as independent confirmation. | A stakeholder reading the output does not take a wall of green as independent confirmation | Story 3 | `[manual]` | ✓ |

## Notes

**Row 4 repeats row 1's criterion** under AD5 rather than inventing a second one. FR6 asks for the phase; AD5 says how it must be tested. One criterion honestly satisfies both, and splitting it would produce a second criterion that tests nothing extra.

**Row 9 is `(story-originated)`** because "separately confirmed, never the default" is stated by the shared **Artifact Publishing** convention, not by spec 44. The spec-text cell is `—` rather than a quote the spec does not contain.

**Rows 5–9 show `—` for Spec Test Approach.** Spec 44's Acceptance Criteria Coverage table tags its must-haves plus NFR1 and the two Invariants; NFR5, FR11 and the Out-of-Scope line are untagged there. That is the spec being internally consistent rather than a coverage gap.

**What verified rows 1–6, stated plainly.** Rows 1, 3 and 4 have automated oracles: the invocation is extracted from `status/SKILL.md` and run with `CLAUDE_PROJECT_DIR` unset, and each `REQ` record's text is compared against the spec file itself. Rows 2, 5 and 6 do not — their subject is prose a model follows, and no assertion can tell a section that honours the MoSCoW rule from one that merely contains the words. They were verified by reading `### Phase 3b` in full, plus two things an assertion *can* carry: the records' data properties (every `REQ` carries a heading; untraced `STATE` records precede the rest), and, for row 6, `git diff` showing one line changed outside the new section. The suite's assertions on the phase's wording are labelled *regression nets* in the file for the same reason — they catch a later edit dropping a rule, which is not the same claim as the rule being honoured.

**What verified rows 7–9.** Row 7's "no second publishing path" is structural and was verified by assertion: the canonical reference line is extracted from `cpm/shared/skill-conventions.md`'s fenced block at run time and compared byte-for-byte, every reference in `status/SKILL.md` is checked against it, and the two pages' scratch paths are checked to be distinct — a shared path is what a second publishing path looks like in practice. Row 8 was verified by comparing the record types the page section names against the set the script actually emitted on a fixture run, so a type renamed in one place and not the other fails. Row 9 rests on the canonical line, which carries "always separately confirmed, and never the default" in its own bytes, plus the Input rule that a page request on a spec asks *which* page rather than choosing. Publishing itself is a model capability and cannot be exercised from a shell; nothing here claims to have published anything.

**FR7 (rows 10–11) also has a row in epic 44-03's matrix**, where the completion promise carries aggregated evidence. The criterion text is identical in both, so whichever epic's gate runs second re-reads the full set of sites rather than trusting the first. **This gate ran first.** The sweep found three sites presenting an aggregate — `cpm:status`'s Phase 3b section, its stakeholder page, and `cpm:do`'s batch-summary verification summary — and all three carry the statement. `cpm:ralph`'s promise is the fourth site and does not exist yet; `cpm:ralph` presents no `✓` at all today, which `test-aggregation-labelling.sh` asserts, so the criterion holds over the sites that exist rather than by exempting one. 44-03's gate inherits a named list, not a guess, and re-reads all four.

**Row 11 is `[manual]`, and this is the read.** Each of the three sites places the statement where the green appears — inside the section that shows it, not in a footnote — and each names *who placed the marks being counted*: `cpm:do`'s summary says "placed by this skill on its own work", and Phase 3b says every `✓` was placed by `cpm:do` on its own work. Naming the author is what stops the count reading as someone else's confirmation, and it is the part the wording was chosen for. The limit of this verdict is that it is the author's read of the author's prose; whether a stakeholder takes a wall of green as confirmation is answered by a stakeholder reading it, not here.

**`cpm:do`'s example strings were changed, not just annotated.** The item previously offered `"Coverage matrix: 9/9 requirements verified"` as the format to copy. A sentence saying the count is not verification, sitting beside an example that reads as verification, teaches the example. The examples now read "9 of 9 rows marked verified by this run".
