# Discussion: Board terminal-status handling — count Done/Superseded/Withdrawn as done

**Date**: 2026-07-20  
**Agents**: Bella (Senior Developer)

## Discussion Highlights

### Key points so far

- Root cause of the screenshot bug: the board hard-codes exact-match `"Complete"` in ~10 places across `status_model.py` and `board_view.py`. The canonical CPM vocabulary is `Pending / In Progress / Complete` only.
- The project in the screenshot uses `**Status**: Done` on some stories/epics. The board does NOT recognise "Done", so those items count as 0 in progress, mis-classify as in-progress (fallback branch in `_epic_state`), and are never hidden by the `z` (show/hide done) toggle.
- CPM's own `pivot` skill already treats `**Status**:` containing "done" or "complete" (case-insensitive) as complete — so the board is the strict outlier, not "Done".
- Chris had already implemented Superseded/Withdrawn (uncommitted working tree) as an **epic-level "retired/inactive"** concept that EXCLUDED such epics (and their stories) from state, next-actions, and progress counts — across the contract, five skills, board code, and tests. This is a coherent implementation, but it EXCLUDES retired work rather than counting it.
- The shared contract `cpm/shared/status-model.md` is the source of truth governing BOTH the board and `/cpm:status`; per its own rule, it must be changed first and both consumers kept in sync.

### Decisions (all confirmed by Chris)

1. **Everything counts** — every terminal status counts toward progress; nothing is dropped from the denominator. This **flips** the just-built code from EXCLUDE → COUNT: a 2-story Withdrawn epic reads `2/2` and folds into the project total.
2. **Superseded/Withdrawn are epic-level only** — a story-level Superseded/Withdrawn is out of scope.
3. **Normalise** — `Done`, `Superseded`, `Withdrawn` all mean the same as `Complete` for counting/state/hiding.
4. **Dependencies split them**: `Superseded`/`Withdrawn` must **permanently block** anything that depends on them (that work will never be done), whereas `Done` (like `Complete`) is finished work and **satisfies** a dependency. This is the one place the three are NOT synonyms.
5. **Retro nudge carve-out**: retired (`Superseded`/`Withdrawn`) epics count as done but do NOT nag `/cpm:retro` — they suggest `/cpm:archive` instead. `Complete`/`Done` epics lacking a retro still nudge retro.

### Final locked model

| Status | Counts as done (progress · state · `z`-hide) | Satisfies a dependency (unblocks dependents) | Retro nudge |
|---|:---:|:---:|:---:|
| `Complete` | yes | yes | yes (if no retro) |
| `Done` | yes | yes (finished work) | yes (if no retro) |
| `Superseded` / `Withdrawn` | yes | **NO — permanently blocks** | no → `/cpm:archive` |

Two sets in the model:

- **done-for-counting** = `{Complete, Done, Superseded, Withdrawn}` (case-insensitive) → progress numerator, hide-by-`z`, state can't peg amber/red. A retired/Done epic's stories all count as done.
- **satisfies-dependency** = `{Complete, Done}` only → Superseded/Withdrawn deliberately excluded so dependents stay permanently blocked (preserves the existing "retiring a depended-upon epic surfaces as a real blocker" contract prose).

Principle: **read tolerant, write strict** — CPM keeps *emitting* `Complete`; readers (board, status, do, ralph, archive) *accept* `Done` as equivalent (matches `pivot`). Nothing starts writing "Done" into new docs. Reference rows keep the status-word label (`· Withdrawn`), not a fraction.

### Change surface

- `cpm/tools/board/status_model.py` — define the two sets; flip `derive_project`'s count from exclude→count; story checks accept `Done`; the dependency check stays `Complete`/`Done`-only (Superseded/Withdrawn excluded).
- `cpm/tools/board/board_view.py` — done/hide checks accept `Done`; keep `_inactive_row` (status-word label).
- `cpm/tools/board/tests/test_derivation.py` — the "only the live epic's two stories count" assertion **inverts** (they count now); add `Done` cases.
- `cpm/shared/status-model.md` — rewrite the exclude passages to the count model; document `Done` normalisation + the dependency split.
- `cpm/skills/{status,do,ralph,archive,epics}/SKILL.md` — the "not Complete" done-markers also accept `Done`; the `status` skill's "retired excluded from counts" line flips to "counted as done."

### Scope note
This is a `/cpm:quick`-sized change — one predicate pair replacing scattered string matches, plus doc/test truthing. It sits on top of, and partially reverses (counting only), the uncommitted Superseded/Withdrawn work already in the working tree.
