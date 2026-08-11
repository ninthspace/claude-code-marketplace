/**
 * Story 0 — the tools exist, and a session can reach them.
 *
 * Five epics built a 171-tool surface and every suite passed over it while nothing declared the
 * server that serves it. That is false-pass register #21, and its shape is worth stating because
 * it is the reason this file exists rather than another assertion inside `server.test.js`:
 * **every test that drives the server supplies the launch a session does not.** `server.test.js`,
 * `spine-integration.test.js` and `naming.test.js` each spawn `bin/dpm-mcp.js` by path, so all
 * three keep passing with the manifest empty. A check that spawns cannot see the gap; only one
 * that reads the manifest can.
 *
 * So the first two tests below assert against `plugin.json` and drive the reading of it against
 * manifests with the declaration removed and broken — the control that makes a passing run mean
 * something, since a check that always passes is indistinguishable from one that works.
 *
 * The third is the other half of FR29. The harness dispatches `mcp__plugin_<plugin>_<server>__
 * <tool>`, so the name a skill writes is not the name the registry holds, and nothing in either
 * language makes the two agree. That is the fourth integration seam the spec names.
 *
 * **That form is the one thing here the suite cannot verify, and it was wrong for four epics.** The
 * blind spot above has a second half: a test that supplies its own launch never meets a name the
 * harness built, so the whole corpus can name a prefix no session dispatches and every check in
 * this file still passes — including the one below, which used to assert the prefix equalled
 * `mcp__` + the server key and was satisfied by two strings agreeing on the wrong rule. What can be
 * held is that the prefix is *derived* from the manifest and not transcribed beside it, which is
 * what the assertion below does now. The rule itself is external, and the comment naming its source
 * is the only place it is written down.
 *
 * **What is deliberately not here.** The name *shape* rule and the refusal of an export carrying
 * the server's own identity are `naming.test.js`'s, asserted there against the live registry and
 * the live schema. Restating them would be a second copy of a rule with one home.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { existsSync, readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { openPlanningDatabase, handlers } from './support/planning-database.js';
import { skillSource, toolNames, CALLABLE } from './support/skills.js';
import { spineTools } from '../src/tools/index.js';

const DPM = join(import.meta.dirname, '..');
const MANIFEST = join(DPM, '.claude-plugin', 'plugin.json');

/** The server key. The harness puts it after the plugin name, not on its own — see `CALLABLE`. */
const SERVER = 'dpm';

/**
 * What is wrong with a manifest's server declaration, or nothing.
 *
 * A function rather than a run of assertions so the same reading can be driven against manifests
 * that are broken on purpose. `root` stands in for `${CLAUDE_PLUGIN_ROOT}`, which is how the
 * plugin format expresses a path inside the plugin directory.
 *
 * @param {object} manifest
 * @param {string} root
 * @returns {string[]}
 */
export function declarationProblems(manifest, root) {
  const servers = manifest.mcpServers;
  if (!servers || Object.keys(servers).length === 0) return ['no MCP server is declared'];

  const problems = [];

  for (const [name, server] of Object.entries(servers)) {
    if (!server.command) problems.push(`${name}: no command`);

    // Every path the declaration names has to exist. `command` is a bare executable here (`node`),
    // so it is the argument carrying the plugin root that names a file — which is the one that can
    // be wrong in a way nothing else notices.
    for (const argument of server.args ?? []) {
      if (!argument.includes('${CLAUDE_PLUGIN_ROOT}')) continue;

      const path = argument.replaceAll('${CLAUDE_PLUGIN_ROOT}', root);
      if (!existsSync(path)) problems.push(`${name}: ${argument} does not exist`);
    }
  }

  return problems;
}

test('the plugin manifest declares a server whose entry point exists', () => {
  const manifest = JSON.parse(readFileSync(MANIFEST, 'utf8'));

  assert.deepEqual(declarationProblems(manifest, DPM), []);

  // The key is half the namespace and the plugin's own name is the other half.
  // `mcp__plugin_dpm_dpm__create_spec` is what every skill in FR25's corpus writes, so renaming
  // either one renames 171 tools in one edit and no other assertion would notice.
  assert.deepEqual(Object.keys(manifest.mcpServers), [SERVER],
    'exactly one server, keyed by the name the callable form is built from');
  assert.equal(manifest.name, 'dpm', 'and the plugin name, which the callable form also carries');

  // And the prefix the corpus is read with is built from both rather than agreeing by coincidence.
  //
  // **Spelled here and computed there, which is the opposite of how this read before.** The old
  // pairing recomputed the prefix from the same key `CALLABLE` was written against, so it compared
  // one rule with itself and passed while both sides named a prefix no session dispatches. The two
  // sides now differ in kind: `CALLABLE` reads the manifest, this is a literal, and only the
  // external rule makes them equal.
  assert.equal(CALLABLE, 'mcp__plugin_dpm_dpm__');
});

test('a manifest missing or misnaming its server is reported, not passed over', () => {
  const manifest = JSON.parse(readFileSync(MANIFEST, 'utf8'));

  // The register's own condition, planted. Each of these is a manifest that would ship a tool
  // surface no session can reach, and each has to be caught by the reading above rather than by
  // a launch — every launch in this suite is one the suite supplied.
  const { mcpServers, ...undeclared } = manifest;
  assert.deepEqual(declarationProblems(undeclared, DPM), ['no MCP server is declared']);
  assert.deepEqual(declarationProblems({ ...manifest, mcpServers: {} }, DPM),
    ['no MCP server is declared']);

  const missing = { mcpServers: { dpm: { command: 'node', args: ['${CLAUDE_PLUGIN_ROOT}/bin/gone.js'] } } };
  assert.deepEqual(declarationProblems(missing, DPM), ['dpm: ${CLAUDE_PLUGIN_ROOT}/bin/gone.js does not exist']);

  assert.deepEqual(declarationProblems({ mcpServers: { dpm: { args: [] } } }, DPM), ['dpm: no command']);
});

test('the declared command starts and answers, run as the manifest writes it', async (t) => {
  const manifest = JSON.parse(readFileSync(MANIFEST, 'utf8'));
  const server = manifest.mcpServers[SERVER];

  // Assembled from the declaration rather than from a path this file knows, which is the whole
  // difference between this and the three suites that already spawn the server: those prove the
  // entry point works, this proves the thing a session is told to run is that entry point.
  const args = server.args.map((argument) => argument.replaceAll('${CLAUDE_PLUGIN_ROOT}', DPM));

  const request = JSON.stringify({
    jsonrpc: '2.0', id: 1, method: 'initialize', params: { protocolVersion: '2025-06-18' },
  });

  const { code, stdout } = await run(server.command, args, `${request}\n`,
    { DPM_DATABASE: ':memory:' });

  assert.equal(code, 0, 'the command the manifest declares did not start');
  assert.equal(JSON.parse(stdout.trim().split('\n')[0]).result.serverInfo.name, SERVER);
});

test('every tool a skill names is the callable form of a registered tool', (t) => {
  const db = openPlanningDatabase(t);
  const registered = new Set(spineTools(db).map((tool) => tool.name));

  const skills = readdirSync(join(DPM, 'skills'), { withFileTypes: true })
    .filter((entry) => entry.isDirectory())
    .map((entry) => entry.name);

  assert.ok(skills.length > 0, 'there are skills to check');

  for (const skill of skills) {
    const source = skillSource(skill);
    const named = toolNames(source);

    assert.ok(named.length > 0, `${skill} names no tool at all — the extraction found nothing`);

    for (const name of named) {
      assert.ok(registered.has(name), `${skill} calls ${CALLABLE}${name}, which is not a tool`);
    }

    // The other direction, and the one the extraction alone cannot give: a bare exported name is
    // a call no agent can make, and it contributes nothing to `named` — so without this it reads
    // as an absence rather than as a mistake.
    //
    // **Matched inside a code span rather than anywhere in the prose**, because one exported name
    // is also an ordinary English word. A bare-word sweep would fail any skill that told an agent
    // to search the codebase, and the repair for a check like that is to delete the sentence — the
    // wrong repair. A backticked name is the corpus's own convention for naming a tool, so it is
    // where a mistake would actually appear.
    for (const registration of registered) {
      if (!source.includes(`\`${registration}\``)) continue;

      assert.fail(`${skill} writes \`${registration}\` without the ${CALLABLE} prefix — `
        + 'the exported name is not the one the harness dispatches');
    }
  }
});

test('a story carries its planning mark as a column, and its title is untouched', (t) => {
  const db = openPlanningDatabase(t);
  const tools = spineTools(db);
  const call = handlers(tools);

  const spec = call.create_spec({ slug: 'persistence', title: 'Persistence' });
  const epic = call.create_epic({ slug: 'spine', title: 'Skills: Spine', parent_id: spec.id });

  const planned = call.create_story({
    epic_id: epic.id, number: 1, title: 'Convert `epics`', position: 0, plan: 1,
  });
  const plain = call.create_story({
    epic_id: epic.id, number: 2, title: 'Convert `do`', position: 1,
  });

  assert.equal(call.read_story({ id: planned.id }).plan, 1);
  assert.equal(call.read_story({ id: plain.id }).plan, 0, 'the default is off, not absent');

  // The point of the column. CPM carries this as `[plan]` appended to the story's `##` heading and
  // parses it back off there; a title that came out of the write with a marker on it would mean
  // the parse had merely moved rather than gone.
  for (const story of [planned, plain]) {
    assert.equal(call.read_story({ id: story.id }).title, story.title);
    assert.doesNotMatch(call.read_story({ id: story.id }).title, /\[plan\]/);
  }

  assert.equal(call.update_story({ id: plain.id, plan: 1 }).plan, 1, 'a story can be marked later');
  assert.equal(call.read_story({ id: plain.id }).title, 'Convert `do`');

  // And the value is constrained at **both** layers, asserted separately because one refusal is
  // indistinguishable from the other from outside. Dropping the tool's enum leaves the column to
  // refuse; dropping the column's `CHECK` leaves the tool to. Either way a caller sees a throw
  // naming `plan`, and a single assertion would keep passing while validation quietly moved to the
  // layer AD10's seam exists to keep it off.
  assert.deepEqual(tools.find((tool) => tool.name === 'create_story').inputSchema.properties.plan.enum,
    [0, 1], 'the tool declares the permitted set, so it refuses before the write');

  assert.throws(
    () => call.create_story({ epic_id: epic.id, number: 3, title: 'X', position: 2, plan: 2 }),
    /plan/,
  );

  assert.throws(
    () => db.prepare('UPDATE story SET plan = 2 WHERE id = ?').run(planned.id),
    /CHECK/,
    'the column refuses it too, so a write reaching past the tool is still constrained',
  );
});

function run(command, args, input = '', env = {}) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, { stdio: ['pipe', 'pipe', 'pipe'], env: { ...process.env, ...env } });

    let stdout = '';

    child.stdout.on('data', (chunk) => {
      stdout += chunk;
    });
    child.stderr.resume();

    child.on('error', reject);
    child.on('close', (code) => resolve({ code, stdout }));

    child.stdin.end(input);
  });
}
