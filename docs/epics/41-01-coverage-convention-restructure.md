# Coverage Matrix: Shared Convention Restructure

**Source spec**: docs/specifications/41-spec-artifact-pivot.md
**Epic**: docs/epics/41-01-epic-convention-restructure.md
**Date**: 2026-07-25

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | R3 — Rewrite the HTML Output convention | Three roles become one (companion assets), with the publishing procedure promoted alongside it. Retire the Tier 1 / Tier 2 vocabulary. | `## HTML Output`'s opening paragraph names one role (companion assets), not three | Story 1 | `[integration]` | ✓ |
| 2 | R3 — Rewrite the HTML Output convention | the storage-path table retains the companion-asset row and no other | The storage-path table retains the companion-asset row and no other | Story 1 | `[integration]` | ✓ |
| 3 | R3 — Rewrite the HTML Output convention | Retire the Tier 1 / Tier 2 vocabulary. | `grep -rn "Tier 1\|Tier 2" cpm/ --include="*.md"` returns zero hits | Story 1 | `[integration]` | ✓ |
| 4 | R3 — Rewrite the HTML Output convention | `Artifact Publishing` exists as an `##` section in `skill-conventions.md` | `Artifact Publishing` is an `##` top-level section, not nested under HTML Output | Story 2 | `[integration]` | ✓ |
| 5 | AD2 — Two design systems, cleanly separated | The publishing mechanics change from *"re-emit `template.html` as a body fragment"* to *"compose per `artifact-design`"*. | Mechanics step 2 instructs composing the page per the `artifact-design` skill, not re-emitting `cpm/assets/html/template.html` as a fragment | Story 2 | `[integration]` | ✓ |
| 6 | AD4 — `Artifact Publishing` is promoted to a top-level convention section | A new byte-identical reference line propagates to **10 skills** | One canonical reference line is recorded in the convention, worded so it holds for skills that produce no local HTML | Story 2 | `[integration]` | ✓ |
| 7 | R5 — Preserve the register invariant | Every publish writes a row to `docs/artifacts/index.md` and an `**Artifacts**:` backlink on the source artifact, per `cpm:artifact`. | The register row and the `**Artifacts**:` backlink are stated as part of publishing, not as a follow-up step | Story 2 | `[integration]` | ✓ |
| 8 | R5 — Preserve the register invariant | must NOT allow any publishing path that omits the register row or the `**Artifacts**:` backlink | must NOT allow any publishing path that omits the register row or the `**Artifacts**:` backlink | Story 2 | `[integration]` | ✓ |
| 9 | R7 — A fragment validator | rejects `<!doctype>`, `<html>`, `<head>` and `<body>` | `check_valid_fragment` rejects `<!doctype>`, `<html>`, `<head>` and `<body>` | Story 3 | `[integration]` | ✓ |
| 10 | R7 — A fragment validator | accepts a leading `<style>` block | `check_valid_fragment` accepts a leading `<style>` block | Story 3 | `[integration]` | ✓ |
| 11 | R7 — A fragment validator | asserts self-containment | `check_valid_fragment` asserts self-containment on the artifact scratch path `docs/plans/{skill}-artifact-{nn}-{slug}.html` | Story 3 | `[integration]` | ✓ |

## Notes

**Story-originated criteria (no spec counterpart).** Two criteria on Story 1 were added during breakdown and are deliberately not traceable to spec text:

- *"The canonical export-affordance pattern (copy-as-prompt / copy-as-JSON) is **relocated** into the Artifact Publishing section, not deleted"* — the spec says to retire the Tier 1/Tier 2 vocabulary but does not say what becomes of the pattern that vocabulary governs. Read literally, R3 would destroy content AD5 and Story 41-02.4 both depend on. This criterion closes that gap.
- *"must NOT delete the self-contained rule or the generate-from-source rule"* — both rules survive the pivot scoped to companion assets, and both are adjacent to deleted content.
