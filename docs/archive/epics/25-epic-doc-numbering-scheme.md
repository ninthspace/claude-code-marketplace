# Document Numbering Scheme

**Source spec**: docs/specifications/28-spec-doc-numbering-scheme.md
**Date**: 2026-04-11
**Status**: Complete
**Blocked by**: —

## Author shared Numbering procedure in CPM conventions doc
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: M1 (shared procedure definition), M2 (archive-aware lookup specification), M7 (invariant statement), AD1 (canonical rule location), AD2 (active ∪ archive glob)
**Retro**: [Smooth delivery] Authoring the shared Numbering procedure slotted cleanly into the existing conventions doc structure; the invariant, rules, and scenario walkthroughs all landed in one draft pass with no rework.

**Acceptance Criteria**:
- The CPM shared skill conventions doc contains a "Numbering" section with the canonical rule `[manual]`
- The shared Numbering procedure specifies globbing both `docs/{type}/` and `docs/archive/{type}/` when computing max `[manual]`
- The shared Numbering procedure contains the invariant statement verbatim: "Numeric prefix is an integer identifier, not a fixed-width string. Never pad existing files to match new widths." `[manual]`
- The procedure specifies integer comparison (not lexical) for the next-number lookup `[manual]`
- The procedure degrades cleanly when `docs/archive/{type}/` does not exist (fresh project) — falls back to active-only lookup `[manual]`

### Draft the Numbering procedure section in cpm/shared/skill-conventions.md
**Task**: 1.1
**Description**: Write the canonical procedure matching the structure of existing Roster Loading and Library Check sections. Cover: minimum 2-digit zero-pad rule with natural-width growth past 99, integer comparison mandate, glob shape for the active directory, glob shape for the archive mirror (`docs/archive/{type}/`), max-union logic, and fallback when archive directory absent. Scopes Story 1 acceptance criteria 1, 2, 4, 5.
**Status**: Complete

### Include the documented invariant statement verbatim
**Task**: 1.2
**Description**: Within the Numbering section, add the exact invariant sentence: "Numeric prefix is an integer identifier, not a fixed-width string. Never pad existing files to match new widths." Position it where a future maintainer scanning the procedure would reasonably see it before modifying numbering logic. Scopes Story 1 acceptance criterion 3 and requirement M7.
**Status**: Complete

### Fixture verification: manual read-through of the new section
**Task**: 1.3
**Description**: Read the complete Numbering section in isolation and confirm it covers all five Story 1 acceptance criteria unambiguously. No code execution — this is a proof-read gate before Story 2 starts referencing the section. If any criterion isn't covered by the prose, revise Task 1.1 or 1.2.
**Status**: Complete

---

## Reference shared Numbering procedure from all creating skills
**Story**: 2
**Status**: Complete
**Blocked by**: Story 1
**Retro**: [Criteria gap] Spec's skill list missed `/cpm:present` (which writes to `docs/communications/`) — discovered during grep for find-highest paragraphs and included in the edit to match the spec's intent. Future batch-SKILL updates should glob for the pattern before writing the skill list to avoid the same miss.
**Satisfies**: M1 (skill-side application of the rule)

**Acceptance Criteria**:
- Each of the nine affected skills replaces its inline "find highest number" paragraph with "Follow the shared Numbering procedure." verbatim `[manual]`
- Skills affected: `/cpm:spec`, `/cpm:epics`, `/cpm:discover`, `/cpm:brief`, `/cpm:review`, `/cpm:retro`, `/cpm:architect`, `/cpm:quick`, and discussion-save logic in `/cpm:party` and `/cpm:consult` `[manual]`
- `/cpm:spec` invoked in a directory containing `99-spec-foo.md` produces `100-spec-bar.md` on the next invocation (fixture scenario) `[manual]`
- `/cpm:spec` with `27-spec-foo.md` in the archive and nothing in the active directory produces `28-spec-bar.md`, not `01-spec-bar.md` (fixture scenario) `[manual]`

### Replace inline "find highest number" paragraph in each of the nine affected skills
**Task**: 2.1
**Description**: For each skill in the list (`/cpm:spec`, `/cpm:epics`, `/cpm:discover`, `/cpm:brief`, `/cpm:review`, `/cpm:retro`, `/cpm:architect`, `/cpm:quick`, plus discussion-save logic in `/cpm:party` and `/cpm:consult`), identify the existing paragraph that describes the glob + find-max + increment logic and replace it with the canonical reference line matching the project's existing pattern: `Follow the shared **Numbering** procedure (from the CPM Shared Skill Conventions loaded at session start).` Preserve any skill-specific context the paragraph sat in. Scopes Story 2 acceptance criteria 1 and 2.
**Status**: Complete

### Fixture scenario: 99 → 100 transition in /cpm:spec
**Task**: 2.2
**Description**: In a fixture directory, create a stub `99-spec-foo.md`, invoke the updated `/cpm:spec` flow, confirm it writes `100-spec-bar.md` rather than erroring or wrapping. Scopes Story 2 acceptance criterion 3 and requirement U3.
**Status**: Complete

### Fixture scenario: archive-aware max lookup in /cpm:spec
**Task**: 2.3
**Description**: In a fixture directory, place `27-spec-foo.md` under `docs/archive/specifications/` with an empty `docs/specifications/`, invoke `/cpm:spec`, confirm the next spec is `28-spec-bar.md` rather than `01-spec-bar.md`. Also verify the fresh-project fallback: with no archive directory at all, confirm lookup still works against the active directory alone. Scopes Story 2 acceptance criterion 4 and requirement R3.
**Status**: Complete

---

## Update /cpm:epics with two-part shape, orphan handling, and dual-shape reading [plan]
**Story**: 3
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: M3 (epic sub-numbering), M4 (orphan `00` prefix), M5 (backwards-compat reading in /cpm:epics), M7 (transition note), S2 (cross-epic dep guidance both shapes), AD3 (scoped sub-number glob)
**Retro**: [Criteria gap] Acceptance criterion 3 (gap preservation) as written in spec 28 described a scenario the algorithm cannot satisfy without a ledger — "deleting 27-02 produces 27-03" conflicts with a pure filesystem max-lookup, which can only preserve gaps that are *internal* to the sequence (i.e. a higher sub-number still exists in the directory). Corrected the criterion to use `[27-01, 27-03] → 27-04` as the example and documented the top-of-sequence limitation: top deletions without archive DO reuse the number. This is a spec-level fidelity slip worth backfilling into spec 28 via `/cpm:pivot` after epic completion.

**Acceptance Criteria**:
- `/cpm:epics` invoked from `docs/specifications/28-spec-foo.md` produces epic files matching `28-01-epic-{slug}.md`, `28-02-epic-{slug}.md`, ... `[manual]`
- Companion coverage files use the same two-part prefix: `28-01-coverage-{slug}.md` `[manual]`
- Creating a new epic under spec 27 when the directory contains `27-01-epic-foo.md` and `27-03-epic-baz.md` (27-02 was previously deleted, or the sequence naturally has a gap) produces `27-04-epic-qux.md` — the gap at 27-02 is preserved because the max-lookup over `[27-01, 27-03]` yields 3, and the missing `27-02` integer is simply skipped. Note that if the deleted sub-number was the *highest* in the sequence (e.g. only `27-01` remains after `27-02` was deleted), the algorithm will produce `27-02` on the next creation — gap preservation only holds for gaps internal to the sequence, not at the top. For true immutability across the top, the retired sub-number must be preserved via archive (the archive-mirror glob will still see it). `[manual]`
- The scoped glob `docs/epics/{parent}-[0-9]*-epic-*.md` ignores flat-shape files when computing the next sub-number `[manual]`
- An epic created without a parent spec is written as `00-{seq}-epic-{slug}.md` `[manual]`
- The "find next sub-number" logic for orphans scopes to `00-[0-9]*-epic-*.md` independent of spec-linked epics `[manual]`
- No new flat-shape epic (e.g. `28-epic-{slug}.md`) is ever written by the updated `/cpm:epics` `[manual]`
- `/cpm:epics` invoked in a directory containing both `15-epic-consult.md` and `27-01-epic-foo.md` reads both without error `[manual]`
- The general epic glob `docs/epics/[0-9]*-epic-*.md` is preserved for operations needing all epics regardless of shape `[manual]`
- No flat-shape epic file is renamed, moved, or modified by the updated `/cpm:epics` `[manual]`
- The `/cpm:epics` skill contains a one-line transition note explaining the coexistence `[manual]`
- Cross-epic dependency reference guidance in the skill template shows both `15-epic-foo` (legacy) and `27-01-epic-foo` (new) as acceptable shapes `[manual]`

### Update Step 2 "Identify Epics" logic to produce two-part filenames from spec input
**Task**: 3.1
**Description**: Replace the current `{nn}-epic-{slug}.md` pattern with `{parent}-{seq}-epic-{slug}.md` where `{parent}` is extracted from the source spec's filename number and `{seq}` comes from the scoped sub-number lookup. Update the "proposed filenames" shown to the user during confirmation. Scopes Story 3 acceptance criteria 1 and the "no new flat-shape epic ever written" criterion.
**Status**: Complete

### Implement scoped sub-number lookup for spec-linked epics
**Task**: 3.2
**Description**: Define the glob pattern `docs/epics/{parent}-[0-9]*-epic-*.md` plus the archive mirror, integer-max the second numeric field, return max+1. Start at `01` when no epics exist under the parent. Document explicitly that flat-shape files are excluded by the glob (no second numeric field to match). Gaps from deleted sub-numbers are preserved, never backfilled. Scopes Story 3 acceptance criteria 3, 4, and AD3.
**Status**: Complete

### Implement orphan epic handling with `00` parent prefix
**Task**: 3.3
**Description**: When `/cpm:epics` is invoked without a parent spec (input is a brief, discussion, description, or bare prompt), assign `00` as the parent prefix and apply the same scoped sub-number lookup against `docs/epics/00-[0-9]*-epic-*.md`. The skill must not fall back to flat-shape `{seq}-epic-{slug}.md` for orphans. Scopes Story 3 acceptance criteria 5, 6, and 7.
**Status**: Complete

### Update coverage-matrix file naming to match two-part prefix
**Task**: 3.4
**Description**: In Step 3d and the Output section, update the coverage-matrix path from `docs/epics/{nn}-coverage-{slug}.md` to `docs/epics/{parent}-{seq}-coverage-{slug}.md`. Ensure the "save epic and coverage together" guidance still holds. Scopes Story 3 acceptance criterion 2.
**Status**: Complete

### Preserve the general epic glob for reader paths
**Task**: 3.5
**Description**: Audit every glob in `/cpm:epics` (and its guidance for cross-epic dependency resolution). Any glob that lists *all* epics for reader purposes (not for sub-number assignment) must retain the shape `docs/epics/[0-9]*-epic-*.md` so both flat and two-part files are returned. Only the sub-number-assignment glob is scoped to the two-part shape. Confirm via a fixture directory containing both `15-epic-consult.md` and `27-01-epic-foo.md` that the general glob returns both. Scopes Story 3 acceptance criteria 8, 9, and 10.
**Status**: Complete

### Add the transition note and cross-epic dependency guidance
**Task**: 3.6
**Description**: Add a one-line note to `/cpm:epics` documenting the shape coexistence: "Epics created before the numbering update used flat `{nn}-epic-{slug}.md`; new epics use parent-scoped `{parent}-{seq}-epic-{slug}.md`. Both shapes coexist; old epics are not migrated." Position it in the section a future maintainer would read before touching numbering logic. Separately, update the cross-epic dependency reference guidance so the `**Blocked by**: Epic {...}` examples show both legacy and new shapes as acceptable. Scopes Story 3 acceptance criteria 11, 12, and requirement M7/S2.
**Status**: Complete

---

## Update /cpm:do with dual-shape epic resolution [plan]
**Story**: 4
**Status**: Complete
**Blocked by**: Story 3
**Satisfies**: M6 (/cpm:do reads both shapes), AD4 (coverage path via substitution)
**Retro**: [Smooth delivery] The `-epic- → -coverage-` substitution rule is the cleanest design decision in the spec. Three text replacements in one file, no branching, no shape detection. Formal plan mode was technically overkill for the scope but worth it to verify the substitution rule covers every touchpoint before editing.

**Acceptance Criteria**:
- `/cpm:do` hydrating a task from `docs/epics/27-01-epic-foo.md` resolves the epic doc and `docs/epics/27-01-coverage-foo.md` correctly `[manual]`
- `/cpm:do` hydrating a task from `docs/epics/15-epic-bar.md` (flat) resolves the epic doc and `docs/epics/15-coverage-bar.md` correctly `[manual]`
- The coverage-path resolution uses the single `-epic-` → `-coverage-` substitution rule (AD4) — one code path for both shapes `[manual]`

### Update epic and coverage path resolution in /cpm:do hydration
**Task**: 4.1
**Description**: Locate every place `/cpm:do` reads an epic document or coverage matrix path. Replace any shape-specific logic with the `-epic-` → `-coverage-` substitution rule (AD4). The resolver must handle both `{nn}-epic-{slug}.md` → `{nn}-coverage-{slug}.md` and `{parent}-{seq}-epic-{slug}.md` → `{parent}-{seq}-coverage-{slug}.md` via the same code path. Scopes Story 4 acceptance criterion 3 and AD4.
**Status**: Complete

### Fixture scenarios: dual-shape hydration
**Task**: 4.2
**Description**: Two fixture scenarios. (a) Create a fixture `docs/epics/27-01-epic-foo.md` with a matching `docs/epics/27-01-coverage-foo.md`, hydrate a task from it via `/cpm:do`, confirm both files are read correctly. (b) Repeat with a fixture `docs/epics/15-epic-bar.md` and `docs/epics/15-coverage-bar.md` (legacy shape). Both must work with no branching on shape. Scopes Story 4 acceptance criteria 1 and 2.
**Status**: Complete

---

## Verification pass on /cpm:archive for filename-width assumptions
**Story**: 5
**Status**: Complete
**Blocked by**: —
**Satisfies**: (supports M2 — ensures archive contract is preserved; supports M5 — ensures archive reader is shape-agnostic)
**Retro**: [Codebase discovery] The audit caught a real latent bug — the extract-slug instruction at line 33 of `/cpm:archive` described a filename pattern with a single numeric segment, which would misparse new two-part epic filenames and silently break chain-matching. Fixed by making slug extraction anchor on the type identifier substring. This is exactly the bug Story 5 was designed to catch, and justifies keeping "verification pass" stories in the plan even when they look like busywork. Also noted an out-of-scope observation: /cpm:archive scans only plans/specs/epics/retros, missing briefs/reviews/architecture/quick/discussions — pre-existing limitation worth a future spec if archive coverage matters.

**Acceptance Criteria**:
- `/cpm:archive` chain-matching logic (slug-based grouping) has been reviewed and confirmed to contain no hidden assumptions about filename width or shape `[manual]`
- `/cpm:archive` preserves its mirrored directory structure (`docs/archive/{type}/`) as the archive target — this is load-bearing for the `max(active ∪ archived) + 1` contract and must not change as a side-effect `[manual]`
- If the review uncovers an assumption, it is documented and fixed; if no issues are found, that's the acceptable outcome and the story is complete `[manual]`

### Audit /cpm:archive for filename-width assumptions and confirm mirrored structure is preserved
**Task**: 5.1
**Description**: Read `/cpm:archive` end-to-end. Confirm: (a) chain-matching is slug-based (already verified in discussion — revalidate it); (b) no step parses or compares numeric prefixes as fixed-width strings; (c) the archive target remains `docs/archive/{type}/` with mirrored structure, which the Numbering procedure's archive-aware lookup depends on. If any width assumption is found, document the location and propose a fix; otherwise record "no issues found — archive is shape-agnostic" as the audit outcome. Scopes all three Story 5 acceptance criteria.
**Status**: Complete

---

## Lessons

### Smooth Deliveries
- **Story 1** (shared Numbering procedure): Authoring the shared procedure slotted cleanly into the existing conventions doc structure; the invariant, rules, and scenario walkthroughs all landed in one draft pass with no rework.
- **Story 4** (`/cpm:do` dual-shape resolution): The `-epic- → -coverage-` substitution rule is the cleanest design decision in the spec. Three text replacements in one file, no branching, no shape detection. Formal plan mode was technically overkill for the scope but worth it to verify the substitution rule covered every touchpoint before editing.

### Criteria Gaps
- **Story 2**: Spec's skill list missed `/cpm:present` (which writes to `docs/communications/` using the same find-highest pattern) — discovered during grep and included in the edit to match the spec's intent. Future batch-SKILL updates should glob for the target pattern before committing a scope list.
- **Story 3**: Acceptance criterion 3 (gap preservation) described a scenario the filesystem-only max-lookup algorithm cannot satisfy — "deleting 27-02 produces 27-03" conflicts with a pure max-lookup, which can only preserve gaps that are *internal* to the sequence. Corrected the criterion in the epic doc and coverage matrix to use `[27-01, 27-03] → 27-04` as the example, and documented the top-of-sequence limitation. Spec 28 has the same wording and should be backfilled via `/cpm:pivot`.

### Codebase Discoveries
- **Story 5** (archive audit): The audit caught a real latent bug — the extract-slug instruction at line 33 of `/cpm:archive` described a filename pattern with a single numeric segment, which would misparse new two-part epic filenames and silently break chain-matching. Fixed by making slug extraction anchor on the type identifier substring. This justifies keeping "verification pass" stories in the plan even when they look like busywork. Also noted an out-of-scope observation: `/cpm:archive` scans only plans/specs/epics/retros, missing briefs/reviews/architecture/quick/discussions — pre-existing limitation worth a future spec.
