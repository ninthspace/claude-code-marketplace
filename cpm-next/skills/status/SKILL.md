---
name: status
description: Read-only project status from the CPM artefacts and git — what the project is, what's been built, what's in flight or blocked, what's waiting on the user, and the next command to run. Use whenever the user returns to a project, asks where things stand, what's next, what's blocked, or what state an epic or spec is in. Triggers on "/cpm-next:status".
---

# Status

Tell the user where the project stands and what to run next, in one screen. The artefacts are the state, so this is a reading of `docs/` and git, and nothing is written.

Status vocabulary, the unblocked-story rule and the evidence format are in `shared/artifacts.md` at the plugin root, two levels above this skill's directory.

## Scope

`$ARGUMENTS` may be a path, a question, or nothing. A path to an epic or spec narrows the report to that artefact and what hangs off it. A question shapes what the report leads with. With nothing, report on the whole project.

## Read

- **Epics**: every epic's status and its stories' statuses, read by the first token. Count `Superseded` and `Withdrawn` epics as closed, not as work remaining.
- **Waiting on the user**: `**Pivot deferred**` lines, stories blocked with a `Not met` criterion, and discussions still `In progress`.
- **Gaps**: specs with no epics, and `Complete` epics with neither a retro whose `**Source**` names them nor a `**Retro waived**` line.
- **Suspect records**: a status outside the vocabulary, a `Complete` story with a criterion that has no `Evidence` line, and a `Complete` epic with a story that isn't. Report these; don't interpret them. A legacy story-level `**Evidence**` field counts as evidence.
- **Git**: the branch, uncommitted changes, and recent commit subjects. Use the last few days of commits if there was activity today, otherwise the last twenty.

For a single spec, also show which of its Must Have requirements no story's `**Satisfies**` names.

## Report

Write it for someone picking the project up cold:

- **Where it stands**: a few short paragraphs of prose. What the project is, what has been built (grouped into themes, not listed), what recent work has been about, and what is in flight. Lead with in-flight work when there is any.
- **Needs you**: waiting items and suspect records, each with its path. Leave the heading out if there are none.
- **Next**: the commands worth running, most useful first, such as `/cpm-next:do {epic}`, `/cpm-next:plan {spec}` for a spec without epics or a pending pivot, `/cpm-next:review {epic}` before a large epic's first run, or `/cpm-next:library learn` once retros have accumulated.

When no CPM artefacts exist, say so in one line and suggest `/cpm-next:party` or `/cpm-next:plan`.
