# Classifier & Hook Refactor

**Source spec**: docs/specifications/38-spec-stale-progress-prompt-and-cpm-clean.md
**Date**: 2026-07-08
**Status**: Pending
**Blocked by**: —
**Retro applied**: 01 · Patterns worth reusing · Applied — write each suite's tests alongside implementation (tasks x.1/x.2) so the x.3 test tasks become lightweight verification.
**Retro applied**: 03 · Codebase discoveries · Applied — grep for every progress-file classification site before/while refactoring so all consume the new helper with no inline duplicate classification remaining.

## Build the shared classifier helper
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: FR1, FR7, FR9, FR6
**Retro**: [Pattern worth reusing] Story 1 delivered as scoped — the classifier's single tab-delimited record contract (CLASSIFICATION\tPATH\tSKILL\tPHASE\tAGE\tAGE_LABEL) gives every downstream consumer one parseable shape, and writing tests alongside implementation (retro 01 applied) meant the suite was green before the dedicated test task, which collapsed to a pure gap-check.

**Acceptance Criteria**:

- Current-session file classified `CURRENT` [unit]
- Other-session file <3 days classified `FRESH`; ≥3 days classified `STALE` [unit]
- must NOT classify the current-session file as STALE/FRESH at any age [unit]
- Boundary: 3d0h → `STALE`, 2d23h → `FRESH` [unit]
- Emits labelled records carrying path, skill, phase, and age for each file [unit]
- The 3-day threshold is defined as a single named constant (replacing `STALE_HOURS=24`) [unit]
- Malformed/unreadable file is skipped; helper still exits cleanly [unit]
- Cross-platform `stat` (`stat -f %m` / `stat -c %Y`) [unit]
- must NOT execute any deletion (the helper never runs `rm`) [unit]

### Create `progress-classify.sh` with classification logic
**Task**: 1.1
**Description**: Create `cpm/hooks/lib/progress-classify.sh`. Emits labelled records (path, skill, phase, age) classifying each `.cpm-progress-*.md` as CURRENT/FRESH/STALE against `CPM_SESSION_ID`; defines the 3-day threshold constant. Covers the classification, threshold, and labelled-output criteria.
**Status**: Complete

### Add robustness & cross-platform handling
**Task**: 1.2
**Description**: Dual `stat` (macOS/Linux), graceful skip of malformed/unreadable files, no `rm` anywhere in the helper. Covers the robustness and never-delete criteria.
**Status**: Complete

### Write tests for the classifier helper
**Task**: 1.3
**Description**: New `test-progress-classify.sh` suite covering CURRENT/FRESH/STALE, the 3d0h/2d23h boundary, current-never-stale, and malformed-skip. Covers the story's automated criteria [unit].
**Status**: Complete

---

## Refactor `session-start.sh` to consume the classifier
**Story**: 2
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: FR2, FR4, FR9
**Retro**: [Pattern worth reusing] To prove a refactor genuinely rerouted logic through the new helper (not just left equivalent inline code), the integration test picks an input where old and new behaviour diverge — a 2-day-old file, which the retired 24h rule called STALE but the helper's 3-day rule calls FRESH; seeing it presented as informational is positive proof the helper drives the hook.

**Acceptance Criteria**:

- `session-start.sh` orphan output is derived from the helper — no inline duplicate classification remains [integration]
- Hook output contains no `BLOCKING`/halt language [unit]
- must NOT emit `BLOCKING` language or instruct the session to stop before proceeding [unit]
- Stale other-session files are labelled as cleanup candidates; fresh other-session files are labelled informational [unit]
- Fresh/stale distinction is presented to the user appropriately (stale→offer, fresh→informational) [manual] — justification: the user-facing presentation is LLM-interpreted prose, no markup oracle
- Current-session file is still injected as active state [unit]

### Replace inline classification with a helper call
**Task**: 2.1
**Description**: Source/call `progress-classify.sh` from `session-start.sh`; remove the inline age/session loop. Covers the "derived from helper, no duplicate" criterion.
**Status**: Complete

### Rework output: remove BLOCKING, emit three-way labels
**Task**: 2.2
**Description**: Drop the BLOCKING orphan block; emit stale=cleanup-candidate, fresh=informational, current=active-state labelled output. Covers the no-BLOCKING and stale/fresh/current criteria.
**Status**: Complete

### Write tests for the `session-start.sh` refactor
**Task**: 2.3
**Description**: Extend `test-startup-hook.sh`/`test-orphan-detection.sh`: output derives from helper, no BLOCKING language, current injected as active. Covers the story's automated criteria [unit]/[integration].
**Status**: Complete

---

## Refactor `session-start-compact.sh` (unify `/clear`, kill silent resurrection)
**Story**: 3
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: FR2, AD5
**Retro**: [Codebase discovery] The compact hook's "graceful" cat-all fallback (inject every progress file when no session matched) was itself the silent-resurrection bug, not a safety net. Replacing it with classifier-CURRENT-only fixes /clear and preserves compaction in one move, because compaction keeps the same session id (so the matching file is still CURRENT) while /clear gets a fresh id (so nothing old is CURRENT). A fallback that fires on "no match" deserves scrutiny — "no match" was exactly the case that needed to inject nothing.

**Acceptance Criteria**:

- On `clear`, other-session/stale files are NOT injected as active state [unit]
- must NOT blanket-`cat` all progress files as active state on `clear` [unit]
- On `compact` (same session), the matching progress file is still injected as active state [unit]
- Compact-summary companion injection for the current session is preserved [unit]

### Route `clear` through the classifier
**Task**: 3.1
**Description**: On `clear`, use the helper; remove the blanket cat-all fallback so other-session/stale files are not injected as active state. Covers the clear-fix and must-NOT criteria.
**Status**: Complete

### Preserve `compact` same-session behaviour
**Task**: 3.2
**Description**: Ensure `compact` (same session) still injects the matching progress file and its compact-summary companion as active state. Covers the compact-preserved criteria.
**Status**: Complete

### Write tests for the compact/clear refactor
**Task**: 3.3
**Description**: Extend `test-compact-hook.sh`: clear no-resurrection, must-NOT cat-all, compact same-session injection preserved. Covers the story's automated criteria [unit].
**Status**: Complete

---

## Verify cross-story integration for Classifier & Hook Refactor
**Story**: 4
**Status**: Complete
**Blocked by**: Story 1, Story 2, Story 3
**Retro**: [Pattern worth reusing] Classify the shared fixture once with the helper to establish ground truth, then assert each hook's active-state decision against that truth — a clean way to prove multiple consumers honour one contract without duplicating the classification logic in the test. Body markers (BODY-*-MARKER) distinguish true active-state injection (file body cat'd) from mere metadata mention in an informational block.

**Acceptance Criteria**:

- Both hooks, run against a shared populated `docs/plans/` fixture (current + fresh-other + stale-other files), produce behaviour consistent with the helper's classification [integration]
- The helper→hook output contract is exercised end-to-end for both `startup` and `clear` sources [integration]

### Write cross-hook integration tests
**Task**: 4.1
**Description**: Shared populated `docs/plans/` fixture (current + fresh-other + stale-other); assert both hooks' behaviour matches the helper's classification across `startup` and `clear` sources. Covers the integration criteria [integration].
**Status**: Complete

---
