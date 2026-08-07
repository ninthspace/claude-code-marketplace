# Coverage Matrix: Pivot the Three Interpretations

**Source spec**: docs/specifications/41-spec-artifact-pivot.md
**Epic**: docs/epics/41-02-epic-pivot-interpretations.md
**Date**: 2026-07-25

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | R2 — Pivot the three interpretations to Claude artifacts | The `status` full-picture document, the `epics` dependency view, and `present`'s HTML communication are published via the Artifact tool rather than written as local HTML. | Phase 4 contains no instruction to write a local HTML file | Story 1 | `[integration]` | ✓ |
| 2 | R2 — Pivot the three interpretations to Claude artifacts | The `status` full-picture document, the `epics` dependency view, and `present`'s HTML communication are published via the Artifact tool rather than written as local HTML. | No write to `docs/plans/epics-dependency-view.html` remains | Story 2 | `[integration]` | ✓ |
| 3 | R2 — Pivot the three interpretations to Claude artifacts | The `status` full-picture document, the `epics` dependency view, and `present`'s HTML communication are published via the Artifact tool rather than written as local HTML. | No write to `docs/communications/{nn}-{format}-{slug}.html` remains | Story 3 | `[integration]` | ✓ |
| 4 | R2 (degradation) | each of the three states its non-HTML degradation path | Degradation to the Phase 1–3 stdout narrative when the Artifact tool is absent is stated in the skill | Story 1 | `[manual]` | ✓ |
| 5 | R2 (degradation) | each of the three states its non-HTML degradation path | Degradation to a stated ready/blocked list in conversation is stated in the skill | Story 2 | `[manual]` | ✓ |
| 6 | R2 (must NOT) | must NOT remove `present`'s Markdown output or its `**Source artifacts**` field | must NOT remove `present`'s Markdown output or its `**Source artifacts**` field | Story 3 | `[integration]` | ✓ |
| 7 | AD1 — Artifacts change the medium, never the record | `present`'s Markdown carries the `**Source artifacts**` field that regeneration depends on | The Markdown output and its `**Source artifacts**` field are retained | Story 3 | `[integration]` | ✓ |
| 8 | AD3 — Degradation is to text, never to HTML | No skill may hard-fail when the Artifact tool is absent from the session. | must NOT hard-fail when the Artifact tool is absent | Story 1 | `[integration]` | ✓ |
| 9 | R5 — Preserve the register invariant | Every publish writes a row to `docs/artifacts/index.md` and an `**Artifacts**:` backlink on the source artifact | Publishing writes the register row in `docs/artifacts/index.md`; no `**Artifacts**:` backlink is written, because `status`/`epics` have no single source artifact and their scans are read-only | Stories 1, 2 | `[integration]` | ✓ |
| 9b | R5 — Preserve the register invariant | Every publish writes a row to `docs/artifacts/index.md` and an `**Artifacts**:` backlink on the source artifact | Publishing writes the register row, with the communication's existing `**Artifact**` field serving as the backlink R5 requires | Story 3 | `[integration]` | ✓ |
| 10 | AD5 — Export affordances are carried across provisionally | clipboard behaviour verified on a live published artifact, or the fallback applied | Clipboard behaviour is verified on a live published artifact, or the selectable `<pre>` fallback is applied | Story 4 | `[manual]` | ✓ |

## Notes

**Story-originated criteria (no spec counterpart).** Five criteria were added during breakdown, all from the surface survey rather than from spec text:

- *Story 1* — "All four secondary sites are updated". The spec named Phase 4 only; `status` carries the HTML story at four further sites (`:3`, `:12`, `:20`, `:31`). This is the fourth consecutive epic where the named site was not the only site.
- *Story 1* — the `"{complete} of {total} epics complete"` agreement statement. It is the stated invariant tying the document's numbers to the narrative's, and it sits inside the block being rewritten.
- *Story 2* — the readiness rule, the schema-tolerance block, and the general glob. All three are behavioural guarantees adjacent to the medium change, and all three would be silently lost in a careless rewrite. The glob in particular protects legacy flat-shape epics from vanishing from the view.
- *Story 3* — the `**Artifact**` field retention and the branding prohibition. The former is what makes update-in-place work; the latter is the prohibition the spec identifies as biting hardest on this skill.

**Row 9 split during execution (2026-07-25).** R5's spec text names two obligations — the register row and an `**Artifacts**:` backlink *on the source artifact*. `present` has a source artifact; `status` and `epics` do not, and both guarantee their scans modify nothing. Satisfying the backlink half for them would mean writing into every epic doc scanned, which contradicts their read-only guarantee and R2's must-NOT on Story 2. Row 9 now carries the register-row-only form for Stories 1–2; row 9b carries the full form for Story 3. AD1's consequence states the same thing from the other direction: for these two skills the register row *is* the durable trace, which is why it must not be dropped as well.

**No integration story for this epic.** The three pivots edit independent skill files with no shared runtime, and the one genuine cross-story integration point — whether the publish→register path works end to end — is exercised by Story 4.
