# Coverage Matrix: Per-Skill Artifact Guidance

**Source spec**: docs/specifications/41-spec-artifact-pivot.md
**Epic**: docs/epics/41-03-epic-per-skill-artifact-guidance.md
**Date**: 2026-07-25

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | AD4 — `Artifact Publishing` is promoted to a top-level convention section | A new byte-identical reference line propagates to **10 skills** — the 3 pivoted plus the 9 R4 sites, with `status` and `epics` overlapping. | All ten skills carry the canonical reference line: `discover`, `brief`, `architect`, `spec`, `epics`, `review`, `audit`, `retro`, `status`, `present` | Story 1 | `[integration]` | ✓ |
| 2 | R4 (propagation) | all 10 skills carry the new reference line; `grep -rh … \| sort \| uniq -c` shows exactly one unique string | `grep -rh "{canonical line}" cpm/skills/ --include="*.md" \| sort \| uniq -c` reports exactly one unique string with a count of 10 | Story 1 | `[integration]` | ✓ |
| 2b | R4 (propagation) | all 10 skills carry the new reference line | In `architect`, `review` and `spec` the line sits outside the `Faithful Render (on request)` section, so epic 41-04's deletion of that section does not remove it | Story 1 | `[integration]` | ✓ |
| 3 | R4 — Add per-skill "when an artifact earns its place here" guidance | to `discover`, `brief`, `architect`, `spec`, `epics`, `review`, `audit`, `retro` and `status`. Each names what an artifact could show for *that skill's* output — a problem map, a value-proposition canvas, an architecture explorer, a requirement explorer, a dependency and readiness view, a findings explorer by severity, a nine-dimension findings dashboard, a trend view across retros, a project dashboard. | Each of the nine skills names what an artifact could show for *that skill's* output — a problem map for `discover`, a value-proposition canvas for `brief`, an architecture explorer for `architect`, a requirement explorer for `spec`, a dependency and readiness view for `epics`, a findings explorer by severity for `review`, a nine-dimension findings dashboard for `audit`, a trend view across retros for `retro`, a project dashboard for `status` | Story 2 | `[manual]` | ✓ |
| 4 | R4 (heuristic) | Each carries the same conservative heuristic the companion-asset sections already use: **if you cannot write the one-line justification for what the visual carries that the prose cannot, it has not earned its place.** | Each carries the conservative heuristic verbatim: **if you cannot write the one-line justification for what the visual carries that the prose cannot, it has not earned its place** | Story 2 | `[integration]` | ✓ |

## Notes

**Fidelity note — row 3.** The spec lists the nine artifact suggestions as an unattributed sequence; the story criterion binds each suggestion to its skill by name. The mapping follows the spec's own ordering exactly (`discover`…`status`), so this is a tightening rather than a divergence — but the pairing is the story's, not the spec's, and is recorded here for that reason.

**Row 2 rescoped and row 2b added during execution (2026-07-25).** The criterion's command was repo-wide (`cpm/`), which also matches the canonical line's *definition* in `cpm/shared/skill-conventions.md` — so it would have reported 11 against a criterion asserting 10. Scoped to `cpm/skills/`, matching the epic's edit scope. Row 2b was added because three of the ten sites (`architect`, `review`, `spec`) carried the superseded line inside the `Faithful Render (on request)` section that epic 41-04 deletes: an in-place replacement satisfies row 2 at this epic's gate and then silently drops the count to 7 when 41-04 runs, with no test failing at either gate. Row 2b binds the placement so the guarantee survives the next epic.

**Story-originated criteria (no spec counterpart).** Three, all defensive:

- *Story 1* — "must NOT introduce a variant phrasing, prefix, or suffix at any site". This is the failure mode that actually occurred during the `41bc7a5` work, where a `**Publish as an artifact (optional).**` prefix at one site broke byte identity across six.
- *Story 2* — "must NOT make artifact generation a default, automatic, or unconfirmed behaviour in any skill". R4 adds nine suggestion sites; without this boundary each is a candidate default.
- *Story 2* — "must NOT offer publishing during an autonomous run". Carried from the existing convention, which states autonomous runs never publish. Nine new sites is nine new chances to lose it.
