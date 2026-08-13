# Restore on Create, and the One-Line Report

**Source spec**: docs/specifications/49-spec-dpm-database-lifecycle.md  
**Date**: 2026-08-13  
**Status**: Pending  
**Blocked by**: 49-01  
**Retro applied**: 42 · Criteria gaps · Applied (no additions needed) — FR6 already carries its own decoy, and the spec names it as one: "the decoy that stops *answers from the dump* passing by returning anything at all". FR10's stdout must-NOT is likewise already present.  
**Retro applied**: 42 · Patterns worth reusing · Applied — AD14's two directions are named separately (creating from the dump is safe automatically, overwriting is not), and the restore path here is deliberately *not* the import sequence 49-04 extracts; conflating them would apply the overwrite protections to a case that has nothing to protect.

The README has said since it was written that `.dpm/dpm.sql` "is what a checkout restores from", and no
code path performs it — `restore()` is reached only from the conflicted-merge path. A fresh clone starts
with an empty database beside a dump full of rows. Now that the database is created lazily, the create is
the natural place to close that.

## Restore from the dump when no database exists
**Story**: 1  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR6, AD14

**Acceptance Criteria**:

- A directory holding `.dpm/dpm.sql` and no database answers a read tool from the dump's rows [integration]
- The same call with no dump present returns an empty result rather than an error — the decoy that stops "answers from the dump" passing by returning anything at all [integration]
- must NOT restore over an existing database: a database holding a distinguishable row keeps it when the dump lacks it [integration]

### Restore-if-missing inside `open()`
**Task**: 1.1  
**Description**: A first open finding no database and a dump beside it restores from that dump; a first open finding a database never touches it, whatever the dump says. This is `restore()` alone, deliberately **not** the staging-file-and-rename sequence 49-04 extracts — AD14's whole argument for making this case automatic is that restoring into nothing can lose nothing, so there is no existing database to protect. Reusing the import sequence here would be harmless and misleading, and the next reader would take the protections as evidence something was at risk.  
**Status**: Pending

### Write tests for Story 1
**Task**: 1.2  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. The decoy is the load-bearing one: a read tool returning rows proves nothing unless the same call over an empty directory returns *empty* rather than the same rows from somewhere else.  
**Status**: Pending

---

## Report the unusual first open in one line on stderr
**Story**: 2  
**Status**: Pending  
**Blocked by**: Story 1  
**Satisfies**: FR10

**Acceptance Criteria**:

- A first open that restored from a dump writes exactly one line to stderr naming the restore; an ordinary create writes none [integration]
- must NOT write any of it to stdout [integration]

### The one-line report
**Task**: 2.1  
**Description**: The unusual cases only — a restore, or a database served read-only. An ordinary create is silent, per the spec's Deferred list, and NFR1's stderr-silence criterion in 49-01 depends on that staying true.  
**Status**: Pending

### Write tests for Story 2
**Task**: 2.2  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. Both halves of the first criterion go in one test — a restore that reports and an ordinary create that does not — because "writes one line" is satisfiable by a server that writes one line every time.  
**Status**: Pending

---

## Notes

**Nothing added beyond the spec.** FR6 carries its own decoy and the spec labels it as one; FR10 carries
the stdout must-NOT. Both are the shape retro 42 asks for, already in the source.

**Step 3c — integration testing story: skipped.** Two stories, sequentially dependent, both already
driven end-to-end over a real server. The epic's boundary — *Server ↔ dump*, "the one place the server
reads a committed artefact" — is Story 1's entire subject and is exercised there rather than by a
cross-story story. The seam this epic shares with 49-01, the lazy `open()` itself, is covered by 49-01's
Story 7.

**Why this is a separate epic from 49-01 despite its size.** It is the only place the server reads a
committed artefact, and it is the requirement that makes the README's long-standing claim true. Folding
it into the deferred-creation epic would put a behaviour change inside an epic whose subject is a
behaviour *removal*, and the two land differently: 49-01 can ship without this and be correct, while this
cannot ship without 49-01 at all.

**FR10's second unusual case is 49-01's.** "A database served read-only" is FR5's version-ahead path,
delivered in 49-01 Story 5. FR10's own criterion names only the restore case, so that is what this epic's
criteria assert; the read-only line is wired here and exercised where the version-ahead gate is.
