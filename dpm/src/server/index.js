/**
 * The server loop: read a message, dispatch it, write the reply if there is one.
 *
 * Everything the loop needs is a parameter — the streams, the tools, the database location —
 * because a server that reached for `process.stdin` itself could only be tested by spawning a
 * process. Story 1's criterion is about what a *full session's* stdout contains, and the
 * cheapest honest way to assert that is to run the real loop over a pair of streams the test
 * owns. The spawned-process case is still covered, because it is the only thing that proves the
 * entry point wires the real streams to this.
 */

import { mkdirSync } from 'node:fs';
import { dirname } from 'node:path';
import { RPC_ERRORS, failure } from './rpc.js';
import { dispatch, methods } from './mcp.js';
import { log, readMessages, writeMessage } from './transport.js';
import { start } from '../start.js';
import { readOnlyTools, spineTools } from '../tools/index.js';

/**
 * Serve MCP over a pair of streams until the input ends.
 *
 * @param {object} [options]
 * @param {import('node:stream').Readable} [options.input]
 * @param {import('node:stream').Writable} [options.output]
 * @param {import('./mcp.js').Tool[]} [options.tools]
 * @returns {Promise<{handled: number}>} How many messages were dispatched, so a caller can tell
 *   a session that ran from one that connected and did nothing (NFR6).
 */
export async function serve({
  input = process.stdin,
  output = process.stdout,
  tools = [],
} = {}) {
  const table = methods(tools);
  let handled = 0;

  await readMessages(
    input,
    (message) => {
      handled += 1;

      const reply = dispatch(message, table);
      if (reply !== null) writeMessage(output, reply);
    },
    (line, error) => {
      // A line that is not JSON has no id to answer under, so the response carries `id: null` —
      // which is exactly what JSON-RPC reserves that value for. It still goes to stdout,
      // because it is protocol; the diagnostic goes to stderr, because it is not.
      log('unparseable message:', error.message);
      writeMessage(output, failure(null, RPC_ERRORS.parse));
    },
  );

  return { handled };
}

/**
 * Where the database lives, per AD4: generated, gitignored, and beside the committed `.sql`.
 *
 * Overridable by environment so a test — or a second project in one checkout — can point
 * elsewhere without the path becoming an argument every caller has to thread through.
 */
export const DATABASE = process.env.DPM_DATABASE ?? '.dpm/dpm.db';

/**
 * Open the database, register the spine tools, and serve until stdin ends.
 *
 * **This is the function that makes `server.test.js`'s import-graph guard mean something.**
 * Until Story 2 nothing under `src/server/` reached `node:sqlite`, so the assertion that the
 * entry point's *static* graph is free of it passed whichever way the entry point was written —
 * it was mutation-tested and the mutation survived. From here the graph runs
 * `index.js → start.js → db/connection.js → node:sqlite`, and a static import in
 * `bin/dpm-mcp.js` would drag the whole of it above the Node floor check.
 *
 * @param {object} [options]
 * @param {string} [options.location]
 * @returns {Promise<{handled: number}>}
 */
export async function main({ location = DATABASE } = {}) {
  // The directory is ours to create; the alternative is a first launch that fails on a missing
  // `.dpm/` with SQLite's own message, which names neither the plugin nor what to do about it.
  if (location !== ':memory:') mkdirSync(dirname(location), { recursive: true });

  const { db, migrated } = start(location);
  const tools = spineTools(db);

  // NFR7's lockout case. The server starts either way — refusing to start is the one outcome the
  // requirement rules out — and the difference is that a database from a newer plugin is served
  // read-only. This is the single line on stderr that a launch ever produces, because a caller
  // whose writes are being refused needs to know why before they make one.
  if (migrated.ahead) {
    log(`database schema version ${migrated.from} is ahead of this server's ${migrated.target};`,
      'serving reads only');

    return serve({ tools: readOnlyTools(tools, { found: migrated.from, supported: migrated.target }) });
  }

  // Deliberately says nothing on the way up. A line naming the database on every launch is the
  // same unasked-for noise `warnings.js` exists to remove, and `server.test.js` asserts a clean
  // session is silent on stderr as well as well-formed on stdout — a property worth keeping,
  // because it is what makes a stray warning visible at all.
  return serve({ tools });
}
