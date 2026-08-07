# Coverage Matrix: Documentation and Release

**Source spec**: docs/specifications/41-spec-artifact-pivot.md
**Epic**: docs/epics/41-05-epic-documentation-and-release.md
**Date**: 2026-07-25

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | In Scope — documentation | Documentation updates: `cpm/README.md` and `cpm-training-guide.html`. | `cpm/README.md` describes no faithful-render capability and no local HTML output for `status`, `epics` or `present` | Story 1 | — | ✓ |
| 2 | In Scope — documentation | Documentation updates: `cpm/README.md` and `cpm-training-guide.html`. | `cpm-training-guide.html`'s `SKILLS` records show artifact outputs where the skill now publishes rather than writes HTML | Story 1 | — | ✓ |
| 3 | In Scope — release | Plugin version bump to 3.1.0, applied at every site (per retro 13/14: `grep -rn` the current version string first — three epics running, the named site has not been the only site). | `grep -rn` for the current version string is run **before** any edit, and its full result set is recorded | Story 2 | — | ✓ |
| 4 | In Scope — release | Plugin version bump to 3.1.0, applied at every site | Every site returned by that grep carries `3.1.0` afterwards | Story 2 | — | ✓ |
| 5 | Release (testing strategy) | version string is consistent across every site carrying it | Cross-manifest agreement is asserted structurally — semver shape and manifest-to-manifest equality — rather than by comparing against a pinned literal | Story 2 | `[integration]` — structural cross-file agreement, not a pinned literal (retro 14) | ✓ |

## Notes

**Traceability note.** This epic covers **In Scope** items rather than numbered requirements. The spec's requirement list (R1–R7) does not include documentation or the release bump; both appear only in the Scope section. Rows 1–4 therefore quote the Scope section, and rows 1–4 carry no Spec Test Approach because the spec's Acceptance Criteria Coverage table has no entry for them — only the version-consistency row does. This is a gap in the spec's own coverage table, recorded here rather than papered over.

**Story-originated criteria (no spec counterpart).** Two, both anti-staleness guards:

- *Story 1* — "must NOT introduce a skill count, version literal, or other snapshot value that a later change silently invalidates." A "20 skills" literal stamped on both HTML decks during the last docs refresh went stale within a day when a 21st skill was added. The same failure class as the pinned version literals retro 14 found.
- *Story 2* — "must NOT pin a version literal in any test assertion." Directly carried from retro 14's testing gap: two assertions pinned `2.0.0` and had been failing silently since that release, because nothing runs the suite between releases.
