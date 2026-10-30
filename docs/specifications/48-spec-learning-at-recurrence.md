# Spec: Learning at recurrence

**Date**: 2026-10-30  
**Source**: docs/discussions/04-discussion-harness-loops-graphs-for-cpm-next.md (part (b), not built by spec 47), and conversation
**Amended**: 2026-10-30 — NFR1 measures the word count with no limit (user's decision in review 06, docs/reviews/06-review-learning-at-recurrence.md, resolving the Pivot deferred in 48-07); FR7 says `library` is the only skill that keeps the retro format, since FR6 still has `do`, `plan` and `review` read unretired observations

## Problem Summary

cpm-next learns through a retro written when an epic completes and a `library learn` run the user starts later. Most retro observations are specific to one spec, epic or story and are never useful again, yet `do`, `plan` and `review` read them as context, and the user is asked to sort them. A lesson worth keeping is one that has been met more than once, and that is known when the second failure is recorded, not when an epic ends.

Learning also happens at two levels the plugin does not separate:

- **Repo-level**: a constraint about one codebase, kept in that project's `docs/library` and applied by its `plan`, `review`, `do` and auditor.
- **Process-level**: a failure a cpm-next rule could have prevented, fixed by changing a skill or the auditor and shipped by version. Today this needs someone to read retros across repositories by hand; spec 47 came from two agents doing that once.

The files changed are `cpm-next/skills/{do,plan,review,library,status}/SKILL.md`, `cpm-next/skills/do/worktree.md` and the contract `cpm-next/shared/artifacts.md`.

## Functional Requirements

### Must Have

- **FR1**: `do` records a signal on the story, or the `docs/quick/` record, where a failure was found: `**Signal**: {class-slug} — {project | process} — {what failed, one line} ({the file and step, rule or check involved})`. It writes one when an audit finding holds (Critical or Warning), when a story is marked blocked (including blocked on a test failure), and when it writes an `**Amended**`, `**Inline change**` or `**Pivot deferred**` line. `project` means the cause is in this codebase; `process` means a cpm-next rule could have prevented it, and its parenthesis names the cpm-next file and step. One signal per class per story. A worktree subagent reports its failures for the lead to record. — AC: the contract defines the field; `do` and `worktree.md` state when and by whom it is written `[manual]`
- **FR2**: A class slug is kebab-case and names the kind of failure, not the instance. `do` reuses a slug already used in `docs/epics/`, `docs/quick/` or a library lesson's `**Class**`, or one of the contract's seed slugs, and makes a new one only when none fits. — AC: the contract lists seed slugs and the rule; `do` states it `[manual]`
- **FR3**: A signal reference is `{epic or quick path} → Story {N} → {slug}`. After writing a signal, `do` looks for the same failure, in this order: a library lesson with that `**Class**` (or, for a lesson with none, one that describes it); a signal with that slug in a different epic or quick record of any spec; an unretired legacy retro observation that describes it. It reads both to confirm, and on a match appends ` — recurs: {signal or lesson reference, or retro path → "{opening words}"} ({why it matches, one clause})` to the new signal. A match within the same epic is not a recurrence. A rejected confirmation gives the new signal a different slug. — AC: the contract shows the forms; `do` states the order, the threshold and the confirmation `[manual]`
- **FR4**: A `project` signal that recurs and has no library lesson goes under **Needs you** once, as a promotion candidate with the matching signals and the constraint text proposed. In the walk-through, a yes makes `do` write a `lessons-learned.md` entry in the contract's form; `do` appends ` — raised {YYYY-MM-DD}` to the signal when it raises it and ` — declined {YYYY-MM-DD}` on a no, and never raises a signal so marked again. A `process` signal, and a recurrence of an existing library lesson, go under **Found** only. Nothing is promoted without the user's yes. — AC: `do` states the routing, the marks and the walk-through case; control: a signal with ` — raised` or ` — declined` is not raised again `[manual]`
- **FR5**: A promoted lesson is a constraint, not a story: the rule, how a criterion or check shows it holds, the owning layer, `**Class**: {slug}`, and `**Source**` naming the signal references that prompted it. The `lessons-learned.md` entry and the amendment block take this form, and the duplicate rule matches on `**Class**`. `do` writes only `lessons-learned.md` entries; amendments to other library documents stay with `library learn`. — AC: the contract shows both forms `[manual]`
- **FR6**: `do`, `plan` and `review` read library lessons, signals that recur, and unretired legacy retro observations (until `library learn` retires them). `**Lessons**` lines may cite a signal reference as well as the existing forms. — AC: the three skills and the contract state it `[manual]`
- **FR7**: `do` no longer writes a retro when an epic completes, a `**Retro waived**` line, or a story `**Retro**` line: an unresolved audit finding that concerns no criterion becomes a signal, and Suggestions are not recorded. The contract's retro format, `**Retired` marker and `**Recurrence**` rule move to `library`, the only skill that keeps the retro format; `do`, `plan` and `review` still read unretired observations, as FR6 says. — AC: `grep -c "Retro waived\|\*\*Retro\*\*" cpm-next/skills/do/SKILL.md cpm-next/skills/status/SKILL.md` returns 0 for each, and the contract keeps the retro format only as a pointer to `library` `[manual]`
- **FR8**: `status` reports, as suspect records, a story with a `- Not met:` line, a ` — blocked:` note or an `**Audit**` line with findings fixed but no `**Signal**`; reports the count of unretired legacy retro observations with `/cpm-next:library learn` while any remain; and no longer reports a `Complete` epic without a retro. — AC: `status` states it `[manual]`
- **FR9**: `library learn` promotes from recurring `project` signals and from legacy retro observations, proposes the owning layer for each (a library constraint for `project`; a `plan` criterion rule, a `do` rule or an auditor check for `process`), writes `project` lessons in the form of FR5, and lists `process` candidates without writing them. — AC: `library` states it `[manual]`
- **FR10**: `library sweep` reads a list of repositories kept at `~/.claude/cpm-next/repos.txt` (one absolute path per line; `library sweep add {path}`, `remove {path}` and `list` manage it, and a missing file is reported with how to add one), collects every `process` signal in their `docs/epics/` and `docs/quick/`, and unretired legacy retro observations that name a cpm-next skill or rule, and groups them by the cpm-next file and step involved, using the slug as a hint and reading to confirm. It reports each group found in two or more repositories, with its signals. It writes nothing in the scanned repositories; on the user's choice it writes a discussion record in the current repository for `/cpm-next:plan`. — AC: `library` states it `[manual]`
- **FR11**: A signal that never recurs is never promoted, never put to the user, and needs no retirement step. — AC: `do` states it; control: `do` puts a signal under **Needs you** only when it recurs and is `project` and unmarked `[manual]`

### Should Have

- **FR12**: `plan` states a criterion over the rule it enforces rather than one instance ("every export streams its rows", not "the January export streams its rows"), and `review` flags one that names an instance where the rule is meant. — AC: `plan` and `review` state it with that example `[manual]`
- **FR13**: `do`'s **Needs you** gives each `**Pivot deferred**` item with the `/cpm-next:plan {path}` that settles it, and `status` lists each with its target document. — AC: `do` and `status` state it `[manual]`

### Won't Have (this iteration)

- Promotion without the user's yes, and any plugin change made by a sweep.
- Changes to the `cpm-next-models`, `cpm-next-progress` or `whats-next` mods.
- Back-filling signals into existing epics or converting existing retros.
- From the same analysis, left for a later spec: a library field naming the paths or terms a document applies to; install-owned required checks for the auditor; an epic-graph lint run as code; audit rounds scaled by `**Effort**`.

## Non-Functional Requirements

- **NFR1**: The release records the combined word count of `do`, `plan`, `review`, `library`, `status`, the auditor and the contract before (10,978 at commit `70c789c`, `wc -w`) and after; no limit applies.
- **NFR2**: No added sentence in a SKILL.md, `worktree.md` or agent file records history, per `CLAUDE.md` "A SKILL.md is not a change log".
- **NFR3**: `claude plugin validate cpm-next` reports no errors, and the mods' suites (`claude plugin test cpm-next-models`, `cpm-next-progress`, `whats-next`) still pass.

## Architecture Decisions

### AD1: Signals live in the epic doc
A `**Signal**` line on the story, in place of `**Retro**`, so the epic stays the only run state and matching is a grep across `docs/epics/` and `docs/quick/`. The mods' parsers read only `Status`, `Blocked by` and `Source spec`, so a new field is safe. Rejected: an append-only signals file; signals in retro files. User's decision, 2026-10-30.

### AD2: A class slug, confirmed by reading; the sweep groups by rule
A slug makes signals countable by `grep`; the confirmation read stops a careless shared slug becoming a lesson. Slugs are chosen per repository, so across repositories the sweep groups `process` signals by the cpm-next file and step they name, a namespace every repository shares, and uses the slug only as a hint. Seed slugs in the contract reduce drift. Rejected: judgement only; a closed taxonomy. User's decision on the slug; the sweep grouping planned here.

### AD3: No epic-completion retro
With signals and recurrence the retro has no job left. Existing retros stay readable and keep counting until `library learn` retires them. Rejected: an optional summary retro. User's decision.

### AD4: The sweep is a library mode, its list outside repositories
`library` already reads and writes lessons. The repository list is personal to the machine and spans projects, so it lives under `~/.claude/cpm-next/`. Reading other repositories will raise permission prompts; the README says so. User's decision on the mode; the path planned here.

### AD5: `do` writes a confirmed project lesson itself, as an entry only
At the second occurrence the user has both examples in front of them. `do` writes only a `lessons-learned.md` entry, which needs no choice of target document; amendments, batch promotion and legacy retros stay with `library learn`.

### AD6: Process findings go to the sweep, not to each project's Needs you
A `process` candidate cannot be acted on in the project that hit it, and in unattended runs it would pile up in **Needs you** in every repository. It is listed under **Found** and counted by the sweep, where the user decides on a plugin change. This replaces spec 47's FR16 routing of a library-lesson recurrence to **Needs you**.

## Scope

### In Scope
The files named in the Problem Summary; the cpm-next README log and upgrade note (which tells the user to run `/cpm-next:library learn` on existing retros); plugin and marketplace versions and descriptions (cpm-next 0.10.0, marketplace 4.0.5); the root `README.md` line describing `retros/`; and a maintenance record in `docs/maintenance/README.md` of the repository-list path, the new contract strings, and that the mods' parsers ignore unknown fields.

### Out of Scope
The mods; any project's docs; back-filling.

## Testing Strategy

The skills are prose; each requirement is checked by reading the changed file against it, with `grep` for required strings (`[manual]`). NFR1 by `wc -w`; NFR3 by `claude plugin validate cpm-next` and `claude plugin test` on the three mods. Behaviour is seen in a live run only through an installed release, in the final user-checks epic, using a scratch repository with two seeded epics that share a failure, and two scratch repositories for the sweep, so the checks do not wait for real projects to fail twice. Commit `70c789c` is the baseline for every count.

## Assumptions

- Signals record failures an audit or a blocked story already exposes; `do` gains no detection step, only a record of what it found.
- "Different epic" is the repo-level threshold, across specs too; a repeat within one epic is the same mistake carried through it, which `do` step 5 already fixes wherever it occurs.
- The sweep reports groups in two or more repositories; the user decides what becomes a plugin spec.
- The repository-list path is chosen here; the user can move it at review.
- The user's own `~/.claude/CLAUDE.md` progress-tracker section lists "Retro or Found items"; after this release no story `**Retro**` line exists, so that text is the user's to update after release; the upgrade note says so (user's decision, 2026-10-30). The user confirmed AD4's path, AD6's routing and dropping Suggestions on 2026-10-30.
- The challenge pass (Casey, Margot, Ren) found the old `**Recurrence**` and `**Retro**` uses left in place, lessons without a class, per-repo slugs defeating the sweep, legacy retros dropped from matching, repeat prompts in unattended runs, criteria that only check that text exists, and a word budget that left out `library` and `status`; each is folded in above. Not taken: a shared slug file beside `repos.txt` (the sweep groups by rule instead).
