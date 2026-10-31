# cpm-next Artefact Contract

The skills in this plugin keep their procedures short and their data strict. This file is the strict part. The `whats-next` and `cpm-next-progress` mods parse these files, so the formats below are a contract: write them exactly, read them tolerantly.

## Where things live

| Artefact | Path | Written by |
|---|---|---|
| Discussion | `docs/discussions/{nn}-discussion-{slug}.md` | party; library sweep |
| Brief | `docs/briefs/{nn}-brief-{slug}.md` | plan |
| ADR (only for decisions that outlive one spec) | `docs/architecture/{nn}-adr-{slug}.md` | plan |
| Spec | `docs/specifications/{nn}-spec-{slug}.md` | plan |
| Epic | `docs/epics/{parent}-{seq}-epic-{slug}.md` | plan (structure), do (status, signals), library (signal marks) |
| Retro (legacy) | `docs/retros/{nn}-retro-{slug}.md` | no skill writes one; library reads them and marks observations retired |
| Review | `docs/reviews/{nn}-review-{slug}.md` | review |
| Quick change record | `docs/quick/{nn}-quick-{slug}.md` | do; library (signal marks) |
| Reference library | `docs/library/*.md` | library, the user, or do (`lessons-learned.md` entries); every skill reads it |
| Persona roster override | `docs/agents/roster.yaml` | the user; replaces the plugin default entirely |

Read all of these as context whenever they bear on the work. Files from CPM v3, including legacy flat epics (`{nn}-epic-{slug}.md`) and coverage matrices (`*-coverage-*.md`), are valid input. This plugin does not create coverage matrices; the `**Satisfies**` field on each story carries the traceability instead.

## Numbering

`{nn}` is `max + 1` over the integer prefixes in both `docs/{type}/` and `docs/archive/{type}/`. Compare as integers, never as strings. Pad to at least two digits (`01`, `99`, `100`). Numbers are never reused and existing files are never renamed.

Epic prefixes are two-part. `{parent}` is the source spec's number, or `00` when the epic comes from a brief, discussion or description with no spec. `{seq}` is `max + 1` over existing epics with that parent, again across active and archive.

## Status vocabulary

The first token of a `**Status**:` value is what tools read. Anything after ` — ` is a human note.

- Stories and tasks: `Pending`, `In Progress`, `Complete`.
- Epics: those three, derived from their stories, plus the user-set terminal values `Superseded` and `Withdrawn`. Never set the terminal values yourself.
- Read `Done` as `Complete`; always write `Complete`.
- A story `do` has to stop on (a `Not met` line, an audit finding left unresolved, a failure it can't explain) is marked blocked: it keeps its status and adds the note ` — blocked: {reason}`, so tools still read the first token. The note comes off when the user settles what blocked the story and nothing else still blocks it; `do` then resumes the story. A story waiting on the user is not blocked.
- A story is unblocked when its `**Blocked by**` is `—` or every item it names is `Complete`, and every item its epic's `**Blocked by**` names is `Complete`. A `Superseded` or `Withdrawn` epic never satisfies a dependency.

## Brief

```markdown
# Product Brief: {Title}

**Date**: {YYYY-MM-DD}
**Source**: {paths or "conversation"}

## Problem
## Vision
## Users and Value
## Key Features
### Essential
### Enhancing
## Constraints
## User Journeys
## Assumptions
```

Omit a section that would only contain filler. Keep Assumptions: it is where anything decided without the user is recorded.

## Spec

```markdown
# Spec: {Title}

**Date**: {YYYY-MM-DD}
**Source**: {brief / discussion / ADR paths, or "conversation"}

## Problem Summary

## Functional Requirements
### Must Have
- **FR1**: {requirement} — AC: {testable criterion} `[unit|feature|integration|browser|manual|user]`
### Should Have
### Could Have
### Won't Have (this iteration)

## Non-Functional Requirements
- **NFR1**: {requirement with a measurable threshold}

## Architecture Decisions
### AD1: {Decision}
{Choice, the alternatives considered, and why. Cite an ADR file if one exists.}

## Scope
### In Scope
### Out of Scope

## Testing Strategy
{Test command, which tags map to which suites, integration boundaries.}

## Assumptions
```

`[browser]` marks a criterion proved only by a rendered page. `[manual]` marks a step `do` performs in the session outside the test suite. `[user]` marks one only the user can prove: a production run, a deploy, a sign-off, a third-party account.

Requirement labels (`FR3`, `NFR2`, `AD1`) are stable identifiers. When amending, add new numbers rather than renumbering.

## Epic

```markdown
# {Epic Name}

**Source spec**: {path, or the brief/discussion path for a 00- epic}
**Date**: {YYYY-MM-DD}
**Status**: Pending
**Blocked by**: —

## {Story Title}
**Story**: {N}
**Status**: Pending
**Blocked by**: —
**Satisfies**: {FR1, NFR2 — omit only for 00- epics}
**Effort**: {low | high — optional}
**Model**: haiku {optional, on a low story only}

**Acceptance Criteria**:
- {criterion} `[tag]`

### {Task Title}
**Task**: {N.1}
**Description**: {what this task covers within the story}
**Status**: Pending

---
```

`**Effort**` is how hard `do` thinks while building the story; a story without one is built at `medium`. `**Model**: haiku` marks a `low` story as a fixed, mechanical edit that a Haiku subagent can make. Neither field changes what the story must deliver or how it is audited.

Stories are numbered from 1 within each epic. Tasks use `{story}.{seq}`. Intra-epic dependencies name stories (`Story 2`); cross-epic dependencies name the epic by filename prefix (`Epic 28-01-epic-setup`).

### Evidence against each criterion

`do` records evidence as an indented line directly under the criterion it proves, never in a separate block:

```markdown
**Acceptance Criteria**:
- {criterion} `[tag]`
  - Evidence: {test name, file:line}{ ({command})} — red: {message} with {lines undone in {file:lines} | mutation of {file:line}: {change}}
- {criterion} `[tag]`
  - Evidence: {proof} — red: n/a — {manual | browser-observed | static | existing (reaches {file:line})}
- {criterion} `[user]`
  - Evidence (user, {YYYY-MM-DD}): {what the user reported} — red: n/a — user
- {criterion} `[tag]`
  - Not met: {what was tried and why it fell short}
- {criterion} `[tag]`
  - Waiting on user: {the steps the user carries out}
```

A test-proven criterion's evidence is incomplete without its red result, or an `existing` reason. `{message}` is the first line of the failure message, or for a multi-line diff the first line that names the expected and actual values. The command is left out when it is the project's test command run on the named test. Each `n/a` reason fits particular tags: `manual` a `[manual]` criterion, `static` a `[manual]` criterion proven by reading code or by `grep` with no test (and an untagged one proven that way), `user` a `[user]` criterion or a criterion whose `Evidence` line is in the `Evidence (user, {YYYY-MM-DD}):` form, which is the only form that carries it, `browser-observed` a `[browser]` criterion checked with claude-in-chrome, and `existing` as the next paragraph defines it. The fit is checked only on tagged criteria; `existing` is judged on every criterion, and its misuse, whatever the tag, is a Warning, not the Critical that an `n/a` reason misfitting its tag is.

`existing`, written `red: n/a — existing (reaches {file:line})`, fits a test-proven criterion (a tag the project's Testing Strategy maps to a suite, or untagged and proved by a test) that keeps behaviour the code already had and names no control. Its test's own body must be unchanged in the story's diff and must have passed in the baseline, and `{file:line}` is a line the story changed that the test executes. A criterion names a control when it is a must-not, must-not-change or never criterion under `plan`'s rule, or its text says `control`. A criterion a test proves takes no other `n/a`. An `existing` reason on a criterion for new behaviour, on one naming a control, on a test whose body the story changed, or naming a line the test does not execute is a finding.

`- Waiting on user:` marks a criterion `do` treats as `[user]` though it is not tagged so (a browser check with no server or browser, a deploy); `do` writes it under that criterion and removes it when it writes the criterion's `Evidence` line.

How a tool reads a story's criteria: a criterion is a `- ` line under `**Acceptance Criteria**:`, continued on indented lines that are not sub-bullets; its tag is the last backticked word in it; its indented `- Evidence`, `- Evidence (user, …)`, `- Not met:` and `- Waiting on user:` lines belong to it; and a legacy story-level `**Evidence**:` field counts as evidence for every criterion of the story.

The criterion line itself is never edited to record verification, so its text stays comparable with coverage matrices and earlier readings. A story is `Complete` only when every criterion has an `Evidence` line; a `Not met` line leaves it blocked. A story that is unblocked, is not marked blocked, and has at least one criterion lacking `Evidence`, every such criterion being `[user]` or treated as `[user]` by `do`, is waiting on the user: it keeps its status, and `do` does not pick it. Read a legacy story-level `**Evidence**:` field as valid input, but don't write one.

### Fields `do` may add to a story

- `**Signal**: {class-slug} — {project | process} — {what failed, one line} ({file and step, rule or check involved})`, also in a `docs/quick/` record; see **Signals**.
- `**Scratch**: {absolute path}` while a red pass runs, naming `{absolute git common dir}/cpm-next/scratch/{epic file stem}-{story}/` (or `quick-{nn}/`), the directory that holds the copies of the files being changed, a `manifest` of the working tree's changed paths with their blob hashes, and a `tree` file naming the checkout the pass runs in; the line and the directory are removed once the files are restored and the manifest compared.
- `**Audit**: pass ({YYYY-MM-DD}){, n findings fixed}` or `**Audit**: skipped — {reason}`, written when the story closes.
- `**Inline change**: {one-line summary} ({YYYY-MM-DD})` for a wording fix with no scope change.
- `**Amended**: {what changed} ({YYYY-MM-DD}) — cited: {file:line | FRn | conflicting criterion}`
- `**Pivot deferred**: {change} → {artefact path} (Story {N}, {YYYY-MM-DD}) — cited: {citation}`

### Fields on the epic header

- `**Lessons**: {lesson reference} (Story {N}), {lesson reference} (build), …` names the library lessons, signals and retro observations that bear on the epic. Optional; omitted when none bears. A lesson reference is one of `{library path} → "{heading, verbatim}"`, `{library path} → amendment {class slug} ({YYYY-MM-DD})`, `{library path} → amendment from {retro path} → "{opening words of the observation}"` (an amendment with no `**Class**`), `{retro path} → "{opening words of the observation}"` or a signal reference. `(Story {N})` marks a lesson a criterion of that story reflects, listed once per such story; `(build)` one about how to build, which no criterion needs.

## Signals

A signal records a failure `do` found, so that the second occurrence can be recognised. It sits on the story, or in the `docs/quick/` record, where the failure happened:

`**Signal**: {class-slug} — {project | process} — {what failed, one line} ({file and step, rule or check involved}){ — recurs: {reference} ({why it matches})}{ — raised {YYYY-MM-DD}}{ — promoted {YYYY-MM-DD}}{ — declined {YYYY-MM-DD}}`

- `project` means the cause is in this codebase; `process` means a cpm-next rule could have prevented it, and the parenthesis then names the cpm-next file and step.
- A class slug is kebab-case and names the kind of failure, not the instance. Reuse a slug already in use, a library lesson's `**Class**` or a seed before making one; use a narrower slug when one class holds two distinct rules. Seeds: `check-cannot-fail`, `shared-state-collision`, `unprovable-in-session`, `instance-not-rule`, `spec-drift`, `fix-not-carried-through`, `definition-in-two-places`.
- A signal reference is `{epic path} → Story {N} → {slug}` or `{quick path} → {slug}`. The `recurs` reference is any lesson reference form under **Fields on the epic header**, or a signal reference.
- `raised` marks a signal listed as a promotion candidate; `promoted` one written to the library; `declined` one the user refused. A signal matching a declined one is declined too.

`do`, `plan` and `review` read library lessons, signals that recur and unretired legacy retro observations. A signal that never recurs is never read as context or reported.

## Retro (legacy)

Retros in `docs/retros/` are legacy input that no skill writes, and `library` defines their format, reads them and marks their observations retired.

## Review

```markdown
# Review: {Epic title, or Epic title — Story N}

**Date**: {YYYY-MM-DD}
**Source**: {epic path}
**Reviewers**: {persona display names}
**Findings**: {n} ({critical} critical, {warning} warnings, {suggestion} suggestions)

## Summary

## Findings
- **[{Critical|Warning|Suggestion}]** {icon} **{persona}**: {finding}
  → Story {N}{, criterion or task}: {what is wrong and why it matters}

## Remediation
- Fixed: {finding} → {what changed in the epic}
- Needs you: {finding} → {the decision it waits on}
- Not acted on: {finding} → {why}
```

Critical means the story can't be built correctly as written. Warning means it can be built but will probably go wrong. Suggestion means it would be better but won't go wrong.

## Library document

```markdown
---
title: {Title}
source: {original path or URL}
added: {YYYY-MM-DD}
last-reviewed: {YYYY-MM-DD}
scope:
  - {scope value}
summary: >
  {two to five sentences of constraints, decisions and rules, written for skills}
---

{source content, unchanged}
```

All six fields are required. Filenames are kebab-case with no number prefix.

`scope` holds v3 skill names, because v3 skills filter the library on them; cpm-next skills read every library document regardless. Choose by what the document constrains:

| The document constrains | Scope values |
|---|---|
| what gets planned: requirements, domain rules, architecture | `discover`, `brief`, `architect`, `spec`, `epics` |
| how code gets written: standards, conventions, API contracts | `do`, `quick`, `review` |
| discussion: team norms, positions to argue from | `party`, `consult` |
| everything: glossaries, domain language, team conventions | `all`, alone |

Combine rows freely; an API contract is usually `spec`, `epics`, `do`.

A lesson reaches the library as an entry in `docs/library/lessons-learned.md`, written by `do` when the user accepts a recurring `project` signal, or by `library learn`; or, when it changes what an existing document says, as an amendment block appended to that document by `library learn`, which `library consolidate` later folds into the body:

```markdown
## Amendment — {YYYY-MM-DD}

**Source**: {signal references, or {retro path} → {Category} → "{observation text, verbatim}"}
**Class**: {slug}

{The rule, how a criterion or check shows it holds, and the layer that owns it; what should change in this document.}
```

`lessons-learned.md` has one front-matter block, titled `Promoted Lessons` (an existing `Promoted Retro Lessons` title stays), whose `scope` is the union of its entries' scopes. Entries are appended and never rewritten:

```markdown
## {Lesson title}
**Promoted**: {YYYY-MM-DD}
**Class**: {slug}
**Source**: {signal references, or {retro path} → {Category} → "{observation text, verbatim}"}
**Scope**: {scope values for this lesson}

{The rule, how a criterion or check shows it holds, and the layer that owns it, written to stand on its own.}
```

Either way, `last-reviewed` in the document's front-matter moves to today. A lesson whose `**Class**` is already in the library and states the same rule is never promoted a second time, confirmed by reading; a lesson with no `**Class**` that describes the same rule counts as a match.

## Amending an existing artefact

Edit in place and add an `**Amended**: {YYYY-MM-DD} — {summary}` line under the header. Never rewrite a `Complete` story's criteria; add a new story for new work instead. When an upstream change alters what a `Pending` story must do, update that story in the same pass.
