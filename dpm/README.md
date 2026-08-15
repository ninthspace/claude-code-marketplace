# dpm — Data-Modelled Planning Method

SQLite-backed persistence for planning artefacts. Every artefact is a row with typed
columns; every cross-artefact reference is a foreign key. Markdown under `docs/` is a
generated, one-way projection of the database rather than the place the data lives.

Skills write exclusively through typed MCP tools — no skill contains SQL, and nothing in
dpm parses prose.

## Requirements

- **Node 22.5.0 or later.** dpm uses `node:sqlite` from the standard library, so there is
  no native module, no `node-gyp`, and no build step at install time. Below the floor,
  each of dpm's five executables refuses with a message naming the version rather than
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
```

The database itself is not committed — `.dpm/dpm.sql` is its committed text form, and it
is what a checkout restores from. That restore is not a step either: on a fresh clone the
first tool call finds no database, finds the dump beside it, builds one from it, and says
so in a line on stderr. A checkout that already has a database keeps it untouched, whatever
the dump holds — replacing one is a merge, and a merge is something you ask for.
Keeping the binary out of the commit is not a step you
perform: the first tool call writes `.dpm/.gitignore` before it creates the database, so
there is no window in which an unignored `dpm.db` can be staged. Commit that file once and
it reaches every clone. If you already have one, dpm leaves it exactly as it is.

**2. Publish before committing.** The markdown under `docs/` is generated, and nothing
generates it as a side effect of writing. After a skill run that changed anything:

```sh
node <plugin path>/dpm/bin/dpm-publish.js
```

or run `/dpm:publish` if you are already in a session. Then commit — both the projection
and `.dpm/dpm.sql` go in the same commit.

Skip step 2 and the hook refuses the commit and names this command; nothing is lost, and
nothing is written behind you.

## When the guard refuses

The database and `.dpm/dpm.sql` are two forms of the same thing, and they can fall out of
step in three different ways. The guard says which one happened and names the fix — but
each of these is a real command you can run at any time, not only when a commit is
refused, and each discards whatever is only on the side it overwrites. Knowing which is
which before you are standing in front of a refusal is the point of this section.

**The database moved.** You changed something and did not publish. Regenerate both
artefacts:

```sh
node <plugin path>/dpm/bin/dpm-publish.js
```

or `/dpm:publish` if you are already in a session. This is step 2 above, and it is the
common case.

**The dump moved.** You pulled. `.dpm/dpm.sql` arrived rewritten and your database is
behind it. Rebuild the database from the dump:

```sh
node <plugin path>/dpm/bin/dpm-import.js
```

Publishing here would do the opposite of what you want — it regenerates the dump from a
database that is behind it, and everything the pull brought would be gone.

**Both moved.** You pulled onto work you had not published. Neither can be regenerated
from the other without losing whatever is only on the side being overwritten, so the two
have to be reconciled:

```sh
node <plugin path>/dpm/bin/dpm-merge.js
```

Run it during the conflicted `git merge`, from the repository root. It reads git's three
stages of `.dpm/dpm.sql`, merges them row by row, and rebuilds the database from the
result. Where it cannot decide, it stops and says which rows are in question rather than
picking one. Git does not invoke it for you; registering it as a merge driver needs
per-clone configuration and is not something dpm does on your behalf.

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
and it is the command the pre-commit guard names when the refusal is a database that has moved
ahead of its dump. The other two refusals name other fixes; see [When the guard
refuses](#when-the-guard-refuses). In a repository with a CPM corpus still in place, reach for
the skill.

Once the corpus is out of reach, [MIGRATION.md](MIGRATION.md) covers the other half: which of
it, if any, is worth carrying over, and which is finished work that no dpm skill will ever read.

## Status

Under construction — spec `docs/specifications/47-spec-dpm-sqlite-persistence.md`, built
across the epics in `docs/epics/47-*`.

## Licence

MIT
