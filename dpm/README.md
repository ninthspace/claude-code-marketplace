# dpm — Database Planning Method

SQLite-backed persistence for planning artefacts. Every artefact is a row with typed
columns; every cross-artefact reference is a foreign key. Markdown under `docs/` is a
generated, one-way projection of the database rather than the place the data lives.

Skills write exclusively through typed MCP tools — no skill contains SQL, and nothing in
dpm parses prose.

## Requirements

- **Node 22.5.0 or later.** dpm uses `node:sqlite` from the standard library, so there is
  no native module, no `node-gyp`, and no build step at install time.

Installs by clone or marketplace fetch. Nothing needs compiling.

## Status

Under construction — spec `docs/specifications/47-spec-dpm-sqlite-persistence.md`, built
across the epics in `docs/epics/47-*`.

## Licence

MIT
