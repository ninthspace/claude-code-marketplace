# CPM Status Model

**The shared definition of how a CPM project's planning state is derived and what to do next.**

This document is the single source of truth for project-status derivation. Two
implementations conform to it and must never diverge:

- `/cpm:status` — the in-project reconnaissance skill (prose synthesis).
- `cpm/tools/board` — the cross-project status board & launcher (code).

`/cpm:status` *references* this model in prose; the board *implements* it in code.
When the derivation rules change, change them here first, then update both consumers.

---

## Inputs (read-only)

State is derived by reading a project's planning artifacts and git — never by
mutating anything.

| Input | Source |
|---|---|
| Specs | `docs/specifications/[0-9]*-spec-*.md` |
| Epics | `docs/epics/[0-9]*-epic-*.md` — both flat (`NN-`) and two-part (`NN-MM-`) shapes; exclude `-coverage-` files |
| Briefs | `docs/briefs/[0-9]*-brief-*.md` (presence only) |
| Retros | `docs/retros/[0-9]*-retro-*.md` (presence only, for `complete` follow-up) |
| Epic status | each epic's `**Status**:` (`Pending` / `In Progress` / `Complete`) |
| Story status | each `##` story's `**Status**:` and `**Blocked by**:` |
| Git HEAD | `git rev-parse HEAD` — used for **freshness only** (see the board's cache), never for state |

**Unblocked story rule** (shared with `cpm:do` hydration, so the board agrees with what `do` would pick up): a `Pending` story is *unblocked* when its `**Blocked by**` is `—` or every referenced story/epic is `Complete`. Otherwise it is *blocked*.

**Story progress**: `Σ (stories Complete) / Σ (total stories)` across all epics, rendered as e.g. `4/7`.

---

## States

Every project resolves to exactly one **overall state** — the single most-salient
label, used for the RAG glance. Precedence is top-to-bottom; the first matching
rule wins.

| State | Condition | RAG |
|---|---|---|
| `unknown` | project path unreachable, or its artifacts cannot be parsed | grey (`?`) |
| `no-artifacts` | no specs and no epics under `docs/` | grey |
| `blocked` | epics have `Pending` stories, but **none are unblocked** (all remaining work waits on incomplete deps) | red |
| `in-progress` | any story `In Progress`, or a mix of `Complete` + `Pending` stories | amber |
| `epics-ready` | epic files exist and **every** story is still `Pending` (nothing started) | amber |
| `spec-ready` | spec(s) exist but no epic files derived yet | amber |
| `complete` | all epics `Complete` | green |

Two deliberate choices:

- `blocked` means *genuinely stuck* (no unblocked work remains), not merely "some
  story is blocked." A project that is actively moving is never mislabelled red.
- `unknown` is the graceful-degradation state: an unreachable path or a
  half-written / malformed artifact resolves here rather than aborting the sweep.

---

## Next actions

A project frequently has **more than one** actionable next step at once — two
specs awaiting epics, two in-progress epics, a completed epic needing a retro
alongside another still mid-flight. The model therefore derives an **ordered list
of candidate next actions**, not a single value.

- The **primary** next action is the first item in the ordered list — this is what
  the roll-up shows and what a one-shot consumer (`/cpm:status`) recommends.
- The remaining candidates are surfaced in the board's drill-down / launch picker,
  so the user can choose which to copy or launch.

### Candidate ordering (priority, highest first)

1. `attention:unblock` — one per blocked epic; names the unmet dependency. **No command** (the action is to unblock, not to `/cpm:do`).
2. `/cpm:do {epic}` — one per **In-Progress** epic (continue), lowest epic number first.
3. `/cpm:do {epic}` — one per **epics-ready** epic (start), lowest epic number first.
4. `/cpm:epics {spec}` — one per spec with no derived epics, lowest spec number first.
5. `/cpm:retro {epic}` (then `/cpm:archive`) — one per `Complete` epic lacking a retro.
6. `/cpm:discover` — only when the project is `no-artifacts`.

Each candidate is a record: `{ kind, command | null, target_path, label }`.

### State ↔ primary-action consistency

The overall state's precedence is aligned with the primary (first) candidate, so
the RAG label and the recommended action never contradict each other:

| State | Primary next action |
|---|---|
| `blocked` | `attention:unblock` on the lowest-numbered blocked epic |
| `in-progress` | `/cpm:do` on the lowest-numbered In-Progress epic |
| `epics-ready` | `/cpm:do` on the lowest-numbered epics-ready epic |
| `spec-ready` | `/cpm:epics` on the lowest-numbered spec without epics |
| `complete` | `/cpm:retro` (then `/cpm:archive`) |
| `no-artifacts` | `/cpm:discover` |
| `unknown` | none — needs manual inspection |

---

## Graceful degradation

- **Unreachable path** (registry entry points nowhere) → state `unknown`, labelled
  "unreachable", empty next-action list.
- **Unparseable / half-written artifact** → state `unknown` (`?`), empty next-action
  list. A single bad project is isolated — it **must never abort the whole sweep**.
