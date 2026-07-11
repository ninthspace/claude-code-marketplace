# Coverage Matrix: Retro Lesson Promotion (`cpm:retro learn`)

**Source spec**: docs/specifications/36-spec-retro-lesson-promotion.md
**Epic**: docs/epics/36-01-epic-retro-lesson-promotion.md
**Date**: 2026-06-17

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | `learn` action | invoking `/cpm:retro learn` enters a promotion flow (distinct from the default synthesis flow) | `/cpm:retro learn` enters a promotion flow distinct from the default synthesis flow, documented in `cpm:retro` SKILL | Story 1 | `[manual]` | ✓ |
| 2 | Candidate selection | scan `docs/retros/` observations, excluding any already carrying a `**Retired` marker, present them grouped by source retro/category, and let the user pick the lesson(s) to promote | Candidate scan presents `docs/retros/` observations grouped by source retro/category; must NOT offer an observation carrying a `**Retired` marker | Story 1 | `[manual]` | ✓ |
| 3 | Library write | append the lesson as a `##` entry to `docs/library/lessons-learned.md`, creating the file with conformant `cpm:library` front-matter on first promotion | First promotion creates `docs/library/lessons-learned.md` with conformant `cpm:library` front-matter; later promotions append a `##` entry; must NOT overwrite existing content | Story 2 | `[manual]` | ✓ |
| 4 | Front-matter conformance | the file uses `cpm:library`'s six-field model (`title`/`source`/`added`/`last-reviewed`/`scope`/`summary`); `scope` derived via `cpm:library`'s auto-scope heuristics (unioned across entries); `last-reviewed` bumped on each append | `scope` is derived via `cpm:library`'s auto-scope heuristics (unioned across entries) and `last-reviewed` is bumped on each append | Story 2 | `[manual]` (+ `[integration]` at consume time) | ✓ |
| 5 | Atomic retirement | on a successful write, retire the source observation in its retro via the #16 marker, reason = `promoted to docs/library/lessons-learned.md`. Promotion and retirement are one operation. | A successful write atomically retires the source observation (reason → `promoted to docs/library/lessons-learned.md`); must NOT leave a promoted lesson un-retired | Story 2 | `[manual]` | ✓ |
| 6 | Bidirectional provenance | the library entry records its source retro path + category + observation text + promotion date; the retro marker points back to the library doc | Each entry records source retro path + category + observation text + promotion date; the retro marker points back to the library doc | Story 2 | `[manual]` | ✓ |
| 7 | Idempotency | an observation already retired/promoted is not offered and not duplicated | must NOT offer an observation carrying a `**Retired` marker (offer side); Re-running on an already-promoted lesson is a no-op; must NOT create a duplicate entry (write side) | Story 1 & Story 2 | `[manual]` | ✓ |
