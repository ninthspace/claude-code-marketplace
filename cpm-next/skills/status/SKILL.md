---
name: status
description: Read-only project status from the CPM artefacts and git — what the project is, what's been built, what's in flight or blocked, what's waiting on the user, and the next command to run. Use whenever the user returns to a project, asks where things stand, what's next, what's blocked, or what state an epic or spec is in. Triggers on "/cpm-next:status".
model: haiku
effort: low
---

# Status

Tell the user, in one screen, where the project stands and what to run next. Read `docs/` and git, and write nothing.

`shared/artifacts.md`, two levels above this skill's directory, defines the status vocabulary, the unblocked-story rule and the evidence format.

## Scope

A path to an epic or spec in `$ARGUMENTS` narrows the report to that artefact and what hangs off it. A question sets what the report leads with. With nothing, report on the whole project.

## Read

- **Epics**: each epic's status and its stories' statuses, by the first token. `Superseded` and `Withdrawn` epics are closed, not work remaining.
- **Waiting on the user**: `**Pivot deferred**` lines; blocked stories, whose `**Status**` carries ` — blocked: {reason}` or that have an indented `- Not met:` line under a criterion, with the reason; discussions still `In progress`; and stories waiting on a user check. A story waits on a user check when all four hold: everything named in its own `**Blocked by**` and in its epic's `**Blocked by**` is `Complete`; its `**Status**` has no ` — blocked:` note and no criterion has an indented `- Not met:` line; at least one criterion has no `Evidence` line; and every criterion without `Evidence` is tagged `[user]`. It keeps its `Pending` or `In Progress` status: report it here, not as work in flight, with the steps of each `[user]` criterion that has no `Evidence` line, and recommend carrying them out and then running `/cpm-next:do {epic}` to record the result.
- **Gaps**: specs with no epics, and `Complete` epics with neither a retro whose `**Source**` names them nor a `**Retro waived**` line.
- **Suspect records**: a status outside the vocabulary, a `Complete` story with a criterion that has no `Evidence` line (a legacy story-level `**Evidence**` field counts), and a `Complete` epic with a story that isn't. Report these without interpreting them.
- **Git**: the branch, uncommitted changes, and recent commit subjects: the last few days' if there was activity today, otherwise the last twenty.

For a single spec, also list its Must Have requirements that no story's `**Satisfies**` names.

## Report

Write for someone picking the project up cold:

- **Where it stands**: a few short paragraphs of prose: what the project is, what has been built (grouped into themes, not listed), what recent work has been about, and what is in flight, leading with in-flight work when there is any.
- **Needs you**: each waiting item and suspect record with its path and your recommendation: what to decide and which way, or the command that settles it. Don't ask the user about each one; the skill that settles it does that. Leave the heading out if there are none.
- **Next**: the commands worth running, most useful first, such as `/cpm-next:do {epic}` to build, only for an epic with a story that is unblocked, not marked blocked and not waiting on a user check (an epic whose open stories all wait already has its command under **Needs you**), `/cpm-next:do {epic} --parallel check` when two or more of its stories are unblocked at once, `/cpm-next:plan {spec}` for a spec without epics or a pending pivot, `/cpm-next:review {epic}` before a large epic's first run, or `/cpm-next:library learn` once retros have accumulated.

When no CPM artefacts exist, say so in one line and suggest `/cpm-next:party` or `/cpm-next:plan`.
