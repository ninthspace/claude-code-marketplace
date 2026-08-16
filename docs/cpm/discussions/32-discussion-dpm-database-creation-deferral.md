# Discussion: Deferring DPM database creation, ignoring the database, and the pull-import gap

**Date**: 2026-08-13  
**Agents**: Bella

## Discussion Highlights

### Key points so far

- Startup checks: stale-progress guard returned RUN, classifier emitted no records (nothing to surface). Library: only `docs/library/lessons-learned.md`, scope `do` — not in `consult` scope, skipped.
- The creation site is `dpm/src/server/index.js` `main()`: `mkdirSync(dirname(location), {recursive:true})` then `start(location)` — unconditional at launch. `DATABASE = process.env.DPM_DATABASE ?? '.dpm/dpm.db'`, relative to the server's cwd, so every session in any directory gets `.dpm/dpm.db`.
- `start()` (dpm/src/start.js) = openConnection → migrate → applyVocabulary. Creating the file is not the whole cost: it migrates 22 schema files and seeds vocabularies.
- **The real obstacle to laziness**: `spineTools(db)` (dpm/src/tools/index.js:92) runs `SELECT kind FROM document_kind` at *build* time to derive the document tools. So the `tools/list` response currently depends on a migrated, seeded database existing.
- Second wrinkle: the `migrated.ahead` → `readOnlyTools(...)` decision is taken at launch. Deferring the open means deferring that decision to first use.
- DPM ships no hooks.json (only `dpm/hooks/pre-commit`), so nothing else touches the DB at session start — the MCP launch is the sole cause.

### Findings behind the chosen shape

- Build-time DB reads are not one site but ~5: `index.js:92` (`document_kind`), `search.js:47` (`sqlite_schema` → entity vocabulary in the input schema), `list.js:219/222` (kinds + numbering) and `list.js:295/300` (`PRAGMA table_info`/`foreign_key_list` → column lists), `document.js:60/76`, `milestones.js:34`. **Every one reads schema or seeded vocabulary — none reads a user row.** That is what makes a template build sound.
- `src/server/mcp.js:90` declares `capabilities: { tools: { listChanged: false } }`, so the list advertised at launch must stay true for the session. It does: document kinds are **seed-only** (there is `read`/`list`/`preview_document_kind` but no `create_document_kind`), and template and real file both go through the same `start()`, so same plugin version → identical tool list.
- Precedent already in the tree: `src/tools/cross/template.js:132` builds a whole tool set off `start(':memory:')` inside a handler, and the sibling binaries (`src/guard/main.js:63`, `src/publish/main.js:57`) already treat "no database here" as a legitimate state and say "create one, or point DPM_DATABASE at the right path". The MCP server is the only component that creates one unasked.
- Only three tool modules destructure `const { db } = context` at build time (`vocabulary.js:48`, `entity/milestones.js:60`, `spine/detail.js:138`) — relevant if a proxy/getter approach were taken instead of the rebuild.
- Tests that will need to move: `tests/server.test.js` (silent-launch/clean-session assertions), `tests/capability.test.js:162` (spawns `bin/dpm-mcp.js` with `DPM_DATABASE` set and lists tools), `tests/first-run.test.js`.

### Decisions taken

1. **Lazy file, template tool-list.** Migrate a `:memory:` template at launch purely to build the tool table; open/create the real `.dpm/dpm.db` on first tool call, rebuild `spineTools` against it, and apply the `readOnlyTools` version-ahead gate there (it cannot be known before the file is opened). Plumbing: split `methods()` at `mcp.js:81` so `tools/list` describes the template and `tools/call` resolves the live table, with `resolve` defaulting to the same list so every existing `methods(tools)` call site is unchanged. The Node-floor import-graph guard in `server.test.js` is unaffected — the template still goes through `start()`.
2. **First call of any kind creates.** Chris accepted this over a write-only gate: nothing calls a DPM tool automatically (DPM ships no `hooks.json`), so only an agent choosing to would create a database in a stranger's repo. The write-only gate stays available later without redoing the work.
3. **`.dpm/dpm.db` must be ignored always.** Write `.dpm/.gitignore` containing `dpm.db*` — a nested ignore file, so it never edits a file the user owns and travels with `.dpm/dpm.sql` to every clone. Created inside the lazy `open()` before `start(location)`, so the db never exists unignored, and only if absent. `dpm.db*` with the star because WAL/journal siblings are real — `merge/main.js:215` already checks for `.dpm/dpm.db-wal`.
   - Today this is a **manual README step**: `tests/support/git.js:56` and `first-run.test.js:62` write `.gitignore` by hand "performed exactly as it is written there". The README's ignore line should be cut once the server does it; the symlink half of step 1 stands.
   - The pre-commit guard will not object: `orphans()` (`guard/index.js:108`) only considers `docs/{dir}/*.md` whose name carries a seeded kind.
   - **`first-run.test.js:106` needs a line**: it asserts *set equality* on tracked files (`projection + DUMP_PATH + '.gitignore'`), so `.dpm/.gitignore` joins that list as a constant beside `DUMP_PATH`.

### Findings on `dpm.sql` — deferred scope, not yet decided

- **`.dpm/dpm.sql` is written only by a publish.** One implementation, `publish/index.js:74`; three callers by design (AD11): the `publish` MCP tool, `bin/dpm-publish.js`, `/dpm:publish`. Never at start, never by an ordinary write tool. So a non-DPM repo never acquires one.
- **The README describes a restore that does not exist.** README:53–54 says `.dpm/dpm.sql` "is what a checkout restores from", but `restore()` is imported only by `merge/main.js:20` and `merge/index.js:33` — both on the conflicted-merge path. `start()` is openConnection → migrate → seed. So a fresh clone starts with an **empty** database beside a dump full of rows.
- **`dpm-merge` covers the conflict case only, and only manually.** `run()` reads git's three stages via `git ls-files -u` (`merge/main.js:43`), refuses with "not in a conflicted merge" if stages 2/3 are absent, merges row-wise, restores into `.dpm/dpm.db.merging` and renames into place, verifies `dump(db).sql === result.sql`, then publishes and re-guards. **No merge driver is registered anywhere** — no `.gitattributes` in the tree, no mention in README, MIGRATION.md or `hooks/pre-commit`; the README does not mention `dpm-merge` at all. Git never invokes it.
- **The clean pull is the real gap, and it does not fail safe.** A fast-forward updates `.dpm/dpm.sql` and touches nothing else, so the local db is silently stale. The guard then compares `dump(db)` against the file (`guard/index.js:165–168`) and refuses the next commit as `differs`, naming `PUBLISH_COMMAND` (`guard/index.js:46` = `bin/dpm-publish.js`) as the fix — which regenerates `dpm.sql` **from the stale local db**, discarding the pulled rows and their projection.
- **Two distinct triggers, one seam.** "Restore when the db is missing" (clone) is not the same as "reimport when the dump has moved ahead of the db" (pull). The lazy `open()` is the natural home for both, but the pull case also needs the guard to stop recommending publish when the dump is ahead.

### Open question carried into the spec

Scope. Decisions 1–3 are one story's worth (server entry, `mcp.js` method table, three test files, README). The `dpm.sql` findings — restore-on-first-open, reimport-on-pull, and the guard's misleading fix — are separate requirements with their own failure modes (corrupt dump, stale-db-vs-newer-dump, which side wins when local rows are uncommitted). Bella flagged them rather than folding them in; Chris took the whole thing to `/cpm:spec` rather than a `/dpm:quick`, on the grounds that what happens to local rows when the dump moves ahead is a decision, not an implementation detail.
