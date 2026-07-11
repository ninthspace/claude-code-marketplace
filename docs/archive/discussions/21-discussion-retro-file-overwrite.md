# Discussion: Retro file overwritten on every /cpm:do conclusion

**Date**: 2026-06-07
**Agents**: Bella (Senior Developer), Margot (Software Architect)

## Problem reported

In a working repo, the retro file `11-retro-awareness-protocol.md` is replaced with a new version on the conclusion of **every** `/cpm:do` run, rather than a new `12-retro-…md` being created. The epics being run are sequential (95-14, 95-15, …) but the retro file's number (`11`) and slug (`awareness-protocol`) are **both frozen** regardless of which epic ran.

## Verdict: not intended — it is a bug

The spec is unambiguous. `cpm:do` Step 8 calls the shared **Retro Synthesis** procedure (`cpm/shared/skill-conventions.md:60`). Step 4 of that procedure (line 77) assigns `{nn}` via the shared **Numbering** procedure → `max(active ∪ archived) + 1` → a **new, incrementing file every time**; numbers are retired on archive, never reused. The only place "most recent retro / highest numeric prefix" is *read* is the **consumption** side — the `cpm:do` retro-consumption gate (`do/SKILL.md:38`) and the shared Retro Awareness procedure. That is a read, not a write. Overwriting the latest retro is therefore a deviation from spec.

## Root cause

Because **both** the number (`11`) and the slug (`awareness-protocol`) stay frozen across different source epics, the write path is **not deriving from the source epic at all** — it is reusing a filename it already had in context.

Mechanism: at `/cpm:do` startup the consumption gate reads "the most recent retro file (highest numeric prefix)" = `11-retro-awareness-protocol.md`, pinning that concrete path into context. At Step 8, instead of recomputing `{nn}` via Numbering and `{slug}` from this run's epic, the model writes back to the path already in context. **Read-latest at the top, write-back-to-that-same-latest at the bottom** — the two retro touchpoints get conflated because one handed the model a real filename and the synthesis step never forces it to discard that and recompute.

Effect: retros for every epic since `11` have been **lost** (overwritten). Git history of `11-retro-awareness-protocol.md` is the only copy.

## Agreed conclusions

- **Plain global `{nn}` numbering is correct.** Retros also run ad-hoc via `/cpm:retro` and have no epic, so epic-scoped `{nn}-{mm}` would be wrong. The flat `docs/retros/` sequence is right.
- **Slug must derive from *this run's* source epic** (e.g. `95-15-epic-foo.md` → `15-retro-foo.md`). The current `awareness-protocol` name is a fossil carried forward by the overwrite; fix the write path and the name fixes itself.
- **Consumption gate selects by recency only** (highest numeric prefix) — no relevance/source filtering — and reads exactly **one** retro.
- **Chris never runs epics in parallel.** Single-threaded → recency *is* relevance → the recency-only gate is correct. Source-aware selection is **not needed** and should **not** be added (simplest correct design; avoids a boundary to maintain). Answer to "is there a consequential issue picking up the right retro next run?": **no** — once the overwrite is fixed and retros increment, highest-prefix = the immediately preceding run's retro = exactly what's wanted.

## Application tracking (where "we applied a retro lesson" is recorded)

- Recorded **in the consuming epic doc, never in the retro file.** The `cpm:do` consumption gate (`do/SKILL.md:45`) appends a breadcrumb to the epic being worked, in its top-level metadata block below `**Blocked by**`:  
  `**Retro applied**: {nn} · {category} · {disposition} — {note}` (disposition = Applied / Deferred / Obsolete).
- Linkage is **one-directional: epic → retro.** A retro file carries no record of where/whether its lessons were applied; you'd scan epic docs for `**Retro applied**: {nn}`.
- **Decision:** this is acceptable. Reverse-lookup ("which retros were never applied") is done **on-demand as a consultation** by sweeping the epic docs — not maintained as state in the retro files. Caveat: the sweep is only trustworthy once the overwrite bug is fixed.

## Fix scope (for handoff to /cpm:quick)

1. **Recompute the write target, don't inherit it (the actual bug).** In Retro Synthesis step 4, derive `{nn}` (Numbering) and `{slug}` (from this run's source epic) at write time, explicitly independent of whatever filename the consumption gate loaded.
2. **No-overwrite guard.** If the computed path already exists, that's a miscompute — fail/recompute, never overwrite.
3. **(Recommended) Make selection observable.** At the consumption-gate incorporate prompt, state which retro was chosen + its source + date, so a mis-pick is never silent.

## Backlog (not this fix)

- The consumption gate reads only the single most-recent retro, so **deferred/unapplied lessons in older retros silently fall off** the conveyor once a newer retro exists. The producer-side "is this lesson still open?" state does not exist anywhere. This is a feed-forward gap separate from the overwrite bug — worth its own look later.
