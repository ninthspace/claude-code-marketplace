# dpm — Data-Modelled Planning Method

SQLite-backed persistence for planning artefacts. Every artefact is a row with typed
columns; every cross-artefact reference is a foreign key. Markdown under `docs/` is a
generated, one-way projection of the database rather than the place the data lives.

Skills write exclusively through typed MCP tools — no skill contains SQL, and nothing in
dpm parses prose.

## Requirements

- **Node 22.5.0 or later.** dpm uses `node:sqlite` from the standard library, so there is
  no native module, no `node-gyp`, and no build step at install time. Below the floor,
  each of dpm's four executables refuses with a message naming the version rather than
  failing on a missing module.

## Installation

Inside Claude Code:

```
/plugin marketplace add ninthspace/claude-code-marketplace
/plugin install dpm@ninthspace-marketplace
```

The suffix is the marketplace's name rather than the repository's — they differ, and only
the former resolves.

To work on dpm itself, clone the repository and add the clone as a marketplace instead, so
the plugin points at your working tree rather than a cached copy:

```sh
git clone git@github.com:ninthspace/claude-code-marketplace.git
```

then `/plugin marketplace add <path to the clone>`.

Installing registers the MCP server, so the tools and skills are available immediately.
There is nothing to compile either way.

## First run

Two steps, in a repository dpm is going to keep planning artefacts in.

**1. Install the pre-commit hook.** It regenerates both artefacts and refuses a commit
that disagrees with the database. From the repository root:

```sh
ln -s ../../<plugin path>/dpm/hooks/pre-commit .git/hooks/pre-commit
echo '.dpm/dpm.db*' >> .gitignore
```

The database itself is not committed — `.dpm/dpm.sql` is its committed text form, and it
is what a checkout restores from.

**2. Publish before committing.** The markdown under `docs/` is generated, and nothing
generates it as a side effect of writing. After a skill run that changed anything:

```sh
node <plugin path>/dpm/bin/dpm-publish.js
```

or run `/dpm:publish` if you are already in a session. Then commit — both the projection
and `.dpm/dpm.sql` go in the same commit.

Skip step 2 and the hook refuses the commit and names this command; nothing is lost, and
nothing is written behind you.

## Coming from CPM

**There is no importer, and that is a decision rather than a gap** (AD8). dpm never reads a
CPM `docs/` tree. New and existing projects alike begin with a blank database, so a project
adopting dpm carries none of its history across — the artefacts stay exactly where they are,
as CPM's files, and dpm neither converts nor repairs them.

**But dpm will offer to delete some of them, so move them out of the way first.** The
projection reclaims a file it did not write when the name carries one of dpm's *own kind names*
in the position the renderer puts it — `-spec-`, `-epic-`, and so on — inside the directory that
kind is mapped to. Whether that catches a given CPM directory comes down to whether the two
systems happen to use the same word for the same kind of document: `spec` and `spec` collide,
`plan` and `problem_brief` do not.

**Move all twelve regardless.** The ones that are safe are safe by coincidence of vocabulary,
and renaming a single kind in a later version moves a directory from one column to the other
with nothing to announce it. Sorting them is work that has to be redone every release, and
being wrong costs files.

Only those twelve are walked, and only one level deep, so `docs/cpm/` is permanently out of
reach and stays readable:

```sh
mkdir -p docs/cpm
git mv docs/plans docs/briefs docs/specifications docs/epics docs/retros docs/quick \
       docs/discussions docs/communications docs/reviews docs/audits docs/runbooks \
       docs/library docs/cpm/   # drop any you do not have
```

`docs/architecture/` is not on that list because it is never walked at all: dpm renders an ADR
inside the document that raised it and has no directory for the kind. Leave your ADRs where
they are.

A walked directory is still safe for files the rule cannot mistake for its own: a hand-kept
`docs/epics/README.md` is never a candidate.

**Preview before the first publish either way.** `/dpm:publish` lists every removal and asks
before it removes anything. `bin/dpm-publish.js` does not — it is the non-interactive form,
and it is also the command the pre-commit guard names when it refuses a commit. In a
repository with a CPM corpus still in place, reach for the skill.

Once the corpus is out of reach, [MIGRATION.md](MIGRATION.md) covers the other half: which of
it, if any, is worth carrying over, and which is finished work that no dpm skill will ever read.

## Status

Under construction — spec `docs/specifications/47-spec-dpm-sqlite-persistence.md`, built
across the epics in `docs/epics/47-*`.

## Licence

MIT
