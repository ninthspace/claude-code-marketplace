# Coverage Matrix: Coverage Matrix Format

**Source spec**: docs/specifications/22-spec-coverage-matrix-proof-tracking.md
**Epic**: docs/epics/19-epic-coverage-matrix-format.md
**Date**: 2026-02-25

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | 1. Verification column | Coverage matrix template in `/cpm:epics` includes a "Verified" column | Coverage matrix template in the Output section includes a "Verified" column after "Spec Test Approach", with initial value empty for all rows | Story 1 | `[manual]` | ✓ |
| 2 | 1. Verification column | Initial value for all rows is empty (unverified) | Coverage matrix template in the Output section includes a "Verified" column after "Spec Test Approach", with initial value empty for all rows | Story 1 | `[manual]` | ✓ |
| 3 | 4. Invalidation principle | Coverage matrix includes a blockquote verification rule after metadata, before the table | Coverage matrix template includes a blockquote verification rule after the metadata fields and before the table | Story 1 | `[manual]` | ✓ |
| 4 | 4. Invalidation principle | Rule text states verification is bound to criterion text and resets on modification | Blockquote text: "Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified." | Story 1 | `[manual]` | ✓ |
| 5 | 6. Epics invalidation | When `/cpm:epics` regenerates an epic, the coverage matrix verification column resets for affected rows | When `/cpm:epics` regenerates an epic that has an existing coverage matrix, the Verified column is cleared for affected rows | Story 2 | `[manual]` | ✓ |
