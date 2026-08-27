# Coverage — no bare ULID in stored prose

**Number**: 03-04  
**Source epic**: 03-04  
**Status**: pending  

## Coverage

| # | Requirement | Spec Text | Story Criterion | Covered by | Test Approach | Verified |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | FR16 | The refusal names the column and offers the `{{ref:<id>}}` form | `create_document_section` with a body containing a live document's bare ULID is refused, and the message names the column and shows the `{{ref:<id>}}` form. | Story 1 | `[integration]` | ✓ |
| 2 | FR16 | A prose value carrying a bare ULID that names a live `document` row is refused at the tool boundary. | must NOT — The same ULID written correctly as `{{ref:<id>}}` in the same body must not be refused. A check that cannot tell the marker from the bare id refuses the only correct way to write the reference. | Story 1 | `[integration]` | ✓ |
| 3 | FR16 | refused at the tool boundary | Every prose-bearing write tool is covered, with the prose columns enumerated from the classification in `dpm/tests/support/prose-columns.js` rather than from a list of tool names — so a prose column added by a later migration is covered without an edit here. | Story 1 | `[integration]` | ✓ |
| 4 | FR17 | Nothing `/dpm:publish` writes into `docs/` contains a bare ULID naming a live document. | Publishing a fixture corpus produces no file under `docs/` containing a ULID that names a live document. | Story 2 | `[integration]` | ✓ |
| 5 | FR19 | any column carrying a foreign key | A foreign-key column accepts a live document's ULID: `create_dependency` with `source_document_id` set to one is not refused. | Story 1 | `[integration]` | ✓ |
| 6 | FR19 | `session.state`, which is a skill-defined blob dpm does not interpret and never renders | `update_session` with a `state` blob containing a live document's ULID is not refused. The blob is skill-defined, dpm does not interpret it, and nothing renders it. | Story 1 | `[integration]` | ✓ |
| 7 | FR19 | A ULID naming something that is not a document — a session id quoted in an observation — is also left alone | A body containing a well-formed ULID that names no document — a session id quoted in an observation — is accepted. It has no marker form, so refusing it would reject prose with no correct alternative. | Story 1 | `[integration]` | ✓ |
| 8 | FR19 | exempts the columns where a ULID is the correct content | control — A check without these exemptions refuses the foreign-key case — a sweep of every TEXT column against this project's own database flagged 390 of them. The three criteria above are what stop the refusal rejecting correct content, and without the control they read as defensive padding rather than as the finding they are. | Story 1 | `[integration]` | ✓ |
