# Safety-Net & Skill Rollout

**Source spec**: docs/specifications/38-spec-stale-progress-prompt-and-cpm-clean.md
**Date**: 2026-07-08
**Status**: Complete
**Blocked by**: Epic 38-01-epic-classifier-and-hooks
**Retro applied**: 03 · Codebase discoveries · Applied — for Story 4, grep the ralph plugin for every autonomous-override site (override table + operative generated prompt) and register the new gate in each, not just the doc table.
**Retro applied**: 01 · Patterns worth reusing · Applied — for Story 3, place the reference line in the same startup-checks region across all ~20 skills (mirroring Roster Loading) for uniform, auditable placement.
**Retro applied**: 04 · Testing gaps · Applied — use the targeted guard suite as Story 1's [unit] evidence; treat the 2 pre-existing test-audit-skill.sh failures as known/unrelated so a green epic isn't misread.
**Retro applied**: 04 · Patterns worth reusing · Applied — build cleancheck-guard.sh as a small self-contained testable helper beside the classifier, tests written alongside so Task 1.2 becomes a gap-check.

## Build the session-check guard (sentinel + ralph carve-out)
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: FR3, FR11, AD2, AD3
**Retro**: [Pattern worth reusing] The guard reuses the classifier's small-testable-bash-lib shape (retro 04) and lands cleanly, but a subtle bash gotcha surfaced: `: > "$file" 2>/dev/null` still leaks the *open* error because the `>` redirection is set up before `2>` takes effect — group it as `{ : > "$file"; } 2>/dev/null || true` to keep a fail-safe write genuinely silent. Worth applying anywhere a hook/helper does a best-effort write it must not narrate on failure.

**Acceptance Criteria**:

- Guard reports `RUN` when no sentinel exists and no active ralph loop is present, and writes the sentinel [unit]
- Guard reports `SKIP` when the current session's sentinel already exists [unit]
- must NOT report `RUN` when the current session's sentinel exists [unit]
- Guard reports `SUPPRESS` when `.claude/ralph-loop.local.md` is present, regardless of sentinel state [unit]
- Sentinel path is `docs/plans/.cpm-cleancheck-{session_id}`, outside the `.cpm-progress-*.md` glob [unit]
- Sentinel write failure fails safe — reports `RUN`, never triggers deletion [unit]

### Create the guard script
**Task**: 1.1
**Description**: Create `cpm/hooks/lib/cleancheck-guard.sh` beside the classifier. Emits `RUN`/`SKIP`/`SUPPRESS` for a given `CPM_SESSION_ID`: check the ralph state file (→`SUPPRESS`), then the sentinel (→`SKIP`), else write the sentinel and →`RUN`. Covers the RUN/SKIP/SUPPRESS, sentinel-path, and fail-safe criteria.
**Status**: Complete

### Write tests for the guard
**Task**: 1.2
**Description**: RUN/SKIP/SUPPRESS branches, sentinel outside the progress glob, write-failure fail-safe. Covers the story's automated criteria [unit].
**Status**: Complete

---

## Author the Stale-Progress Check convention procedure
**Story**: 2
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: FR3, FR4, FR6
**Retro**: [Testing gap] The convention composes two thin helpers cleanly (guard decides *whether*, classifier decides *how*), but its runtime correctness rests on `${CLAUDE_PLUGIN_ROOT}` being present in the skill's Bash environment — a hooks.json substitution token whose availability to skill-invoked Bash is unverified by the [manual] prose review. It can only be confirmed by republishing the plugin and dogfooding a real `/cpm:*` startup; flag for the post-install validation (retro 04's republish note).

**Acceptance Criteria**:

- New "Stale-Progress Check" section in `skill-conventions.md`: consult the guard; on `RUN` call the classifier and present results; on `SKIP`/`SUPPRESS` do nothing [manual] — justification: convention prose, verified by review
- Presents stale→offer deletion, fresh→informational, current→active state; never deletes without explicit confirmation [manual]
- must NOT offer fresh (parallel-session) files for deletion [manual]
- must NOT delete any file without explicit user confirmation [manual]

### Add the "Stale-Progress Check" section to `skill-conventions.md`
**Task**: 2.1
**Description**: Author the procedure — consult the guard; on `RUN` call the classifier and present three-way non-blocking (stale→offer, fresh→informational, current→active), never deleting without explicit confirmation; on `SKIP`/`SUPPRESS` do nothing. Covers all Story 2 criteria.
**Status**: Complete

---

## Roll out the check reference to all `/cpm:*` skills
**Story**: 3
**Status**: Complete
**Blocked by**: Story 2
**Satisfies**: FR3
**Retro**: [Pattern worth reusing] Placement stayed uniform despite heterogeneous skill structures by anchoring on *role* not line-position — the reference became the **first startup step** in each skill, at the heading level that skill already uses for startup checks (`### X (Startup)` where those exist, `## X` for the top-level-section skills). All 19 `/cpm:*` skills got exactly one single-line reference (verified by per-file count), so no inline duplication and nothing leaked to non-CPM plugins. Reusable rule for future cross-skill rollouts: pick the semantic anchor (first-startup-step) and match local heading conventions, rather than a fixed structural position that no two skills share.

**Acceptance Criteria**:

- Every `/cpm:*` skill's startup includes a "Follow the shared Stale-Progress Check procedure" reference [manual]
- The reference is placed consistently in each skill's startup-checks region (as Roster Loading is) [manual]
- must NOT duplicate the procedure text inline or add it to non-CPM skills [manual]

### Insert the reference line into each `/cpm:*` skill startup
**Task**: 3.1
**Description**: Add "Follow the shared Stale-Progress Check procedure" to each `/cpm:*` skill's startup-checks region, placed consistently (like Roster Loading), with no inline duplication. ~20 skills. Covers all Story 3 criteria.
**Status**: Complete

---

## Register the gate in the ralph override table
**Story**: 4
**Status**: Complete
**Blocked by**: Story 2
**Satisfies**: FR11
**Retro**: [Codebase discovery] Applying retro 03 (grep every override site) surfaced a genuine distinction, not just extra sites: the existing override table documents *prompt-instruction* overrides for `AskUserQuestion` gates, but the Stale-Progress Check is suppressed *structurally* by the guard's `.claude/ralph-loop.local.md` detection — so the operative generated prompt needed **no** change (a clause there would be redundant/misleading), and only the doc table needed the row plus a note explaining guard-level suppression as a valid override mechanism. Lesson: "register in every override site" must mean "reason about each site's mechanism", not "edit each site identically" — the right edit at one site can be *no edit* once you confirm the mechanism differs.

**Acceptance Criteria**:

- The ralph prompt template's *Autonomous Behaviour* override table lists the new Stale-Progress Check gate with "fully suppressed, no prompt, no action" behaviour [manual]
- Satisfies the template's own "register new gates when added" instruction [manual]

### Add the override-table row
**Task**: 4.1
**Description**: In the ralph prompt template's *Autonomous Behaviour* section, register the Stale-Progress Check gate as "fully suppressed, no prompt, no action." Covers Story 4 criteria.
**Status**: Complete

---
