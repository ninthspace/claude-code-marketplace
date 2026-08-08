/**
 * Story 0 — the two criteria about how dpm installs and how its suite runs:
 *
 * - "The whole suite runs from one command that needs no install step and no compiled
 *   dependency" [integration]
 * - "must NOT — a dependency is added whose install requires compilation" [unit]
 *
 * The must-NOT is asserted at the strongest point available: not "no dependency needing
 * compilation" but **no dependency at all**, plus every import under `dpm/` resolving to a
 * Node builtin or a file in this tree. A rule stated as "nothing non-stdlib is imported"
 * fails the moment a package arrives, whichever kind it is, and needs no list of which
 * packages compile.
 *
 * The remaining criterion — "`dpm/` is installable from the marketplace manifest as a plugin
 * alongside `cpm/`, with no build step" — is `[target]`: it needs a real install to assess,
 * and nothing here claims it. What is checked below is the half that can be: that the two
 * manifests describe the same plugin and that no build step exists to run.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readdirSync, readFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { javascriptFilesUnder } from './support/sources.js';

const DPM = join(import.meta.dirname, '..');
const REPOSITORY = join(DPM, '..');

const json = (path) => JSON.parse(readFileSync(path, 'utf8'));

const packageManifest = json(join(DPM, 'package.json'));
const pluginManifest = json(join(DPM, '.claude-plugin', 'plugin.json'));
const marketplace = json(join(REPOSITORY, '.claude-plugin', 'marketplace.json'));

/** Every `.js` file dpm ships, tests included. */
const sourceFiles = () => javascriptFilesUnder(DPM);

/** Module specifiers named in a source file, from static imports, dynamic ones and require. */
function importedSpecifiers(source) {
  const patterns = [
    /(?:^|\s)(?:import|export)[^'"]*?from\s*['"]([^'"]+)['"]/g,
    /(?:^|\s)import\s*['"]([^'"]+)['"]/g,
    /\bimport\s*\(\s*['"]([^'"]+)['"]\s*\)/g,
    /\brequire\s*\(\s*['"]([^'"]+)['"]\s*\)/g,
  ];
  return patterns.flatMap((pattern) => [...source.matchAll(pattern)].map((match) => match[1]));
}

test('the plugin manifest and the marketplace entry describe the same plugin', () => {
  const entry = marketplace.plugins.find((plugin) => plugin.name === 'dpm');

  assert.ok(entry, 'dpm is listed in the marketplace manifest, alongside cpm');
  assert.ok(
    marketplace.plugins.some((plugin) => plugin.name === 'cpm'),
    'and cpm is still listed — the two are siblings in one repository, which is what the ' +
      "spec's Testing Strategy relies on for the FR25 name oracle",
  );

  assert.equal(entry.source, './dpm');
  assert.equal(entry.description, pluginManifest.description);
  assert.equal(entry.version, pluginManifest.version);
  assert.equal(pluginManifest.version, packageManifest.version);
  assert.ok(existsSync(join(REPOSITORY, entry.source.slice(2))), 'the source path exists');
});

test('dpm declares no dependencies of any kind', () => {
  assert.deepEqual(packageManifest.dependencies, {});
  assert.deepEqual(packageManifest.devDependencies, {});

  for (const field of ['peerDependencies', 'optionalDependencies', 'bundledDependencies']) {
    assert.equal(packageManifest[field], undefined, `${field} is absent, not merely empty`);
  }

  assert.equal(existsSync(join(DPM, 'node_modules')), false, 'nothing has been installed');
  for (const lockfile of ['package-lock.json', 'npm-shrinkwrap.json', 'yarn.lock', 'pnpm-lock.yaml']) {
    assert.equal(existsSync(join(DPM, lockfile)), false, `no ${lockfile} — there is nothing to lock`);
  }
});

test('there is no install step and nothing to compile', () => {
  for (const script of ['preinstall', 'install', 'postinstall', 'prepare', 'prepublish', 'build']) {
    assert.equal(
      packageManifest.scripts?.[script],
      undefined,
      `no ${script} script — installing dpm runs nothing`,
    );
  }

  assert.equal(existsSync(join(DPM, 'binding.gyp')), false, 'no node-gyp build description');

  const compiled = [];
  for (const entry of readdirSync(DPM, { recursive: true })) {
    if (String(entry).endsWith('.node')) compiled.push(entry);
  }
  assert.deepEqual(compiled, [], 'no prebuilt native binary is shipped');
});

test('every import under dpm resolves to a Node builtin or to this tree', () => {
  const files = sourceFiles();
  assert.ok(files.length > 0, 'the check found sources to read');

  const external = [];
  for (const path of files) {
    for (const specifier of importedSpecifiers(readFileSync(path, 'utf8'))) {
      const isBuiltin = specifier.startsWith('node:');
      const isLocal = specifier.startsWith('.') || specifier.startsWith('/');
      if (!isBuiltin && !isLocal) external.push({ file: path.slice(DPM.length + 1), specifier });
    }
  }

  assert.deepEqual(
    external,
    [],
    'a bare specifier is a package, and a package is an install step — whether or not it compiles',
  );
});

test('the suite runs from one command, and it is a plain node --test invocation', () => {
  assert.equal(packageManifest.scripts.test, 'node --test');

  // The command has to reach every test file. `node --test` recurses from the working
  // directory, so the check is that no test file sits outside the tree it walks.
  const testFiles = sourceFiles().filter((path) => path.endsWith('.test.js'));
  assert.ok(testFiles.length > 0, 'there are test files for the command to find');
  for (const path of testFiles) {
    assert.ok(path.startsWith(DPM), `${path} is inside dpm/, so one run reaches it`);
  }
});

test('the running Node meets the floor the manifest declares', () => {
  const floor = packageManifest.engines.node;
  assert.match(floor, /^>=\d+\.\d+\.\d+$/, 'the floor is stated as a minimum version');

  const parse = (version) => version.replace(/^>=/, '').split('.').map(Number);
  const [wantMajor, wantMinor, wantPatch] = parse(floor);
  const [haveMajor, haveMinor, havePatch] = parse(process.versions.node);

  const meets =
    haveMajor > wantMajor ||
    (haveMajor === wantMajor &&
      (haveMinor > wantMinor || (haveMinor === wantMinor && havePatch >= wantPatch)));

  assert.ok(meets, `node ${process.versions.node} is below the declared floor ${floor}`);
});
