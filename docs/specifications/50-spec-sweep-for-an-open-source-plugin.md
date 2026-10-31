# Spec: Sweep for an open-source plugin

**Date**: 2026-10-31  
**Source**: conversation (2026-10-31): "the plugin is open source, so how does sweep work within this context?"

## Problem Summary

`/cpm-next:library sweep` (spec 48, `cpm-next/skills/library/SKILL.md` **Sweep**) reads the `process` signals in the repositories listed in one person's `~/.claude/cpm-next/repos.txt` and, on request, writes a discussion record in the current repository for `/cpm-next:plan`. That serves the plugin's maintainer working in the plugin's own repository. cpm-next is open source, and for anyone else three things go wrong:

1. The discussion record lands in their project, where nothing can act on a fix to the plugin, and nothing helps them send the finding upstream.
2. A `process` signal can name their project's files, code and terms, so sharing a sweep's output as it stands would leak them.
3. A signal does not say which cpm-next version it was seen under (`cpm-next/shared/artifacts.md`, **Signals**), so a report cannot tell a failure a later release fixed from one still open.

The files changed are `cpm-next/shared/artifacts.md`, `cpm-next/skills/do/SKILL.md` (**Signals**), `cpm-next/skills/library/SKILL.md` (**Sweep**), `cpm-next/.claude-plugin/plugin.json`, and a new `cpm-next/shared/fixed.md`.

## Functional Requirements

### Must Have

- **FR1**: A `process` signal records the cpm-next version it was seen under, as ` — cpm-next {version}` after its parenthesis, the version read from the installed plugin's `.claude-plugin/plugin.json`. A `project` signal carries no version. — AC: the contract shows the form and says which signals carry it; `do` **Signals** says to read the version and write it on a `process` signal; control: the contract's `project` form has no version segment `[manual]`
- **FR2**: cpm-next ships `shared/fixed.md`, a table with one row per `process` failure a release fixed: the cpm-next file and step, the class slug, the version that fixed it, and what changed in one line. The maintainer adds a row with each release that fixes one. — AC: the file exists with the columns and seed rows for the process fixes of 0.9.0 to 0.11.0 that name a file and step; the contract's **Where things live** names it `[manual]`
- **FR3**: `sweep` leaves out a group when the fixed list has a row for its file and step (and class, when the row names one) and every signal in the group was seen under an earlier version than that row's; it names such a group as fixed, with the version. A signal with no version counts as not fixed. The report shows the versions each group was seen under. — AC: `library` **Sweep** states the rule, the fixed naming and the versions shown; control: a group with one signal seen at or after the fix version is reported, not left out `[manual]`
- **FR4**: `sweep` decides whether it runs in the plugin's own source repository: one whose root holds `cpm-next/.claude-plugin/plugin.json` naming `cpm-next`. There it keeps offering the discussion record for `/cpm-next:plan`, as now. Anywhere else it offers an issue draft instead, and writes no discussion record. — AC: `library` **Sweep** states the test and both branches `[manual]`
- **FR5**: The issue draft holds, for each reported group: the class slug, the cpm-next file and step, a generic one-line description of the failure, the versions it was seen under, and how many repositories showed it. It holds no repository name or path, no file or symbol from those repositories, no code, and no signal text quoted from them. Its title names the file, the step and the class. — AC: `library` **Sweep** lists what the draft holds and what it never holds; control: it says the description is written afresh from the signals rather than copied from them `[manual]`
- **FR6**: The draft is shown in full for the user to read and change before anything leaves the machine. Filing is a separate, explicit choice in one AskUserQuestion call: file it with `gh issue create` against the repository in the installed plugin's `repository` field, or keep it as text with the URL to open a new issue there. Nothing is filed without that yes; when `gh` is missing or not signed in, the draft and URL are given and nothing is filed. — AC: `library` **Sweep** states the order (show, then ask) and the `gh` command; control: it says nothing is filed in any other case `[manual]`
- **FR7**: cpm-next's `plugin.json` names its source repository in a `repository` field, `https://github.com/ninthspace/claude-code-marketplace`; a fork that changes the field files to itself. — AC: the field is present and `claude plugin validate cpm-next` passes `[manual]`

### Should Have

- **FR8**: The cpm-next README, the root README's CPM Next section, the training guide's sweep passages and `docs/maintenance/README.md` describe the version on `process` signals, the fixed list (including that a release adds rows to it) and the two sweep branches. — AC: each names them `[manual]`

### Won't Have (this iteration)

- Filing without the user's yes, or filing from a `do` run.
- Collecting signals from other people's machines, or any telemetry.
- Versions on `project` signals, or back-filling versions into existing signals.

## Non-Functional Requirements

- **NFR1**: No added sentence in a SKILL.md or the contract records history, per `CLAUDE.md` "A SKILL.md is not a change log".
- **NFR2**: `claude plugin validate cpm-next` passes, and `claude plugin test` still passes for cpm-next, cpm-next-models, cpm-next-progress and whats-next (their parsers ignore `**Signal**` lines; `docs/maintenance/README.md`, "Unknown fields in the mods").

## Architecture Decisions

### AD1: The version rides on the signal line
The version is a segment of the `process` signal's own line, so it survives in any repository and needs no other file; the mods and `status` read `**Signal**:` field lines only for their presence, so an added segment breaks nothing. Rejected: a version on the epic header (an epic can span upgrades).

### AD2: A shipped fixed list, maintained by release
`shared/fixed.md` ships with the plugin, so every install knows what its own version fixed, and a fork keeps its own. Rejected: showing versions only, which reports failures already fixed. User's decision, 2026-10-31.

### AD3: The plugin's repository comes from its manifest
The draft files to the installed plugin's `repository` field, so a fork's users file to the fork. Rejected: a URL written into the skill. User's decision, 2026-10-31.

### AD4: Outside the plugin's repository the draft replaces the discussion record
A discussion record in someone else's project has no reader who can change the plugin; an issue in the plugin's repository does. Filing stays a separate yes, since it publishes to a public site.

## Scope

### In Scope
The files named in the Problem Summary; the READMEs, training guide and maintenance record (FR8); versions: cpm-next 0.12.0, marketplace 4.0.7.

### Out of Scope
The mods; `do`'s routing of signals; telemetry of any kind.

## Testing Strategy

Prose changes are checked by reading the changed file against the requirement, with `grep` for required strings (`[manual]`); `claude plugin validate cpm-next` and `claude plugin test` on the four plugins for NFR2. Behaviour is seen in a live run only through an installed release, in the final user-checks epic, using scratch repositories with planted process signals whose names and paths are distinctive, so a leak shows in the draft.

## Assumptions

- "The plugin's own source repository" is recognised by `cpm-next/.claude-plugin/plugin.json` naming `cpm-next` at the repository root, which is this repository's layout; a fork keeps it.
- The installed version is read from the installed plugin's manifest, two levels above the skill's directory, as `do` already reads the contract from there.
- Seed rows for `shared/fixed.md` come from the cpm-next README's 0.9.0 to 0.11.0 entries that name a file and step; a release without such a fix adds no row.
- A signal written before this change has no version and so is never left out as fixed.
- The generic description is the model's own one line; the user's review of the draft is the guard against a leak it misses, which is why the draft is always shown before the filing question.
- The challenge pass was skipped: the change is three prose sections, a table and a manifest field, with its decisions taken by the user.
