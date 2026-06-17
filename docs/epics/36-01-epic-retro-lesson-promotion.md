# Retro Lesson Promotion (`cpm:retro learn`)

**Source spec**: docs/specifications/36-spec-retro-lesson-promotion.md
**Date**: 2026-06-17
**Status**: Complete
**Blocked by**: —
**Retro applied**: 02 · Pattern worth reusing · Deferred — concerns shared HTML template authoring; this epic produces skill prose + a Markdown library doc, no HTML/design output (lesson still valid, kept on record).

## Add the `learn` action and lesson selection
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: `learn` action; candidate selection; idempotency (offer side)

**Acceptance Criteria**:

- `/cpm:retro learn` enters a promotion flow distinct from the default synthesis flow, documented in `cpm:retro` SKILL [manual]
- Candidate scan presents `docs/retros/` observations grouped by source retro/category; must NOT offer an observation carrying a `**Retired` marker [manual]
- Multi-select is supported, and a confirmation preview (proposed entry + derived scope + the retirement that will follow) is shown before any write [manual]

*All criteria `[manual]`: skill-instruction prose behaviour, no executable oracle — verified by inspection and a dry-run of the action.*

### Add `learn` action dispatch
**Task**: 1.1
**Description**: Add `learn` to `cpm:retro` Input parsing, branching to the promotion flow distinct from the default synthesis flow. Covers the `learn` action criterion; documents the action in the SKILL.
**Status**: Complete

### Gather and present candidates
**Task**: 1.2
**Description**: Scan `docs/retros/` observations, exclude any carrying a `**Retired` marker, group by source retro/category, support multi-select, and render the pre-write confirmation preview. Covers the candidate-selection and offer-side idempotency criteria.
**Status**: Complete

**Retro**: [Smooth delivery] Adding the two-mode dispatch and Step L1 was a clean prose addition that reused `cpm:retro`'s existing Input/section structure; the #16 Retro Retirement convention gave offer-side idempotency for free (just skip `**Retired` observations).

---

## Promote-and-retire (atomic) [plan]
**Story**: 2
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: library write; front-matter conformance; atomic retirement; bidirectional provenance; idempotency (no-dup)

**Acceptance Criteria**:

- First promotion creates `docs/library/lessons-learned.md` with conformant `cpm:library` front-matter; later promotions append a `##` entry; must NOT overwrite existing content [manual]
- `scope` is derived via `cpm:library`'s auto-scope heuristics (unioned across entries) and `last-reviewed` is bumped on each append [manual]
- Each entry records source retro path + category + observation text + promotion date; the retro marker points back to the library doc [manual]
- A successful write atomically retires the source observation (reason → `promoted to docs/library/lessons-learned.md`); must NOT leave a promoted lesson un-retired [manual]
- Re-running on an already-promoted lesson is a no-op; must NOT create a duplicate entry [manual]

*All criteria `[manual]`: skill-instruction prose plus a generated Markdown artifact, no test harness covers it — verified by inspection and a dry-run. `[plan]` on this story: it defines the on-disk format contract for a new library doc, so the layout should be agreed before implementation.*

### Library write with conformant front-matter
**Task**: 2.1
**Description**: Create-or-append `docs/library/lessons-learned.md` — six-field `cpm:library` front-matter (referencing `cpm:library`'s documented format in place, not reimplementing it), `scope` as the auto-scope union, `last-reviewed` bump, and per-entry provenance. Covers the library-write, front-matter-conformance, and library-side provenance criteria.
**Status**: Complete

### Atomic retirement and idempotency
**Task**: 2.2
**Description**: As part of the same operation as 2.1, write the #16 retirement marker back-linking the library doc (retro-side provenance), and guard against promoting an already-retired/promoted lesson. Covers the atomic-retirement and no-duplication criteria.
**Status**: Complete

### Version bump and README note
**Task**: 2.3
**Description**: Bump cpm (`plugin.json` + marketplace entry) and the marketplace version, and document the new `learn` action in the README. Housekeeping for the user-visible behaviour change.
**Status**: Complete

**Retro**: [Pattern worth reusing] Specifying the library write by *referencing* `cpm:library`'s front-matter + auto-scope sections (rather than restating them) kept the format single-sourced; the `[plan]` gate earned its place here by pinning the `lessons-learned.md` format contract before the prose was written.

---
