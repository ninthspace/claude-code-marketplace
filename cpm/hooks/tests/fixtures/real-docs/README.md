# `real-docs` — a frozen corpus of real planning documents

Five documents copied verbatim out of this repository's own `docs/` tree, laid out under a
`docs/` root of their own so that the relative paths they record — a matrix's
`**Source spec**:` field, most of all — resolve within the fixture.

## Why these are copies rather than the live documents

The suites that read them are asserting faithfulness to *documents that were not written to
be read by a test*. A constructed fixture cannot stand in for that: it is built to the
parser's shape, so it says nothing about whether the parser is correct about anything but
shapes it was handed. That argument is sound, and it is why these are real documents.

What does not follow is that the test should read the document *where the project happens
to be keeping it today*. `/cpm:archive` moves a delivered chain under `docs/archive/`, and
a suite pinned to `docs/specifications/` then fails — or worse, goes quietly vacuous when
the directory it globs is empty. The status of a planning document is a project-management
fact. It changes for reasons that have nothing to do with the parser, and a test that moves
with it is measuring the wrong thing.

So the document is real and the location is the test's own. Nothing here depends on what is
live, what is archived, or on any back-reference resolving outside this directory.

## Refreshing

Every document here is archived upstream, which is to say frozen — an archived chain is
terminal, so these copies do not drift. Refresh one only when the suite reading it needs a
shape the current copy does not carry, and refresh it by copying the document again rather
than by editing it here: an edited copy is a constructed fixture wearing a real document's
name, which is the one thing this directory exists not to be.

The whole-repository baseline is a separate mechanism and is *not* here — see
`../coverage-baseline-46.tsv` and `../../make-coverage-baseline.sh`, which sweep every spec
in the project, live and archived alike, by the design spec 46 NFR1 sets out.
