# Discussion: Stale progress-file prompt no longer surfacing — root cause and `/cpm:clean` design

**Date**: 2026-07-07
**Agents**: Bella (Senior Developer), Margot (Software Architect)

## Investigation trail (theories raised and resolved)

- Orphan/stale progress-file prompting is driven entirely by `cpm/hooks/session-start.sh`, wired (hooks.json) to SessionStart matchers `startup` and `resume` only.
- The `clear` and `compact` matchers route to `session-start-compact.sh`, which injects state silently and has NO orphan detection.
- An "orphan" = a `docs/plans/.cpm-progress-{id}.md` file whose `{id}` != current session id. Detection is conditional on such leftover files existing.
- Commit 8ef3515 (2026-02-11) added the `clear` matcher → `/clear` now silently re-injects state instead of ever surfacing orphan cleanup. Raised as a candidate regression.
- `CLAUDE_PROJECT_DIR`-unset theory: **DISPROVEN**. Reproduction showed the hook logic is correct (with the var set it emits the full block for all files; with it unset it silently no-ops), BUT the orphan block did fire in ice-coupons at 12:49 and 16:40 today — so the var reaches the hook in practice.

## ACTUAL ROOT CAUSE (confirmed from Chris's own transcripts)

- Orphan detection **works and fires**. The screenshot session (ice-coupons `2cd12436`, ~14:19 today) DID emit the full "BLOCKING — ORPHAN CLEANUP REQUIRED" block into context from its startup hook.
- But Chris's first action was `/cpm:status`, and the skill's own SKILL.md instructions steamrolled the injected hook instruction — the assistant went straight into status reconnaissance and never surfaced the orphan prompt.
- Evidence: `grep` of `2cd12436.jsonl` shows the ORPHAN text present only as injected hook context; the assistant's first texts are "I'll run the CPM status reconnaissance…" — it never paused for cleanup.
- Every recent ice-coupons session's first command is `/cpm:status`. So Chris ~always enters via a slash-command skill, which reliably swallows the SessionStart-injected blocking instruction. That is why "it stopped prompting."
- **Core insight**: SessionStart stdout is *advisory context*. It cannot win against an explicit user slash-command that carries its own SKILL.md body. A hook cannot force the interaction — so the check must live where the user actually enters (the skills), not only in the hook.
- The `/clear`-path gap (session-start-compact.sh has no orphan detection + a silent "cat all" fallback that resurrects stale files as active state) is a **real secondary bug**, but not the cause of the observed symptom.

## LOCKED DESIGN (agreed with Chris)

1. **One shared classification rule** (age + session-ID) factored into a single helper that both hooks and the skill-step call use — kills the `session-start.sh` / `session-start-compact.sh` duplication AND fixes the `/clear` silent-resurrection bug in the same move.
2. **Once-per-session safety-net check** in shared conventions (`shared/skill-conventions.md`), guarded by a `CPM_SESSION_ID`-keyed sentinel so it fires at most once per session no matter how many `/cpm:*` commands run. **Non-blocking OFFER** — the aggressive "BLOCKING — stop everything" behaviour is removed entirely. Three presentation branches over one detection pass:
   - **STALE (≥ 3 days)** → offered for deletion (delete-on-confirm only).
   - **FRESH other-session files → SURFACED AS INFORMATIONAL** ("these look like active/recent parallel sessions") — NOT offered for deletion, NOT silent. Chris explicitly valued being warned about ongoing, non-stale parallel sessions previously; it doubles as a genuine parallel-session aid. This is a **requirement**, not a nicety.
   - **Current-session file** → injected as active state (unchanged).
3. **New `/cpm:clean` command** — explicit, exhaustive, on-demand: lists ALL progress + compact-summary files with age + session label, deletes only what the user names. No sentinel, no staleness filter. Deliberately distinct from `/cpm:archive` (which MOVES durable artifacts into `docs/archive/`; `clean` DELETES ephemeral session state). Name chosen over "tidy" because tidy implies reorganisation.
4. **Staleness threshold = 3 days.**

## Decisions settled

- Staleness threshold **3 days**: YES.
- Replace BLOCKING with a **non-blocking offer**: YES.
- New command name: **`/cpm:clean`**.
- Fresh parallel-session awareness: **MUST surface** (informational), never auto-delete.

## Scope / regression surface (architect's flag)

Touches four things plus tests:

- the shared classifier (new single source of truth),
- both hook scripts (consume the classifier, drop their local copies),
- the shared-conventions once-per-session safety-net step,
- the new `/cpm:clean` skill,
- extend `test-orphan-detection.sh` and `test-compact-hook.sh` so the hook refactor does not regress the compaction-resilience guarantee (the load-bearing reason this is worth a spec rather than a direct edit).

## Outcome

Design fully locked. Consultation wrapped up with agreement to hand off to `/cpm:spec` to build this properly through the pipeline, with the test-coverage requirement called out so the compaction-recovery guarantees cannot silently regress.

## Related prior discussions

- `02-discussion-parallel-sessions.md` — parallel-session progress files (origin of session-scoped filenames).
- `06-discussion-progress-file-cleanup.md` — earlier progress-file cleanup thinking.
