/**
 * The MCP methods this server answers, over the JSON-RPC layer in `rpc.js`.
 *
 * Story 1 builds the handshake and the dispatch; the tools themselves arrive in Story 2 and
 * after. The registry is therefore a parameter rather than an import — a server with no tools
 * is a valid server, and it is the one whose stdout NFR3's criterion actually inspects.
 *
 * **Version negotiation echoes rather than dictates.** MCP revisions are dated strings, and a
 * server that always answered with its own newest would fail a client pinned to an older one it
 * also supports. So a version the server knows is echoed back, and anything else is answered
 * with the preferred version — which is the protocol's own instruction to the client that it
 * must either accept that or disconnect.
 */

import { RPC_ERRORS, failure, isRequest, isValidMessage, success } from './rpc.js';

/**
 * Revisions this server implements, newest first.
 *
 * All three share the shape used here — `initialize`, `tools/list`, `tools/call` and the
 * `notifications/initialized` notification — which is why one implementation answers to any of
 * them. **Verify this list against the client actually in use before shipping**: a revision
 * published after this was written is absent, and a client pinned to it will be answered with
 * `PREFERRED_PROTOCOL` instead.
 */
export const SUPPORTED_PROTOCOLS = ['2025-06-18', '2025-03-26', '2024-11-05'];

/** What the server offers when the client asks for something it does not know. */
export const PREFERRED_PROTOCOL = SUPPORTED_PROTOCOLS[0];

/** Named once so the tests and the handshake cannot disagree about it. */
export const SERVER_INFO = { name: 'dpm', version: '0.1.0' };

/**
 * @typedef {object} Tool
 * @property {string} name
 * @property {string} description
 * @property {object} inputSchema  JSON Schema for the arguments.
 * @property {(args: object) => unknown} handler
 */

/**
 * Negotiate a protocol version.
 *
 * @param {unknown} requested
 * @returns {string}
 */
export const negotiate = (requested) =>
  SUPPORTED_PROTOCOLS.includes(requested) ? requested : PREFERRED_PROTOCOL;

/**
 * Wrap a handler's return value in MCP's `CallToolResult`.
 *
 * It lives here rather than with the tools because the shape is the protocol's, not theirs — a
 * handler returns a row and this is what the wire requires that row to look like. Keeping it on
 * this side is also what stops `src/server/` from importing `src/tools/`, so the dependency runs
 * one way: tools know about the protocol's error codes, the protocol knows nothing about tools.
 *
 * `structuredContent` is the machine-readable copy, present from revision 2025-06-18;
 * `content` carries the same value as text, because a client on an older revision reads only
 * that one and both are in `SUPPORTED_PROTOCOLS`.
 */
export const toolResult = (value) => ({
  content: [{ type: 'text', text: JSON.stringify(value, null, 2) }],
  structuredContent: value,
});

/** The wire form of a tool — everything but the handler, which is this server's business. */
const describe = (tool) => ({
  name: tool.name,
  description: tool.description,
  inputSchema: tool.inputSchema,
});

/**
 * Build the method table for a set of tools.
 *
 * **`tools/list` and `tools/call` no longer share one list (AD12).** The list is advertised before
 * any database exists, built from an in-memory template; the table a call is dispatched against is
 * built later, against the real file, on the first `tools/call`. `tools` is what is described and
 * `resolve` is what is dispatched against, and the two are asserted identical rather than assumed
 * — which is what `capabilities.tools.listChanged: false`, declared below, promises a client.
 *
 * **`resolve` is called inside the `tools/call` handler and nowhere else.** Calling it here would
 * open the database at launch and silently undo the deferral, while every test of the *result*
 * still passed. AD12 rejected a lazy getter on `context.db` for the same reason one level down:
 * several tool modules destructure `const { db } = context` while the registry is being built, so
 * a getter is resolved eagerly and invisibly.
 *
 * `resolve` defaults to returning `tools`, so a caller with one list passes one argument and gets
 * exactly the behaviour this had before the split.
 *
 * `serverInfo` is a parameter for the same reason `resolve` is: this module knows the server's name
 * and version and has no business knowing its *schema* version, which lives behind `src/schema/`
 * and reaches the handshake from `serve()`. A client that caches derived answers needs it — an
 * entry produced under an earlier schema is stale however untouched the database file is — and the
 * handshake is the only place it can arrive, since the connection is not open yet and no read tool
 * reports it.
 *
 * @param {Tool[]} tools The list `tools/list` describes.
 * @param {() => Tool[]} [resolve] The live table `tools/call` dispatches against, resolved on
 *   first call.
 * @param {object} [serverInfo] What `initialize` answers with. Defaults to {@link SERVER_INFO}.
 * @returns {Record<string, (params: object) => unknown>}
 */
export function methods(tools, resolve = () => tools, serverInfo = SERVER_INFO) {
  // Memoised on the *identity* of the list `resolve` hands back, not on first call: the default
  // resolver returns the same array every time, so the map is built once and the unsplit path
  // keeps the cost it always had, while a resolver that opens the database on first call rebuilds
  // the map exactly once — when the list it returns changes.
  let indexed = null;
  const byName = () => {
    const live = resolve();

    if (indexed?.list !== live) indexed = { list: live, map: new Map(live.map((t) => [t.name, t])) };

    return indexed.map;
  };

  return {
    initialize: (params) => ({
      protocolVersion: negotiate(params?.protocolVersion),
      // Declared because it is offered, not because the list is non-empty: a client uses this
      // to decide whether to call `tools/list` at all, and a server that hid the capability
      // while holding tools would never be asked for them.
      capabilities: { tools: { listChanged: false } },
      serverInfo,
    }),

    ping: () => ({}),

    'tools/list': () => ({ tools: tools.map(describe) }),

    'tools/call': (params) => {
      const tool = byName().get(params?.name);

      // Thrown rather than returned so `dispatch` can turn it into a JSON-RPC error. An unknown
      // tool is a caller mistake about the protocol, not a tool that ran and failed.
      if (!tool) {
        const unknown = new Error(`no such tool: ${params?.name}`);
        unknown.rpc = RPC_ERRORS.methodNotFound;
        throw unknown;
      }

      // Wrapped, not returned raw. MCP's `CallToolResult` is a content array, and a handler
      // returns a row — so without this the first registered tool would put a bare object where
      // every client expects `content`. Story 1 could not catch it: with no tools to call, a
      // `tools/call` that never ran was conformant by vacancy.
      return toolResult(tool.handler(params.arguments ?? {}));
    },
  };
}

/**
 * Turn one incoming message into the response to send, or `null` to send nothing.
 *
 * Returning `null` for a notification is the load-bearing case. JSON-RPC forbids replying to a
 * message with no id, and MCP sends `notifications/initialized` immediately after the
 * handshake — so a server that answered everything would put a stray message on stdout during
 * the opening exchange of every single session, which is precisely what NFR3's criterion reads
 * the stream for.
 *
 * @param {unknown} message
 * @param {Record<string, (params: object) => unknown>} table
 * @returns {object|null}
 */
export function dispatch(message, table) {
  if (!isValidMessage(message)) {
    return failure(isRequest(message) ? message.id : null, RPC_ERRORS.invalidRequest);
  }

  const handler = table[message.method];
  const wantsReply = isRequest(message);

  // An unhandled *notification* is dropped, which is how `notifications/initialized` and
  // anything else the client announces are absorbed without a reply and without a method
  // table entry per name. Keying that on the absence of an id rather than on a list of known
  // notification names is what keeps a future one from becoming a stray error response.
  if (!wantsReply) return null;

  if (!handler) {
    return failure(message.id, RPC_ERRORS.methodNotFound, { method: message.method });
  }

  try {
    return success(message.id, handler(message.params ?? {}));
  } catch (error) {
    return failure(message.id, error.rpc ?? RPC_ERRORS.internal, { message: error.message });
  }
}
