# Discussion: Document Numbering Scheme

**Date**: 2026-04-11
**Agents**: Margot, Elli, Bella, Ren, Tomas, Jordan, Sable, Casey, Priya

## Starting questions

Chris raised two concerns about the current CPM document numbering scheme (`{nn}-{type}-{slug}.md`, zero-padded to 2 digits, auto-incremented per directory):

1. **The 99 ceiling** — what happens when any directory crosses 99?
2. **Spec→epic traceability** — epics currently use an independent number sequence from specs, so `docs/epics/15-epic-foo.md` has no filename-level link to the spec that spawned it. Should epics inherit the parent spec's number as a prefix (e.g. `39-01-epic-foo.md`)?

## Current state (established during discussion)

- Every skill uses `{nn}` zero-padded 2-digit auto-increment scoped per-directory: `specifications/`, `epics/`, `plans/`, `briefs/`, `discussions/`, `reviews/`, `retros/`, `architecture/`, `quick/`.
- Counts at time of discussion: specifications 27, epics 24, discussions 13 — runway to 99 exists but the ceiling is visible.
- Spec→epics numbering is **independent**. Spec 03 (party mode) has no structural link to epic 03 (review skill). Traceability lives inside document content, not filenames.
- Epics already have a precedent for companion files sharing a number: `{nn}-epic-{slug}.md` + `{nn}-coverage-{slug}.md`.
- 2-digit zero-pad is hardcoded across ~9 skills in identical "Glob the dir, find max, increment, pad to 2" language.

## Key decisions reached

### Decision 1 — Numbering width: minimum 2 digits, grow naturally past 99

**Rule**: numbers are zero-padded to a **minimum** of 2 digits. Numbers ≥100 use their natural width. Sequence: `01, 02, ..., 99, 100, 101, ...`. Integer comparison (not lexical) is used for "find next number." **No bulk renaming or widening migration, ever.**

**Why this shape**:
- Earlier in the discussion the team floated an "auto-widen on save of #100" mechanic (rename all `NN-*` to `0NN-*` atomically, then save `100-*`). Sable and Casey pushed back hard: the operation is not atomic (99 sequential renames + a write), references to old filenames exist *inside other docs* (discussions, retros, blocked-by clauses) and would need grep-based content rewriting, and a crash mid-migration leaves a broken directory with no clean rollback. A reliable version of widening would need a clean-git-tree precondition, dry-run preview, and single-commit apply — essentially a dedicated `/cpm:widen` skill.
- Chris proposed the simpler alternative: don't renumber at all. New files at 100+ are written at their natural width next to the existing 2-digit files. Old files archive out naturally over time, so the mixed-width state is transient.
- Bella confirmed the "find next number" logic already uses integer comparison, so mixed widths compare correctly without code changes.
- Priya noted the only real cost is transient `ls` sort-order ugliness (lexically `100 < 28 < 99`), which is small in practice — most access is via editor fuzzy-find, grep, or skills that parse the number. `ls -v` gives natural sort on Unix.
- Margot framed the trade as "favour invariants that hold forever over operations that have to be executed perfectly" — mixed-width coexistence is a trivial permanent invariant; widening is a scary one-shot operation. Correct trade.

**Applies to every numbered artifact type**: specifications, epics, plans, briefs, discussions, reviews, retros, architecture ADRs, quick records. The phrasing change is mechanical and should be identical across all nine skills — one canonical sentence, copy-pasted verbatim, so the skills can't drift apart.

**Documented invariant**: "Numeric prefix is an integer identifier, not a fixed-width string. Never pad existing files to match new widths."

### Decision 2 — Numbers are retired on archive (never reused)

**Rule**: `/cpm:archive` never resets numbering. New number = `max(active ∪ archived) + 1`. Numbers are assigned once and never reused.

**Why**: Chris originally floated "archive as a reset opportunity" — restart from 01 after a big archive. Ren flagged that reset-to-01 is dangerous for cross-references: discussions, retros, and reviews reference specs and epics *by number*. If spec 15 is archived and a new spec 15 later appears, any review saying "raised in spec 15" is ambiguous — possibly pointing at the wrong artifact. The safe rule is *"retired numbers stay retired."*

This decision is load-bearing for Decision 1: "seamlessly past 99" only works if archive doesn't reset. If archive reset, you'd rarely hit the ceiling — but you'd inherit reference-ambiguity bugs instead. The combined shape is the cleaner choice.

### Decision 3 — Epic sub-numbering: `{parent}-{seq}-epic-{slug}.md`

**Rule**: new epics use a two-part numeric prefix.

- Format: `{parent}-{seq}-epic-{slug}.md` and `{parent}-{seq}-coverage-{slug}.md`.
- `{parent}` = the spec number the epic was born from. Follows Decision 1's width rule (so `100-01-epic-foo.md` is valid).
- `{seq}` = sequence number within that parent. Starts at `01`, increments per new epic under the same parent, zero-padded to a minimum of 2 digits (same rule as Decision 1 — unlikely ever to exceed 99 per spec, but the rule is uniform).
- **Orphan epics** (from `/cpm:quick`, discussion-driven work, or any epic without a parent spec) use `00` as the parent prefix: `00-01-epic-orphan.md`, `00-02-...`, etc. This keeps the filename shape uniform with no special-cases, and makes "has a parent spec" visually obvious at a glance.
- **Sub-numbers are immutable identifiers**, not ordinals. If epic `27-02` is deleted during a pivot, the next new epic under spec 27 is `27-04`, *not* `27-03`. Gaps are allowed and expected. This mirrors JIRA-style ticket IDs — nobody renumbers JIRA-123 when JIRA-122 is deleted. It also keeps "next number" logic simple: glob `{parent}-[0-9]*-epic-*.md`, extract the second field, integer-max, increment. No cascade, no reconciliation.

**Why**: Chris confirmed the motivation is *filename-level traceability*. Currently, to know which spec spawned which epic, he has to open files or grep content — inefficient. The two-part filename surfaces the parent link directly. Elli noted the format serves both of the traceability use cases simultaneously: "which spec did this come from" (read the first number) and "which epics share a parent" (sort/group by first number).

**The epic sub-numbering scheme applies only to epics (and their companion coverage files).** Other artifact types (specs, briefs, plans, etc.) retain flat numbering. Chris confirmed the pain is specifically at the spec→epic junction; no other cross-type link was requested. If later a brief→discussion or ADR→spec link feels needed, that's a separate conversation.

### Decision 4 — Backwards compatibility: old flat epics stay put

**Rule**: existing flat-shape epics (`15-epic-consult-skill-core.md`, `19-coverage-coverage-matrix-format.md`, etc.) are **not migrated**. They remain exactly as they are on disk. New epics use the two-part format. Over time, as old epics archive out, the directory naturally converges to the new shape.

**Why**: migration would need to assign a parent spec retroactively to each existing epic — and not every old epic has an unambiguous parent spec. No migration also means no git-blame damage, no cross-reference rewriting, and no risk of partial failure. The cost is a transient mixed-shape directory, which is honest (old epics genuinely lacked parent-spec metadata).

**Implementation implications**:
- Glob patterns in `/cpm:epics`, `/cpm:do`, and coverage-matrix handling must read **both** shapes: `[0-9]*-epic-*.md` matches both `15-epic-foo.md` (flat) and `27-01-epic-foo.md` (two-part).
- "Find next number" logic for *new* epics parses only two-part filenames scoped to a given parent. Flat-shape files are invisible to this lookup (no second numeric field to match) and do not affect sub-number assignment.
- Cross-epic dependency references (`**Blocked by**: Epic 15-epic-consult-skill-core` vs `**Blocked by**: Epic 27-01-epic-consult-skill-core`) remain free-form text, so both shapes coexist in prose without code changes.
- A one-line note in the epics skill should document the transition: "Epics created before v1.24 used flat numbering (`{nn}-epic-{slug}.md`); new epics use parent-scoped two-part numbering (`{parent}-{seq}-epic-{slug}.md`)." This prevents a future maintainer from "helpfully" migrating the old files.

## Scope of the resulting work

Ren summarised the final scope:

One spec. One epic. Roughly four tasks:

1. **Update the numbering width rule in all nine skills** (identical text, bulk edit). Skills affected: `/cpm:spec`, `/cpm:epics`, `/cpm:discover` (plans), `/cpm:brief`, `/cpm:review`, `/cpm:retro`, `/cpm:architect`, `/cpm:quick`, `/cpm:party` + `/cpm:consult` (discussions). Elli recommended writing the rule as one canonical sentence and pasting it verbatim into each skill so they can't drift apart.

2. **Add the epic sub-numbering scheme to `/cpm:epics`**: creation logic (`{parent}-{seq}`), glob patterns that read both shapes, coverage-file naming (`{parent}-{seq}-coverage-{slug}.md`), orphan handling (`00-{seq}`), immutable-identifier rule documented.

3. **Update `/cpm:do`** to read both flat-shape and two-part-shape epic filenames and their companion coverage files. Read-side only — no writing, no migration.

4. **Update `/cpm:archive`** to implement "retired numbers stay retired" semantics: new number = `max(active ∪ archived) + 1`. Never reuse a previously-assigned number. This decision is load-bearing for the numbering-width decision.

Jordan's scope sanity check was raised earlier and answered: the pain is real enough (Chris is close to 99 on an existing project, and filename-level traceability is a repeated friction) to justify the full change over a cheap front-matter-only interim fix.

## Constraints / things to preserve

- **Mixed-shape coexistence is a permanent invariant.** Old flat epics will still exist in `docs/epics/` years from now if they haven't been archived. The code must handle both shapes indefinitely, not as a transition phase.
- **Width assumption is forbidden.** Numeric prefixes are integers, not fixed-width strings. Any future skill that parses filenames must use integer comparison.
- **Sub-number gaps are legal.** Never auto-compact sub-numbers to close gaps. Sub-numbers are identifiers, not ordinals.
- **Orphan parent is `00`, not absent.** Every new epic has a two-part filename. No epic is written as `{seq}-epic-{slug}.md` (flat) by the new logic.
- **The archive never resets.** This is the contract that lets "grow past 99" be safe.
