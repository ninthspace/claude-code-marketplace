# The signal and lesson contract

**Source spec**: docs/specifications/48-spec-learning-at-recurrence.md  
**Date**: 2026-10-30  
**Status**: Complete  
**Blocked by**: —  
**Lessons**: docs/retros/11-retro-prose-rules-need-a-reader-who-is-not-the-writer.md → "A criterion that names a mapping with no tag to key it on" (Story 1), docs/retros/11-retro-prose-rules-need-a-reader-who-is-not-the-writer.md → "A criterion promised that `do` and the auditor would follow a lesson" (build)  
**Amended**: 2026-10-30 — rewritten after review 06 (docs/reviews/06-review-learning-at-recurrence.md)

## The contract defines signals, recurrence and lessons by class
**Story**: 1  
**Status**: Complete  
**Audit**: pass (2026-10-30), 4 findings fixed — the round-2 Warning was fixed after the last audit and accepted unaudited by the user (2026-10-30)  
**Blocked by**: —  
**Satisfies**: FR1, FR2, FR3, FR5, FR6, FR7, NFR2  
**Effort**: high

**Acceptance Criteria**:

- `cpm-next/shared/artifacts.md` lists `**Signal**: {class-slug} — {project | process} — {what failed} ({file and step, rule or check})` among the fields `do` may add to a story or a `docs/quick/` record, and says what keys `project` (the cause is in this codebase) and `process` (a cpm-next rule could have prevented it; the parenthesis names the cpm-next file and step) `[manual]`
  - Evidence: `cpm-next/shared/artifacts.md:152` lists `**Signal**` among the story fields, also in a `docs/quick/` record; `:163-:172` define `project` and `process` (the parenthesis naming the cpm-next file and step) — red: n/a — manual
- The contract gives the slug rule (kebab-case, the kind of failure not the instance, reuse before inventing, a narrower slug when one class holds two distinct rules) and a seed list of at least five slugs, including `check-cannot-fail`, `shared-state-collision`, `unprovable-in-session`, `instance-not-rule` and `spec-drift` `[manual]`
  - Evidence: `artifacts.md:170` gives the slug rule (kebab-case, kind not instance, reuse first, a narrower slug when one class holds two rules) and seven seeds including `check-cannot-fail`, `shared-state-collision`, `unprovable-in-session`, `instance-not-rule` and `spec-drift` — red: n/a — manual
- It defines the signal reference (`{epic path} → Story {N} → {slug}`, or `{quick path} → {slug}`), the suffix ` — recurs: {reference} ({why it matches})`, the marks ` — raised {YYYY-MM-DD}`, ` — promoted {YYYY-MM-DD}` and ` — declined {YYYY-MM-DD}`, and adds the signal reference to the lesson reference forms `[manual]`
  - Evidence: `artifacts.md:167` gives the suffix and the `raised`, `promoted` and `declined` marks; `:171` the signal references (`{epic path} → Story {N} → {slug}`, `{quick path} → {slug}`) and the `recurs` reference forms; `:161` adds a signal reference and the amendment form `{library path} → amendment {class slug}` to the lesson reference forms; `:172` defines each mark — red: n/a — manual
- The `lessons-learned.md` entry and the amendment block carry `**Class**: {slug}`, the rule, how a criterion or check shows it holds and the owning layer, keep `**Promoted**` and `**Scope**` in the entry, and give `**Source**` as signal references or, for a lesson promoted from a legacy retro, `{retro path} → {Category} → "{observation text}"`; the duplicate rule is a matching `**Class**` confirmed by reading, or, for a lesson with no `**Class**`, a lesson that describes the same rule. Control: two entries with the same `**Class**` and the same rule cannot both be written under the rule as stated `[manual]`
  - Evidence: `artifacts.md:237-:257`: the amendment block and the `lessons-learned.md` entry carry `**Class**` and a body stating the rule, how a criterion or check shows it holds and the owning layer, keep `**Promoted**` and `**Scope**`, and give `**Source**` as signal references or the retro form; the closing rule (`:257`) matches a `**Class**` and the same rule, confirmed by reading, or, with no `**Class**`, a lesson describing the same rule. Control: two entries with the same `**Class**` and the same rule are a duplicate under `:257` — red: n/a — manual
- It states that `do`, `plan` and `review` read library lessons, signals that recur, and unretired legacy retro observations until `library learn` retires them `[manual]`
  - Evidence: `artifacts.md:174` states that `do`, `plan` and `review` read library lessons, signals that recur and unretired legacy retro observations — red: n/a — manual
- The story `**Retro**` field and the `**Retro waived**` epic field are gone; the artefact table no longer names `do` as a retro writer; the retro format, the `**Retired` marker and the old `**Recurrence**` rule are replaced by one sentence pointing to `library`. Control: `grep -c "Retro waived" cpm-next/shared/artifacts.md` returns 1 at `70c789c` and 0 after `[manual]`
  - Evidence: no `**Retro**` field, no `**Retro waived**` field; the artefact table (`:14`) names no skill as a retro writer; `## Retro (legacy)` (`:176`) is one sentence pointing to `library`. `grep -c "Retro waived" cpm-next/shared/artifacts.md`: 1 at `70c789c`, 0 now — red: n/a — manual
- No added sentence names a project, retro, version or earlier behaviour `[manual]`
  - Evidence: added lines read; the history grep over them returns nothing — red: n/a — manual

### Edit the contract
**Task**: 1.1  
**Description**: Edit the artefact table, story fields, epic header fields, lesson reference forms, retro and library sections of `cpm-next/shared/artifacts.md`, keeping a copy of the removed retro text for epic 48-04.  
**Status**: Complete

---
