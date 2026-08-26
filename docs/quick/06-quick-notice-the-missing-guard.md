# A guard that has gone missing is silent, so the server says it on the way past

**Number**: 06  
**Status**: complete — Delivered. Prompted by this repository's own guard link having gone missing unnoticed.  

**Closed**: 2026-08-26T13:05:00.000Z  

## The change

The pre-commit guard is a symlink the user makes once per repository, and `.git/hooks/` is not tracked — so it does not survive a re-clone, a fresh `git init`, or anything that rewrites that directory. Its two failure modes are not alike. A link into an older release refuses the next commit and names the release it ran from, so it reports itself. A link that is gone reports nothing: git skips a hook it cannot find without a warning and without failing the commit, so an unguarded repository and a guarded one are indistinguishable from outside.

Documentation only reaches a reader who remembers to look. The first tool call of a session is the one piece of dpm that runs in the repository, unasked, on its way to the database — so it is the only place the absence can surface without being sought.

It warns on absence and on nothing else. A hook that exists and is not dpm's may well be dispatching to dpm, and a warning firing every session on a correctly configured repository is one the reader learns to skip, taking the true ones with it.

## Files affected

- `dpm/src/server/hook-check.js` — new; `unguardedMessage(directory)` returns one line or `null`.
- `dpm/src/server/index.js` — a fifth injected seam on `open()`, consulted between the ignore write and the restore.
- `dpm/tests/hook-check.test.js` — new; seven tests, five of them a silence paired with its control.
- `dpm/README.md`, `README.md` — the two failure modes separated, the shell functions, and the exception for a checkout that develops DPM.

## A defect the suite caught immediately

The walk up from the database directory looking for `.git` did not terminate on a relative path, and the default location is repository-relative. `parse('.dpm').root` is the empty string, `dirname('.')` is `'.'`, and the loop had no other stopping condition — so every integration test in the suite hung, each spawning a server that opens a database by the default path.

Found in one run because the whole suite stopped rather than one test failing. The fix is one `resolve()`, and the reason it is written down in the source is that a reader tidying the path handling would remove the line that ends the loop. There is now a test whose subject is that the call returns at all.

## Acceptance Criteria

| Met | Criterion | Note |
| --- | --- | --- |
| ✓ | A session opening a database inside a repository with no `.git/hooks/pre-commit` writes one line to stderr saying so. | `unguardedMessage()` runs between the ignore write and the restore, on the same `log` channel and the same terms as the restore report. Asserted through the open by capturing `process.stderr.write`, not by trusting the seam was consulted. |
| ✓ | A repository that has a hook is silent, and so is every state where `.git/hooks/` is not the question. | Four silences — a hook present, no repository above, `.git` a file rather than a directory (a linked worktree), and `core.hooksPath` set — each asserted beside a control that turns it back into a sentence. Without the controls a function returning `null` unconditionally passes all four. |
| ✓ | A dangling symlink is reported as one, rather than as an absence. | `existsSync` follows the link so both reach the same branch; `lstatSync` distinguishes them for the message. They are different fixes — `ln -sf` against `ln -s` — and the README sends the two readers to different lines. |
| ✓ | Nothing is warned about that dpm cannot be sure of. | A `pre-commit` that exists and is not dpm's may be dispatching to dpm — the `pre-commit` framework holds its entry in `.pre-commit-config.yaml`, and the README's wrapper form `exec`s the guard from a script of the user's own. The check answers only "is there a hook at all", which is the only question available without guessing. |
| ✓ | The observing server does not warn. | The check sits below the read-only early return, alongside the other four things that branch skips. An observer opening a project it does not own has no business reporting on that project's hooks. |
| ✓ | The documentation says what to run and when. | Both READMEs now separate the two failures — a stale link refuses and names itself, a missing one is silent — and `dpm/README.md` carries the two shell functions, with a warning that they must not be used in a checkout that develops DPM. |
| ✓ | `node --test` stays green across the whole DPM suite. | 828 tests, 828 passing. |
