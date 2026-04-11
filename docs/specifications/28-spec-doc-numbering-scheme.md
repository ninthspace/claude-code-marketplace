# Spec: Document Numbering Scheme

**Date**: 2026-04-11
**Brief**: docs/discussions/14-discussion-doc-numbering-scheme.md

## Problem Summary

CPM's document numbering has two friction points surfacing from real use. First, every per-directory artifact type (specs, epics, plans, briefs, discussions, reviews, retros, ADRs, quick records) uses a 2-digit zero-padded auto-incrementing number — the project is close to hitting `99` in existing directories, and the skills have no story for what happens next. Second, epic filenames carry no structural link to the spec that spawned them, forcing readers to open files or grep content to discover the parent spec. The spec lands four rules: (1) numbers grow naturally past 99 using integer comparison with no renaming; (2) archive permanently retires numbers — new = `max(active ∪ archived) + 1`; (3) new epics use parent-scoped two-part filenames (`{parent}-{seq}-epic-{slug}.md`, `00` for orphans); (4) old flat-shape epics coexist permanently with the new shape, with no migration.

## Functional Requirements

### Must Have

- **M1. Uniform numbering-width rule across all numbered artifact skills.** Every skill that creates a numbered document applies the same rule via a shared "Numbering" procedure: zero-pad to minimum 2 digits, grow naturally past 99 using natural width, integer comparison for the next-number lookup. Applies to `/cpm:spec`, `/cpm:epics`, `/cpm:discover`, `/cpm:brief`, `/cpm:review`, `/cpm:retro`, `/cpm:architect`, `/cpm:quick`, and discussion-save logic in `/cpm:party` and `/cpm:consult`. Each skill references the shared procedure rather than restating the rule inline.
- **M2. Archive retires numbers permanently.** Creating skills look at both `docs/{type}/` and `docs/archive/{type}/` when computing the next number. New number = `max(active ∪ archived) + 1`. Retired numbers are never reused.
- **M3. Epic sub-numbering: two-part parent-scoped format.** `/cpm:epics` creates new epics with the pattern `{parent}-{seq}-epic-{slug}.md`, where `{parent}` is the spec number the epic derives from and `{seq}` is a sub-sequence number starting at `01` within that parent. Coverage-matrix companion files inherit the same prefix: `{parent}-{seq}-coverage-{slug}.md`. Sub-numbers are immutable identifiers — gaps from deletions are preserved, never backfilled.
- **M4. Orphan epic handling: `00` parent prefix.** Epics with no parent spec (from `/cpm:quick`, discussion-driven work, or standalone invocation) use `00` as the parent prefix: `00-{seq}-epic-{slug}.md`. All new epics produced by `/cpm:epics` use the two-part format — no new flat-shape epics are written.
- **M5. Backwards-compatible reading of old flat-shape epics.** `/cpm:epics`, `/cpm:do`, and any skill that reads the epics directory handles both shapes transparently. Existing flat-shape epics are not migrated, renamed, or touched. The "find next sub-number" logic scopes to two-part filenames only; flat-shape files are naturally excluded.
- **M6. `/cpm:do` reads two-part epic filenames and companion coverage files.** `/cpm:do` resolves both flat and two-part epic paths when hydrating a task, and resolves the matching coverage matrix file via the `-epic-` → `-coverage-` substitution rule, which works for both shapes.
- **M7. Documented invariants and transition note.** The shared Numbering procedure explicitly states the invariant: *"Numeric prefix is an integer identifier, not a fixed-width string. Never pad existing files to match new widths."* The `/cpm:epics` skill contains a one-line transition note explaining the coexistence: *"Epics created before the numbering update used flat `{nn}-epic-{slug}.md`; new epics use parent-scoped `{parent}-{seq}-epic-{slug}.md`. Both shapes coexist; old epics are not migrated."*

### Should Have

- **S1. Canonical numbering rule stored in the CPM shared skill conventions doc.** Prevents drift across the ~9 affected skills over time. Skills reference the procedure by name ("Follow the shared Numbering procedure") rather than duplicating the rule text.
- **S2. Cross-epic dependency reference guidance shows both shapes.** `/cpm:epics` template guidance on `**Blocked by**: Epic {...}` lines demonstrates both `15-epic-foo` (legacy) and `27-01-epic-foo` (new) shapes as acceptable, so authors don't assume one shape is required.

### Could Have

- **C1. Status/epic list tooling surfaces parent linkage.** `/cpm:status` groups epics by parent spec in its output, using the new filename structure. Nice-to-have, not required for the change to land.

### Won't Have (this iteration)

- **W1. Migration of old flat-shape epics.** No retroactive parent-spec assignment, no rename, no content rewrite.
- **W2. Auto-widening renumbering at 99→100.** Explicitly rejected; numbers grow naturally to their natural width.
- **W3. Sub-numbering applied to other artifact types.** Briefs, plans, reviews, retros, ADRs, quick records, and discussions keep flat numbering. Only epics gain the two-part shape.
- **W4. Archive number-reset mode.** Archive always retires; never reuses.

## Non-Functional Requirements

### Reliability

- **R1. No partial-state corruption of existing directories.** The change is strictly additive — new shape written, old shape untouched. There is no bulk rename, no content rewrite, no migration operation that could fail mid-way and leave inconsistent state.
- **R2. Idempotent "find next number" logic.** Running the numbering lookup twice returns the same result. The logic does not depend on filesystem ordering or locale-specific sort behaviour — only on integer comparison of parsed numeric prefixes.
- **R3. Archive-aware lookup fails closed.** If `docs/archive/{type}/` is unreachable or malformed, the creating skill refuses to assign a new number rather than silently reusing a retired one. A missing archive directory (fresh project) degrades cleanly to active-only lookup, which is the correct behaviour.

### Usability

- **U1. Filename traceability is immediately visible.** A reader scanning `ls docs/epics/` can identify an epic's parent spec without opening the file. This is the core user-facing benefit driving the sub-numbering decision.
- **U2. Mixed-shape directories remain legible.** During the transition period where `docs/epics/` contains both flat-shape and two-part epics, a one-line explanatory note in the epics skill documents the coexistence so readers are not left wondering why the directory looks inconsistent.
- **U3. No surprise for existing projects past 99.** A project crossing `99 → 100` experiences no disruption: no prompt, no migration step, no manual intervention. The creating skill writes the `100` file next to the `99` file and continues.

## Architecture Decisions

### AD1 — Canonical numbering rule lives in the CPM shared skill conventions doc

**Choice**: The canonical "Numbering" procedure is written once in the CPM shared skill conventions doc (the same file loaded at session start alongside "Roster Loading" and "Library Check"). Each affected skill contains a single reference line: *"Follow the shared Numbering procedure."*

**Rationale**: Matches the existing precedent for shared procedures (Roster Loading, Library Check). Structurally prevents drift across the ~9 skills — the rule exists exactly once. The retro recommendation ("batch SKILL.md updates benefit from consistent structure") is satisfied by referencing a single canonical source rather than pasting verbatim.

**Alternatives considered**: (A) Pasting the full rule verbatim into each of the ~9 skills — makes each skill self-contained but introduces real drift risk over time. (C) Hybrid of canonical rule plus a one-line reference in each skill — structurally identical to the chosen approach but with more local signposting than necessary.

### AD2 — "Find next number" scopes both active and archive directories

**Choice**: The shared Numbering procedure specifies that the max-lookup globs both `docs/{type}/[0-9]*-{type}-*.md` and `docs/archive/{type}/[0-9]*-{type}-*.md`, integer-compares the parsed numeric prefixes, and returns `max + 1`. If `docs/archive/{type}/` does not exist, the lookup falls back to the active directory only. Integer comparison is mandatory — lexical comparison breaks mixed-width coexistence.

**Rationale**: `/cpm:archive` already mirrors directory structure into `docs/archive/{subdirectory}/`, so the archive path is predictable and globable. No new tooling, no metadata file tracking retired numbers. The "retires permanently" invariant (requirement M2) follows directly from scoping the glob to both directories.

**Alternatives considered**: A dedicated "retired-numbers ledger" file listing used numbers explicitly. Rejected — the ledger is a new source of truth that can diverge from the filesystem, and globbing is trivial at CPM's scale.

### AD3 — Sub-number lookup uses a scoped parent glob

**Choice**: When `/cpm:epics` creates a new epic under spec `{parent}`, it globs `docs/epics/{parent}-[0-9]*-epic-*.md` plus the archive mirror, extracts the second numeric field, integer-maxes, and returns `max + 1`. Orphans use `00-[0-9]*-epic-*.md` following the same pattern. If no epics exist under the parent, the sequence starts at `01`.

**Rationale**: Scoped glob naturally excludes flat-shape files (they have no second numeric field to parse), so the backwards-compat concern handles itself. Gaps from deleted sub-numbers are preserved because the max-lookup simply skips missing integers — no backfill required. The immutable-identifier rule (requirement M3) is implicit in this approach.

**Alternatives considered**: Scanning all epic files and parsing every filename to build an index. Rejected as unnecessary overhead.

### AD4 — Coverage file resolution via string substitution

**Choice**: `/cpm:do` and any other reader resolves the coverage-matrix path from an epic path by replacing `-epic-` with `-coverage-` in the filename. This single substitution works for both flat (`15-epic-foo.md` → `15-coverage-foo.md`) and two-part (`27-01-epic-foo.md` → `27-01-coverage-foo.md`) shapes without shape detection.

**Rationale**: A single shape-agnostic code path eliminates branching between legacy and new formats in `/cpm:do`. The rule is easy to state, easy to verify, and has no corner cases — any valid epic filename produces a valid coverage filename.

**Alternatives considered**: Detecting the shape first (counting numeric segments) and branching to two resolver functions. Rejected — the substitution rule makes the detection unnecessary and the branching is accidental complexity.

## Scope

### In Scope

- Add a canonical "Numbering" procedure to the CPM shared skill conventions doc covering: minimum 2-digit pad, natural-width growth past 99, integer comparison, `max(active ∪ archived) + 1` with both directories globed.
- Replace the inline "find highest number" paragraphs in the ~9 affected skills with a one-line reference: *"Follow the shared Numbering procedure."* Skills affected: `/cpm:spec`, `/cpm:epics`, `/cpm:discover`, `/cpm:brief`, `/cpm:review`, `/cpm:retro`, `/cpm:architect`, `/cpm:quick`, plus discussion-save logic in `/cpm:party` and `/cpm:consult`.
- Update `/cpm:epics` with the new two-part filename shape `{parent}-{seq}-epic-{slug}.md`, orphan `00` handling, immutable sub-numbers via scoped glob, and companion coverage file `{parent}-{seq}-coverage-{slug}.md`.
- Update `/cpm:do` to resolve both flat and two-part epic paths and their matching coverage files via the `-epic-` → `-coverage-` substitution rule.
- Update `/cpm:epics` (reader side) to handle both filename shapes in general epic listings and dependency resolution, while scoping the sub-number lookup to two-part filenames only.
- Review `/cpm:archive` for any hidden assumptions about filename width; its chain-matching logic groups by slug, which is already shape-agnostic, but one pass to confirm is in scope.
- Add a one-line transition note to `/cpm:epics` documenting the coexistence of flat and two-part shapes.
- Add the documented invariant to the shared Numbering procedure: *"Numeric prefix is an integer identifier, not a fixed-width string. Never pad existing files to match new widths."*
- Fixture-based verification scenarios executed alongside each skill edit, per the retro recommendation for incremental verification.

### Out of Scope

- Migration of existing flat-shape epics. No retroactive parent-spec assignment, no rename, no content rewrite, no git-history manipulation.
- Auto-widening renumbering at the `99 → 100` transition. The `/cpm:widen` skill idea is rejected in favour of natural-width growth.
- Sub-numbering for artifact types other than epics. Briefs, plans, reviews, retros, ADRs, quick records, and discussions keep flat numbering.
- Archive number-reset mode. Archive always retires; never reuses.
- A retired-numbers ledger file or any other new tracking infrastructure.
- Changes to the free-form prose syntax for cross-epic dependency references (`**Blocked by**: Epic {filename}`).

### Deferred

- **C1**: `/cpm:status` grouping epics by parent spec. Possible once the new shape exists; revisit once enough new-shape epics exist in the wild to make grouping visibly useful.
- Sub-numbering for other artifact pairs (e.g. briefs linking to discussions, ADRs linking to specs). If pain surfaces, a future spec can extend the two-part pattern.
- Retirement-number persistence (a ledger file) for catastrophically large archives where globbing becomes slow. Not relevant at current scale.

## Testing Strategy

### Tag Vocabulary

Test approach tags used in this spec:

- `[unit]` — Unit tests targeting individual components in isolation
- `[integration]` — Integration tests exercising boundaries between components
- `[feature]` — Feature/end-to-end tests exercising complete user-facing workflows
- `[manual]` — Manual inspection, observation, or user confirmation
- `[tdd]` — Workflow mode: task follows red-green-refactor loop. Composable with any level tag (e.g. `[tdd] [unit]`). Orthogonal — describes how to work, not what kind of test.

**Caveat for this spec**: the work is edits to SKILL.md prose interpreted by Claude at runtime, not executable code. Most criteria naturally carry `[manual]` — fixture-based verification, where a known directory state is created and the skill is invoked to confirm the expected filename is produced. This is an accurate reflection of where the logic lives, not a testing-quality shortcut.

### Acceptance Criteria Coverage

| Requirement | Acceptance Criterion | Test Approach |
|---|---|---|
| M1 | The CPM shared skill conventions doc contains a "Numbering" section with the canonical rule | [manual] |
| M1 | Each of the ~9 affected skills replaces its inline "find highest number" paragraph with "Follow the shared Numbering procedure." verbatim | [manual] |
| M1 | `/cpm:spec` invoked in a directory containing `99-spec-foo.md` produces `100-spec-bar.md` on the next invocation | [manual] |
| M2 | The shared Numbering procedure specifies globbing both `docs/{type}/` and `docs/archive/{type}/` when computing max | [manual] |
| M2 | `/cpm:spec` with `27-spec-foo.md` in the archive and nothing in the active directory produces `28-spec-bar.md`, not `01-spec-bar.md` | [manual] |
| M2 | If `docs/archive/{type}/` does not exist, the lookup degrades cleanly and uses the active directory only | [manual] |
| M3 | `/cpm:epics` invoked from `docs/specifications/28-spec-foo.md` produces epic files matching `28-01-epic-{slug}.md`, `28-02-epic-{slug}.md`, ... | [manual] |
| M3 | Companion coverage files use the same two-part prefix: `28-01-coverage-{slug}.md` | [manual] |
| M3 | Creating a new epic under spec 27 when `27-02-epic-foo.md` has been deleted produces `27-03-epic-baz.md` (gap preserved, not backfilled) | [manual] |
| M3 | The scoped glob `docs/epics/{parent}-[0-9]*-epic-*.md` ignores flat-shape files when computing the next sub-number | [manual] |
| M4 | An epic created without a parent spec is written as `00-{seq}-epic-{slug}.md` | [manual] |
| M4 | The "find next sub-number" logic for orphans scopes to `00-[0-9]*-epic-*.md` independent of spec-linked epics | [manual] |
| M4 | No new flat-shape epic (e.g. `28-epic-{slug}.md`) is ever written by the updated `/cpm:epics` | [manual] |
| M5 | `/cpm:epics` invoked in a directory containing both `15-epic-consult.md` and `27-01-epic-foo.md` reads both without error | [manual] |
| M5 | The general epic glob `docs/epics/[0-9]*-epic-*.md` is preserved for operations needing all epics regardless of shape | [manual] |
| M5 | No flat-shape epic file is renamed, moved, or modified by any updated skill | [manual] |
| M6 | `/cpm:do` hydrating a task from `docs/epics/27-01-epic-foo.md` resolves the epic doc and `docs/epics/27-01-coverage-foo.md` correctly | [manual] |
| M6 | `/cpm:do` hydrating a task from `docs/epics/15-epic-bar.md` (flat) resolves the epic doc and `docs/epics/15-coverage-bar.md` correctly | [manual] |
| M6 | The coverage-path resolution uses the single `-epic-` → `-coverage-` substitution rule (AD4) | [manual] |
| M7 | The shared Numbering procedure contains the invariant statement verbatim | [manual] |
| M7 | The `/cpm:epics` skill contains a one-line transition note explaining the coexistence | [manual] |
| M7 | The invariant and transition note are positioned in sections a future maintainer would reasonably read before modifying numbering logic | [manual] |

### Integration Boundaries

The integration surface for this spec is contractual consistency between skills, not runtime API contracts:

1. **Shared Numbering procedure ↔ creating skills.** The ~9 skills depend on the shared procedure correctly describing the lookup behaviour. The "canonical procedure, skills reference by name" contract (AD1) is the integration guarantee — interpretation drift is prevented structurally.
2. **Creating skills ↔ `/cpm:archive`.** Creating skills rely on `/cpm:archive` preserving the mirrored directory layout (`docs/archive/{type}/`). Archive's current layout is load-bearing and must not change as a side-effect.
3. **`/cpm:epics` ↔ `/cpm:do`.** Both skills must agree on filename shape rules. If `/cpm:epics` writes two-part names but `/cpm:do` only reads flat, task execution breaks. Dual-shape reading in `/cpm:do` (requirement M6) is the integration contract.
4. **`/cpm:epics` (reader) ↔ `/cpm:epics` (writer).** Within one skill, the "find next sub-number" glob and the "write new epic" path must use the same pattern. AD3's scoped glob is the single source of truth.

### Test Infrastructure

**None required.** The retro's observation that hook test infrastructure is mature and extensible does not apply — this spec does not touch hooks. There is no runtime executable code to test; all verification is fixture-based manual scenarios executed during implementation. Existing fixture patterns under `cpm/hooks/tests/` are available if bash-level regression tests are later desired, but they are not mandatory for this spec to land.

### Unit Testing

Unit testing of individual components is handled at the `cpm:do` task level — each story's acceptance criteria drive test coverage during implementation. In this spec, the "test coverage" for a given task is the fixture scenario referenced by its acceptance criterion.
