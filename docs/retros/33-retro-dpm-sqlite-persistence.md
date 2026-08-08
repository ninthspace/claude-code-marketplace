# Retro: dpm — SQLite-Backed Artefact Persistence

**Date**: 2026-08-08  
**Source**: docs/specifications/47-spec-dpm-sqlite-persistence.md  
**Stories**: no epic — 15/15 remediation tasks from review 04 complete

## Summary

Spec 47 went through a second adversarial review and a pivot in one session. The review found 15 findings (8 critical) in a document that had already been reviewed once and fully remediated; every critical one was found by *executing* the schema rather than by reading it. The pivot then applied all 15, and the act of applying them surfaced two further defects that neither review had — both in the same class, and both caught the same way.

## Observations

### Criteria Gaps

- **Two of FR14's criteria could not both pass.** Neither is wrong read alone; they contradict only when read against each other. Criteria are reviewed one at a time by default, which is exactly the reading that cannot find this.
- **Two criteria tested against values the spec never supplied** — FR13's "under the stated ceiling" with no ceiling stated, NFR5's "absent from the project glossary" with no glossary. A criterion that names a missing referent reads as testable and is not; the gap is invisible in the criterion and only appears when you go looking for the thing it cites.

### Codebase Discoveries

- **Executing the DDL found what reading it could not.** Sixteen of eighteen foreign keys into `document(id)` accepted a story under a spec; two branches from a common base collided on `document.id`; `sqlite3 .dump` emitted FTS5 shadow tables as hex blobs and ordered rows by insertion. All four are critical, all four are invisible in a schema that looks correct, and the first review missed all four.
- **A fresh `sqlite3` process defaults `foreign_keys` off.** Two probe results were quietly wrong until re-run with the pragma in the same session — the same false-pass class the spec is written against, reproduced in the tooling used to review it.
- **Applying a decision broke something the decision never mentioned.** Converting ids to ULIDs invalidated `document_fts`, because an external-content FTS5 table addresses rows by `content_rowid` and a rowid must be an integer. Nothing in the identity decision touched search; the failure appeared on the first row inserted after the change.

### Complexity Underestimates

- **The largest line item in the biggest decision was sized against the wrong denominator.** AD6 costed its tool surface from thirteen document kinds when the schema holds twenty-two entity types, because the nine that produce no file are easy to forget when counting things that produce files. The estimate was roughly half.
- **Six hand-maintained counts had drifted from what they counted**, including a table of eleven headings that contained twelve. A count restated in prose in several places is a fact with several copies and no owner.

### Patterns Worth Reusing

- **Re-extract and re-execute the DDL after every batch of edits.** It cost seconds per batch and caught the FTS5 break at the moment it was introduced, rather than at implementation where it would have been a rewrite. The spec is now the only artefact in this project whose central claim has been run.
- **Verify a count programmatically before writing it down.** A drift-table row count was asserted as 36 from memory and was actually 35 — the same class of defect the batch existed to remove, appearing inside the fix for it.

## Recommendations

- **Execute the artefact, not just the review.** Any spec carrying DDL, a schema, a config format or a protocol should have it extracted and run as part of review. Four criticals in an already-remediated document is the measure of what reading alone returns.
- **Read acceptance criteria in pairs within a requirement**, not one at a time. Mutual exclusivity is invisible in the single-criterion reading that both `cpm:spec` and `cpm:review` default to.
- **Treat a criterion citing a named value as a criterion citing a missing value until the value is found.** "the stated ceiling", "the project glossary", "the documented limit" — grep for the referent before accepting the criterion.
- **When a decision changes a primitive, sweep for its consumers before declaring it applied.** The ULID decision was correct, complete in its own terms, and broke a subsystem it never named. The sweep is what caught it; the decision text would not have.
- **Count in code, quote in prose.** Any number restated in more than one place in a document is drift waiting to happen — derive it once, verify it before each restatement.
