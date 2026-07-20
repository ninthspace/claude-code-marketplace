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
| Epic status | each epic's `**Status**:` — auto-derived `Pending` / `In Progress` / `Complete`, or the terminal, user-set `Superseded` / `Withdrawn` (see *Retired epics* below) |
| Story status | each `##` story's `**Status**:` and `**Blocked by**:` |
| Git HEAD | `git rev-parse HEAD` — used for **freshness only** (see the board's cache), never for state |

**`Done` is read as `Complete`.** CPM only ever *writes* `Complete`, but readers accept `Done` (case-insensitive) as a full synonym — a hand-authored or imported `**Status**: Done` counts, hides, and satisfies dependencies exactly like `Complete`. This "read tolerant, write strict" rule keeps off-spec docs working without letting `Done` leak into newly-generated artifacts.

**Unblocked story rule** (shared with `cpm:do` hydration, so the board agrees with what `do` would pick up): a `Pending` story is *unblocked* when its `**Blocked by**` is `—` or every referenced story/epic is *finished* (`Complete` / `Done`). A `Superseded` / `Withdrawn` reference is **never** satisfied (see *Retired epics*). Otherwise the story is *blocked*.

**Story progress**: `Σ (stories done) / Σ (total stories)` across **all** epics, rendered as e.g. `4/7`. A story is *done* when its status is `Complete` / `Done`, and **every** story of a terminal epic (a retired `Superseded` / `Withdrawn` epic, or one whose epic-level status is `Complete` / `Done`) counts as done — everything counts, nothing is dropped from the denominator.

### Status parsing (lead-token) and linting

A `**Status**:` value is read by its **leading token** — the text up to the first
delimiter (an em/en dash `—` / `–`, a spaced hyphen ` - `, an opening paren `(`,
or a semicolon `;`). That leading token is normalised (trimmed, case-insensitive)
against the vocabulary; **everything after the delimiter is a human note the tool
ignores**. So:

```
**Status**: Complete — folded into Story 10; do not execute separately
```

reads as `Complete` (it counts, hides, and satisfies dependencies), while the
tail is preserved verbatim in the source for a human reader. This lets a real,
messy status carry triage context without breaking derivation — write the
canonical word first, then `— your note`.

**Recognised vocabulary**: stories accept `Pending` / `In Progress` / `Complete`
/ `Done`; epics accept those plus `Superseded` / `Withdrawn`. `Superseded` /
`Withdrawn` are **epic-level only** — on a story they are *unrecognised*.

**Linting, not guessing.** A non-empty status whose leading token is *not* in the
recognised vocabulary is **flagged, never parsed by prose**. The tool does not try
to infer intent from free text like `Folded into Story 10` — it surfaces it so a
human (or a `/cpm` skill) can rewrite it to the `Complete — note` form. An
unrecognised status still **counts as not-done** (the conservative choice: it is
made visible, never silently swept into the "done" pile). The board surfaces it as:

- a trailing `(!)` marker on the epic row,
- a `⚠` glyph and warning colour on the offending story row (showing the raw text),
- a short preface in the epic-detail panel listing each unrecognised status,
- a distinct callout in `/cpm:status`.

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
| `in-progress` | any story `In Progress`, or a mix of *done* (`Complete`/`Done`) + `Pending` stories | amber |
| `epics-ready` | epic files exist and **every** story is still `Pending` (nothing started) | amber |
| `spec-ready` | spec(s) exist but no epic files derived yet | amber |
| `complete` | every active epic finished (all stories done), or every epic retired | green |

Two deliberate choices:

- `blocked` means *genuinely stuck* (no unblocked work remains), not merely "some
  story is blocked." A project that is actively moving is never mislabelled red.
- `unknown` is the graceful-degradation state: an unreachable path or a
  half-written / malformed artifact resolves here rather than aborting the sweep.

### Retired epics (`Superseded` / `Withdrawn`)

`Superseded` and `Withdrawn` are **terminal** epic statuses a user sets by hand
when an epic's work is no longer needed — `Superseded` for work replaced by
another epic, `Withdrawn` for work simply dropped. They are **never
auto-derived** from stories (unlike `Pending` / `In Progress` / `Complete`), and
CPM never sets them on your behalf — you action them explicitly.

A retired epic is **closed out, not deleted**. Its stories all **count as done**
toward story-progress (the work is finished with, so it swells the numerator, not
the "still to do" pile), and the epic is removed from the state *logic* and the
next-action list so a deliberately-abandoned epic can't peg a project to a stuck
amber/red state or nag a `/cpm:retro` — there is nothing to reflect on, so it is
`/cpm:archive`'s job, not the retro's. A project whose only remaining epics are
retired (or `Complete`) resolves to `complete`.

**But a retired epic never satisfies a dependency.** Cross-epic dependency
resolution still *sees* it, and because its work will never be done, anything
depending on it stays **permanently blocked** — retiring a depended-upon epic
surfaces as a real blocker, not a silent skip. This is the one place `Superseded`
/ `Withdrawn` diverge from `Complete` / `Done`: they count as done everywhere
*except* as a satisfied dependency.

Retired epics are swept out of the active `docs/` tree by `/cpm:archive` (a
dedicated staleness signal). In the board they appear only under the
show-complete toggle, dimmed and labelled with their status word.

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
5. `/cpm:retro {epic}` (then `/cpm:archive`) — one per `Complete` epic lacking a retro **and not waived** (see *Retro waiver* below).
6. `/cpm:discover` — only when the project is `no-artifacts`.

Each candidate is a record: `{ kind, command | null, target_path, label }`.

### Retro waiver (`**Retro waived**:`)

A retro is never mandatory: `cpm:do` deliberately skips end-of-epic retro generation for a clean epic (no retro-trigger signal fired). To stop such an epic nagging as "retro pending" forever, a completed epic may carry an epic-level **`**Retro waived**:`** marker (a header-block field, distinct from the story-level `**Retro**:` observation fields). A `Complete` epic bearing this marker is treated as **retro-satisfied** — exactly like one with an actual `docs/retros/` retro — so it produces **no** `/cpm:retro` candidate (rule 5) and no board retro row/summary. The marker is set by **`/cpm:retro triage`** on epics it classifies as clean, and is a plain, reversible record: deleting the line restores the nudge. It affects only the retro follow-up — counting, state, hiding, and dependency logic are unchanged.

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
