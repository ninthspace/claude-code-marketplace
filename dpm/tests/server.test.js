/**
 * Story 1 — the server starts, states its floor, and keeps stdout to itself.
 *
 * Two of the three criteria are about what does *not* appear: no stray output on stdout, and no
 * crash-instead-of-message below the Node floor. Both are absences, and an absence is what a
 * broken check always reports — so each is paired here with the positive control that makes it
 * fail. The floor refusal is driven through a real spawned process rather than asserted against
 * the function alone, because what NFR2 promises is the behaviour of the *binary*.
 *
 * NFR1 — "a clean clone starts the server with no compilation step" — is `[target]` and is not
 * closed here. What is checked is the part a machine that already has the tree can honestly
 * check: that no dependency exists to install and no build output is required to run.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { Readable, Writable } from 'node:stream';
import { serve } from '../src/server/index.js';
import { dispatch, methods, negotiate, PREFERRED_PROTOCOL, SUPPORTED_PROTOCOLS } from '../src/server/mcp.js';
import { takeLines } from '../src/server/transport.js';
import { assertNodeFloor, floorMessage, meetsFloor, REQUIRED_NODE } from '../src/server/node-floor.js';
import { filterWarnings, isSqliteExperimental } from '../src/server/warnings.js';
import { javascriptFilesUnder } from './support/sources.js';
import { openPlanningDatabase } from './support/planning-database.js';
import { spineTools } from '../src/tools/index.js';

/**
 * Run a script to completion, writing `input` to its stdin and closing it.
 *
 * `execFile` has no `input` option — that belongs to `execFileSync` — and passing one is
 * silently ignored, so the child waits on a stdin that never closes and the test hangs rather
 * than failing. Spawning and ending the stream explicitly is what makes the server see EOF.
 *
 * @param {string[]} args
 * @param {string} [input]
 * @returns {Promise<{code: number, stdout: string, stderr: string}>}
 */
function runNode(args, input = '', env = {}) {
  return new Promise((resolve, reject) => {
    const child = spawn(process.execPath, args, {
      stdio: ['pipe', 'pipe', 'pipe'],
      env: { ...process.env, ...env },
    });

    let stdout = '';
    let stderr = '';

    child.stdout.on('data', (chunk) => {
      stdout += chunk;
    });
    child.stderr.on('data', (chunk) => {
      stderr += chunk;
    });

    child.on('error', reject);
    child.on('close', (code) => resolve({ code, stdout, stderr }));

    child.stdin.end(input);
  });
}

const ROOT = join(import.meta.dirname, '..');
const BIN = join(ROOT, 'bin', 'dpm-mcp.js');

/** Collects everything written, so a test can read the whole stream rather than sample it. */
function capture() {
  const chunks = [];

  return {
    stream: new Writable({
      write(chunk, encoding, done) {
        chunks.push(chunk.toString());
        done();
      },
    }),
    get lines() {
      return chunks.join('').split('\n').filter((line) => line !== '');
    },
  };
}

/** Run a whole session through the real loop and hand back what reached stdout. */
async function session(messages, tools = []) {
  const output = capture();
  const input = Readable.from([`${messages.map((m) => JSON.stringify(m)).join('\n')}\n`]);

  const { handled } = await serve({ input, output: output.stream, tools });

  return { handled, lines: output.lines, replies: output.lines.map((line) => JSON.parse(line)) };
}

const HELLO = {
  jsonrpc: '2.0',
  id: 1,
  method: 'initialize',
  params: { protocolVersion: PREFERRED_PROTOCOL, capabilities: {}, clientInfo: { name: 't', version: '1' } },
};

// --- The Node floor ----------------------------------------------------------------------------

test('the floor compares versions numerically, not as strings', () => {
  assert.equal(meetsFloor('22.5.0'), true, 'the floor itself clears the floor');
  assert.equal(meetsFloor('22.4.9'), false);
  assert.equal(meetsFloor('21.99.99'), false, 'a high minor under a low major is still under');

  // The case a lexicographic comparison gets backwards: '22.10.0' < '22.5.0' as text.
  assert.equal(meetsFloor('22.10.0'), true);
  assert.equal(meetsFloor('22.9.0'), true);

  assert.equal(meetsFloor('23.0.0-nightly20260101'), true, 'a prerelease is judged on its numbers');
  assert.equal(meetsFloor('v22.5.0'), true, 'a leading v is tolerated');
});

test('an unreadable version is not treated as a version that passes', () => {
  for (const version of ['', 'garbage', 'x.y.z', undefined, null]) {
    assert.equal(meetsFloor(version), false, `${version} must not read as above the floor`);
  }
});

test('the refusal names both the required version and the one in use', () => {
  const message = floorMessage('20.11.0');

  assert.match(message, /20\.11\.0/, 'the version in use');
  assert.match(message, new RegExp(REQUIRED_NODE.replaceAll('.', '\\.')), 'the version required');
  assert.match(message, /node:sqlite/, 'and why, so the user can judge the upgrade');

  assert.throws(() => assertNodeFloor('20.11.0'), /requires Node >=22\.5\.0/);
  assert.doesNotThrow(() => assertNodeFloor(REQUIRED_NODE), 'the control: at the floor it proceeds');
});

test('package.json states the same floor the code enforces', () => {
  const manifest = JSON.parse(readFileSync(join(ROOT, 'package.json'), 'utf8'));

  // Two copies of one number, which is the drift this project keeps finding. The test is what
  // makes them one fact.
  assert.equal(manifest.engines.node, `>=${REQUIRED_NODE}`);
});

test('the entry point refuses to start below its floor, as a process', async (t) => {
  // A fixture that differs from `bin/dpm-mcp.js` in one constant — the floor it demands — so
  // the refusal path is exercised through a real process on a machine that is above the real
  // floor. Asserting `assertNodeFloor` alone would leave untested the part NFR2 is about:
  // that the binary exits, says why, and says it on stderr.
  const impossible = '999.0.0';
  const fixture = join(ROOT, 'tests', 'fixtures', 'floor-entry.mjs');

  const refused = await runNode([fixture, impossible]);

  assert.equal(refused.code, 1, 'the process exited non-zero');
  assert.match(refused.stderr, /requires Node >=999\.0\.0/, 'and named the version it wanted');
  assert.equal(refused.stdout, '', 'nothing reached stdout — it is the transport, even on failure');

  // The control: the same fixture, above its floor, starts. Without it this test passes against
  // an entry point that refuses unconditionally.
  const started = await runNode([fixture, '0.0.1']);

  assert.equal(started.code, 0);
  assert.equal(started.stdout, 'started\n');
});

// --- Stdout carries JSON-RPC and nothing else ---------------------------------------------------

test('a full session leaves nothing but well-formed JSON-RPC on stdout', async () => {
  const { lines, replies } = await session([
    HELLO,
    { jsonrpc: '2.0', method: 'notifications/initialized' },
    { jsonrpc: '2.0', id: 2, method: 'tools/list' },
    { jsonrpc: '2.0', id: 3, method: 'ping' },
  ]);

  for (const line of lines) {
    const parsed = JSON.parse(line);
    assert.equal(parsed.jsonrpc, '2.0', line);
    assert.ok(Object.hasOwn(parsed, 'result') || Object.hasOwn(parsed, 'error'), line);
  }

  assert.deepEqual(replies.map((reply) => reply.id), [1, 2, 3]);
});

test('a notification is answered with nothing at all', async () => {
  const { handled, lines } = await session([
    HELLO,
    { jsonrpc: '2.0', method: 'notifications/initialized' },
    { jsonrpc: '2.0', method: 'notifications/anything/else' },
  ]);

  // Three messages in, one reply out. Answering a notification is well-formed JSON and a
  // protocol violation, and `notifications/initialized` arrives in every real session — so a
  // server that replied would put a stray message on stdout every time.
  assert.equal(handled, 3);
  assert.equal(lines.length, 1, 'only the request was answered');
  assert.equal(JSON.parse(lines[0]).id, 1);
});

test('an unparseable line becomes a parse error on stdout and a diagnostic on stderr', async () => {
  const output = capture();
  const input = Readable.from(['not json at all\n{"jsonrpc":"2.0","id":7,"method":"ping"}\n']);

  await serve({ input, output: output.stream });

  const replies = output.lines.map((line) => JSON.parse(line));

  // The bad line does not take the stream down with it — the request after it is still served,
  // which is the whole reason the transport reports parse failures rather than throwing.
  assert.deepEqual(
    replies.map((reply) => [reply.id, reply.error?.code ?? null]),
    [[null, -32700], [7, null]],
  );
});

test('an unknown method and an unknown tool are errors, not silence', async () => {
  const { replies } = await session([
    { jsonrpc: '2.0', id: 1, method: 'no/such/method' },
    { jsonrpc: '2.0', id: 2, method: 'tools/call', params: { name: 'dpm_not_a_tool' } },
  ]);

  assert.equal(replies[0].error.code, -32601);
  assert.equal(replies[0].error.data.method, 'no/such/method');
  assert.equal(replies[1].error.code, -32601);
  assert.match(replies[1].error.data.message, /dpm_not_a_tool/);
});

test('a tool that throws becomes an error response rather than stopping the server', async () => {
  const { replies } = await session(
    [
      { jsonrpc: '2.0', id: 1, method: 'tools/call', params: { name: 'dpm_explodes', arguments: {} } },
      { jsonrpc: '2.0', id: 2, method: 'ping' },
    ],
    [
      {
        name: 'dpm_explodes',
        description: 'throws',
        inputSchema: { type: 'object', properties: {} },
        handler: () => {
          throw new Error('the tool failed');
        },
      },
    ],
  );

  assert.equal(replies[0].error.code, -32603);
  assert.match(replies[0].error.data.message, /the tool failed/);
  assert.deepEqual(replies[1].result, {}, 'and the session continues');
});

test('the real binary serves a session over real pipes', async (t) => {
  const messages = [
    JSON.stringify(HELLO),
    JSON.stringify({ jsonrpc: '2.0', method: 'notifications/initialized' }),
    JSON.stringify({ jsonrpc: '2.0', id: 2, method: 'tools/list' }),
  ].join('\n');

  // The loop is driven over streams everywhere else in this file; this is the one test that
  // proves the entry point wires the process's actual stdin and stdout to it.
  //
  // `:memory:` because the entry point otherwise creates `.dpm/dpm.db` wherever it is launched
  // from — which for a test run is the repository root. It did, once, before this was passed.
  const { stdout, stderr, code } = await runNode([BIN], `${messages}\n`, {
    DPM_DATABASE: ':memory:',
  });

  assert.equal(code, 0, 'and it exits cleanly when stdin closes');

  const lines = stdout.split('\n').filter((line) => line !== '');
  assert.equal(lines.length, 2);
  assert.equal(JSON.parse(lines[0]).result.serverInfo.name, 'dpm');

  // Story 1 asserted this list was empty, which was true and is no longer: the entry point now
  // opens a database and registers the spine. What is checked is that the real binary reaches
  // the *same* registry the in-process tests use — the names are derived from it, never restated
  // — because a binary serving a different tool set from the one under test is the failure this
  // test exists to catch.
  const served = JSON.parse(lines[1]).result.tools.map((tool) => tool.name).sort();
  const registered = spineTools(openPlanningDatabase(t)).map((tool) => tool.name).sort();

  assert.ok(registered.length > 0, 'and the registry it is compared against is not empty');
  assert.deepEqual(served, registered);

  assert.equal(stderr, '', 'a clean session says nothing on stderr either');
});

// --- The hoisting hazard the entry point is shaped around ---------------------------------------

test('nothing the entry point imports statically reaches node:sqlite', () => {
  // The floor check exists to replace `ERR_UNKNOWN_BUILTIN_MODULE` with a sentence. It can only
  // do that if it runs first — and ES imports are evaluated before any statement in the file
  // that wrote them, so a single static import reaching `node:sqlite` moves the crash *before*
  // the check and silently un-implements NFR2. Nothing about the source would look wrong.
  const staticImports = (source) =>
    [...source.matchAll(/^\s*import\s[^;]*?from\s+['"]([^'"]+)['"]/gm)].map((match) => match[1]);

  const seen = new Set();
  const reaches = (file) => {
    if (seen.has(file)) return [];
    seen.add(file);

    const source = readFileSync(file, 'utf8');
    const found = [];

    for (const specifier of staticImports(source)) {
      if (specifier === 'node:sqlite') found.push(`${file} imports node:sqlite`);
      if (!specifier.startsWith('.')) continue;

      found.push(...reaches(join(file, '..', specifier)));
    }

    return found;
  };

  assert.deepEqual(reaches(BIN), []);

  // The control: the walker must be able to find one, or its empty answer means nothing. The
  // connection module is where `node:sqlite` legitimately lives.
  assert.deepEqual(reaches(join(ROOT, 'src', 'db', 'connection.js')), [
    `${join(ROOT, 'src', 'db', 'connection.js')} imports node:sqlite`,
  ]);
});

// The name must not end on the bare word `import` before the closing quote: `plugin.test.js`'s
// specifier scan is textual, and `import '…'` in prose reads to it as a real bare specifier.
test('the entry point reaches the server through a dynamic import, not a hoisted one', () => {
  const source = readFileSync(BIN, 'utf8');

  // **This is the assertion with teeth today, and the one above is the one with teeth later.**
  // `src/server/` does not reach `node:sqlite` yet — no tool touches the database until Story 2
  // — so the graph walk currently finds nothing whichever way this file is written, and adding
  // a static `import … from '../src/server/index.js'` passes it. That was mutation-tested and
  // slipped through. What cannot slip through is the shape itself: the server must arrive by
  // `await import`, because that is what defers evaluation until after the floor check, and it
  // has to be true *now* so it is still true when the graph fills in.
  assert.match(source, /await import\(\s*['"]\.\.\/src\/server\/index\.js['"]\s*\)/);

  const staticSpecifiers = [...source.matchAll(/^\s*import\s[^;]*?from\s+['"]([^'"]+)['"]/gm)]
    .map((match) => match[1]);

  assert.deepEqual(
    staticSpecifiers,
    ['../src/server/node-floor.js', '../src/server/warnings.js'],
    'only the two modules that must run before the floor check are imported statically',
  );
});

test('dpm has no dependency to install, which is the checkable half of NFR1', () => {
  const manifest = JSON.parse(readFileSync(join(ROOT, 'package.json'), 'utf8'));

  // NFR1's criterion is `[target]` — only a clean clone on a real host can close it. What can
  // be checked here is that there is nothing to install and nothing to build: no dependency
  // means no `npm install`, which is the step AD5 rejected Python for needing.
  assert.deepEqual(manifest.dependencies ?? {}, {});
  assert.deepEqual(manifest.devDependencies ?? {}, {});
  assert.equal(manifest.scripts?.build, undefined, 'and no build script to forget to run');

  const external = javascriptFilesUnder(join(ROOT, 'src'))
    .flatMap((file) =>
      [...readFileSync(file, 'utf8').matchAll(/from\s+['"]([^'".][^'"]*)['"]/g)]
        .map((match) => match[1])
        .filter((specifier) => !specifier.startsWith('node:'))
        .map((specifier) => `${file} imports ${specifier}`),
    );

  assert.deepEqual(external, [], 'and no source file imports anything but Node built-ins');
});

// --- The pieces, directly -----------------------------------------------------------------------

test('protocol negotiation echoes a version it knows and offers its own otherwise', () => {
  for (const version of SUPPORTED_PROTOCOLS) {
    assert.equal(negotiate(version), version, 'a supported version is echoed, not overridden');
  }

  assert.equal(negotiate('1999-01-01'), PREFERRED_PROTOCOL);
  assert.equal(negotiate(undefined), PREFERRED_PROTOCOL);
  assert.equal(SUPPORTED_PROTOCOLS[0], PREFERRED_PROTOCOL, 'the preferred one is the newest');
});

test('a message split across chunk boundaries is parsed once and whole', () => {
  // A pipe delivers bytes, not lines. This is the failure that shows up only under load, as a
  // parse error on a message that was never malformed.
  const whole = '{"jsonrpc":"2.0","id":1,"method":"ping"}';

  const first = takeLines(whole.slice(0, 12));
  assert.deepEqual(first.lines, [], 'no complete line yet');
  assert.equal(first.rest, whole.slice(0, 12), 'and the fragment is kept');

  const second = takeLines(first.rest + `${whole.slice(12)}\n{"partial":`);
  assert.deepEqual(second.lines, [whole]);
  assert.equal(second.rest, '{"partial":', 'the next fragment carries over');
});

test('a malformed but parseable message is an Invalid Request, not a crash', () => {
  const table = methods([]);

  for (const message of [null, 42, [], {}, { jsonrpc: '1.0', method: 'ping' }, { jsonrpc: '2.0' }]) {
    const reply = dispatch(message, table);

    if (reply === null) continue;
    assert.equal(reply.error.code, -32600, JSON.stringify(message));
  }
});

test('the SQLite experimental warning is dropped and every other warning survives', () => {
  const written = [];
  const fake = { removeAllListeners() {}, on() {} };
  const listener = filterWarnings(fake, { write: (line) => written.push(line) });

  const experimental = Object.assign(new Error('SQLite is an experimental feature'), {
    name: 'ExperimentalWarning',
  });
  assert.ok(isSqliteExperimental(experimental));

  listener(experimental);
  assert.deepEqual(written, [], 'the one warning AD5 knowingly accepts is not shown');

  // The control, and the reason this is a filter rather than NODE_NO_WARNINGS: a deprecation is
  // the early notice for AD5's stated risk that this API may change between minors.
  listener(Object.assign(new Error('x is deprecated'), { name: 'DeprecationWarning' }));
  listener(Object.assign(new Error('some other experiment'), { name: 'ExperimentalWarning' }));

  assert.deepEqual(written, [
    '[dpm] DeprecationWarning: x is deprecated\n',
    '[dpm] ExperimentalWarning: some other experiment\n',
  ]);
});
