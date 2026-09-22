/**
 * Epic 05-07 Story 2 — the guard git invokes is the one in this checkout (ENV3).
 *
 * **The requirement says a suite assertion already pins this. None did.** ENV3 reads *"A suite
 * assertion already pins this and is the only thing standing between a plugin reinstall and a guard
 * gone stale"*, and the nearest thing in the suite — `first-run.test.js`, "must NOT — the run passes
 * against stubs" — resolves the hook of a **fixture** repository it built itself. That is a real and
 * necessary assertion about a fresh project; it says nothing about this one. So this story writes
 * the assertion the requirement believed it was re-running.
 *
 * **Why it matters here and nowhere else.** An ordinary project links its hook at a release under
 * the plugin cache, and that path carries a version: on upgrade the link goes stale and is re-made.
 * This repository is where the guard and the schema it checks are the *same checkout*, three
 * directories apart — so a cache link would go stale against a schema being written beside it. On
 * 2026-08-16 it did: schema 24 landed, this project's database migrated to it, and the 0.5.0 guard
 * refused the commit because it knew 23. Correctly, since a guard cannot project a database newer
 * than itself.
 *
 * The assertion is therefore about a path rather than about behaviour, and it is the one thing
 * standing between a plugin reinstall and a guard that refuses every commit for the wrong reason.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, lstatSync, readFileSync, realpathSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import { join, resolve } from 'node:path';

const PACKAGE = new URL('../', import.meta.url).pathname;

/** The repository root, asked of git rather than assembled from `..`. */
function repositoryRoot() {
  return execFileSync('git', ['rev-parse', '--show-toplevel'], { cwd: PACKAGE })
    .toString().trim();
}

// --- ENV3: the hook git invokes resolves into this working tree ------------------------------------

test('the repository\'s pre-commit hook resolves into this checkout [integration]', () => {
  const root = repositoryRoot();
  const hook = join(root, '.git', 'hooks', 'pre-commit');
  const shipped = resolve(PACKAGE, 'hooks', 'pre-commit');

  // **A missing hook is a failure here rather than a skip.** ENV3 is about *this* repository, where
  // the guard has to be the working tree's; a clone with no hook is a clone where the next commit
  // goes in unchecked. The remedy is the one CLAUDE.md gives, repeated so a red run carries its fix.
  assert.ok(existsSync(hook),
    'there is no .git/hooks/pre-commit — re-make it with:\n'
    + '  ln -sf "$(git rev-parse --show-toplevel)/dpm/hooks/pre-commit" .git/hooks/pre-commit');

  // **Resolved rather than compared as text**, because a relative link, an absolute one and a hard
  // copy all name the same file and only one of them looks like the path.
  assert.equal(realpathSync(hook), realpathSync(shipped),
    `the pre-commit hook resolves to ${realpathSync(hook)}, not to the guard in this checkout`);

  // **And it is a link rather than a copy**, which is the half resolution cannot see: a copy
  // resolves to itself and would pass a comparison against its own path while going stale the
  // moment the guard beside the schema changed.
  assert.equal(lstatSync(hook).isSymbolicLink(), true,
    'the hook is a copy of the guard rather than a link to it, so it will not follow the schema');
});

test('must NOT — the hook resolves into the plugin cache [integration]', () => {
  const resolved = realpathSync(join(repositoryRoot(), '.git', 'hooks', 'pre-commit'));

  // The failure this exists for, stated as the thing it must not be. A cache path carries a
  // version, so a guard reached through one is pinned to a release while the schema it checks moves
  // with the checkout — which is how the 2026-08-16 refusal happened.
  assert.doesNotMatch(resolved, /plugins\/cache/,
    'the hook resolves into the plugin cache, so it will go stale on the next plugin upgrade');

  // Named positively as well, so the assertion cannot pass by the path simply being odd: it is
  // under this package, which is where the schema is.
  assert.ok(resolved.startsWith(realpathSync(PACKAGE)),
    `the hook resolves outside this package, to ${resolved}`);
});

// --- The guard it reaches is the one that knows this schema ----------------------------------------

test('the guard the hook reaches runs this checkout\'s binaries [integration]', () => {
  const guard = readFileSync(resolve(PACKAGE, 'hooks', 'pre-commit'), 'utf8');

  // **The link is half the claim and the script is the other half.** A hook correctly linked into
  // this checkout that then invoked a cached binary would satisfy every assertion above and still
  // check the database against a release rather than against the schema beside it.
  assert.doesNotMatch(guard, /plugins\/cache/,
    'the guard invokes something under the plugin cache');

  // It reaches the guard binary this package ships, by a path derived from its own location.
  assert.match(guard, /dpm-guard\.js/, 'the guard script does not run dpm-guard.js');

  // The control on the reading: the file is the one this repository ships and is not empty, so an
  // absence above is the script's rather than the read's.
  assert.ok(guard.length > 200, `the guard script is ${guard.length} bytes — it was not read`);
});
