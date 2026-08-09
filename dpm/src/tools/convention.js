/**
 * The contract every entity tool follows.
 *
 * Written first and separately because Stories 3 through 7 all assert against it, and because
 * AD10 chose a conformance test over codegen — which means the tool schemas and the DDL are two
 * hand-written definitions and the test is the only thing holding them together. A test is only
 * as sharp as the declaration it reads, so what a tool declares about itself is the whole
 * mechanism, not bookkeeping around it.
 *
 * **`inputSchema` is written by hand and must stay that way.** Deriving the enums from
 * `PRAGMA table_info` at registration would close the seam structurally, and it is genuinely the
 * better property — AD10 says so, and rejected it on cost rather than merit. Taking it here by
 * the back door would not deliver that benefit: it would leave Story 7's conformance test
 * comparing the live schema against itself, passing unconditionally, while looking exactly like a
 * test that checks something. That is the shape of AD10's own must-NOT.
 *
 * **What `serverSupplied` is for.** AD10 requires every `NOT NULL` column without a default to be
 * a required argument on its create tool. Read against the live schema, that set includes `id`,
 * `created_at` and `updated_at` — a ULID this server mints and its own clock — plus the columns
 * denormalised from a parent and pinned by a composite foreign key. Making those caller arguments
 * would be faithful to the sentence and useless in practice. So a tool declares which columns it
 * fills itself, and Story 7 asserts that every `NOT NULL`-without-default column is *either* a
 * required argument *or* declared here, in both directions. A column added later must be
 * consciously classified; what it cannot be is neither, silently.
 */

import { RPC_ERRORS } from '../server/rpc.js';

/**
 * A tool refusing its arguments.
 *
 * Carries `rpc` so `dispatch` renders it as a JSON-RPC error rather than an internal one
 * (`src/server/mcp.js`). FR3 puts rejection at the tool boundary, and a caller cannot tell a
 * boundary rejection from a crash unless the code says which it was.
 */
export class ToolError extends Error {
  /**
   * @param {string} message
   * @param {{code: number, message: string}} [rpc]
   */
  constructor(message, rpc = RPC_ERRORS.invalidParams) {
    super(message);
    this.name = 'ToolError';
    this.rpc = rpc;
  }
}

/**
 * How a column this server fills gets its value. The keys are what Story 7 reads; the values are
 * for whoever is reading the tool six months from now and wants to know where a column came from.
 */
export const SUPPLIED = {
  /** A ULID from `src/id/ulid.js`. */
  ulid: 'ulid',
  /** The server's clock, as an ISO 8601 string. */
  clock: 'clock',
  /** `allocateNumber` — see `src/numbering/allocate.js`. */
  allocated: 'allocated',
  /** Read from another argument's row, or fixed by the column's own `CHECK`. */
  derived: (from) => `derived from ${from}`,
};

/**
 * How many rows a list-returning tool hands back when the caller does not say.
 *
 * **A default, not a ceiling.** FR13 asks for the bound and then says what kind of bound it is:
 * "The bound is a default that costs nothing to override, not a limit." So `limit` declares this
 * as its `default` and declares no `maximum` — a caller who wants two thousand rows asks for two
 * thousand and gets them. A ceiling here would be a boundary on what dpm can be asked for, which
 * is the thing the requirement's must-NOT forbids.
 */
export const DEFAULT_LIMIT = 50;

/**
 * The argument a tool with a body grows, and the columns it governs.
 *
 * Injected by `defineTool` rather than written on each tool, for the reason validation is wrapped
 * on: a tool that declared `body` and forgot the argument would advertise a summary/body split it
 * did not have, and one that declared the argument and forgot to filter would advertise a bound it
 * never applied. Declaring the columns is the whole of what a tool has to do.
 */
const bodyArgument = (body) => ({
  include_body: {
    type: 'boolean',
    default: false,
    description: `Return ${body.join(', ')} as well. Withheld unless asked for.`,
  },
});

/**
 * The two arguments every paged tool takes.
 *
 * `offset` is here because a default page size without a way past the first page is not a bound,
 * it is a truncation — the caller would have raised `limit` purely to reach row 51, which turns
 * every deep read into a full one.
 */
const PAGE_ARGUMENTS = {
  limit: {
    type: 'integer',
    minimum: 1,
    default: DEFAULT_LIMIT,
    description: 'Rows to return. Raise it as far as you like — there is no ceiling.',
  },
  offset: { type: 'integer', minimum: 0, default: 0, description: 'Rows to skip first.' },
};

/**
 * Drop the body columns from whatever a handler returned.
 *
 * Understands the two shapes a dpm tool returns — one row, or a page of them — and nothing else.
 * A tool returning a third shape would silently pass through unfiltered, which is why `defineTool`
 * only ever hands this the result of a tool that declared `body` in the first place.
 *
 * @param {unknown} value
 * @param {string[]} body
 * @returns {unknown}
 */
export function withoutBody(value, body) {
  // The early return is load-bearing beyond speed: rebuilding a row here would turn `node:sqlite`'s
  // null-prototype rows into plain objects for every tool, body or no body, and strict deep-equal
  // treats those as different however identical their contents.
  if (body.length === 0 || value === null || typeof value !== 'object') return value;

  const strip = (row) => Object.fromEntries(
    Object.entries(row).filter(([column]) => !body.includes(column)),
  );

  if (Array.isArray(value.items)) return { ...value, items: value.items.map(strip) };

  return strip(value);
}

/** The JSON Schema keywords `validate` understands. Anything else in a schema is a mistake. */
const KEYWORDS = new Set(['type', 'properties', 'required', 'additionalProperties', 'enum',
  'description', 'default', 'minLength', 'minimum']);

const TYPES = {
  string: (value) => typeof value === 'string',
  integer: (value) => Number.isInteger(value),
  boolean: (value) => typeof value === 'boolean',
  object: (value) => typeof value === 'object' && value !== null && !Array.isArray(value),
};

/**
 * Check arguments against a tool's `inputSchema` before any SQL runs.
 *
 * Deliberately a small validator over the subset of JSON Schema the tools use, rather than a
 * general one. A general validator is a dependency, and `package.json` declares none (NFR1); a
 * hand-rolled general validator is a large amount of code whose bugs would be silent. The
 * `KEYWORDS` guard is what keeps the subset honest — a schema reaching for a keyword this does
 * not implement fails loudly at registration instead of being ignored at call time, which is the
 * failure mode that makes partial validators worse than none.
 *
 * @param {object} schema
 * @param {object} args
 * @param {string} where The tool name, for the message.
 * @returns {object} The arguments, with defaults applied.
 * @throws {ToolError}
 */
export function validate(schema, args, where) {
  if (!TYPES.object(args)) throw new ToolError(`${where}: arguments must be an object`);

  const properties = schema.properties ?? {};
  const required = schema.required ?? [];
  const checked = {};

  for (const name of Object.keys(args)) {
    if (!Object.hasOwn(properties, name)) {
      throw new ToolError(`${where}: unknown argument '${name}'`);
    }
  }

  for (const name of required) {
    // `undefined` and absent are the same thing here, and both are the must-NOT's shape: a
    // caller that omits `class` must be refused, not defaulted into one.
    if (args[name] === undefined) throw new ToolError(`${where}: '${name}' is required`);
  }

  for (const [name, rule] of Object.entries(properties)) {
    // **`default` is advertised, not applied.** JSON Schema's `default` is advisory — it tells a
    // client what omitting the argument will get them — and materialising it here would make an
    // absent argument indistinguishable from a supplied one by the time a handler sees it. On a
    // create tool that is merely redundant, since the handler supplies the same fallback. On an
    // *update* tool it is a silent data loss: `dpm_update_story_criterion({id})` would arrive
    // carrying `polarity: 'must'` and reset a `must_not` criterion nobody asked to change.
    const value = args[name];

    if (value === undefined || value === null) continue;

    if (rule.type && !TYPES[rule.type](value)) {
      throw new ToolError(`${where}: '${name}' must be ${rule.type}, got ${typeof value}`);
    }

    if (rule.enum && !rule.enum.includes(value)) {
      throw new ToolError(
        `${where}: '${name}' must be one of ${rule.enum.join(', ')} — got '${value}'`,
      );
    }

    if (rule.minLength !== undefined && value.length < rule.minLength) {
      throw new ToolError(`${where}: '${name}' must not be empty`);
    }

    if (rule.minimum !== undefined && value < rule.minimum) {
      throw new ToolError(`${where}: '${name}' must be at least ${rule.minimum}`);
    }

    checked[name] = value;
  }

  return checked;
}

/**
 * Register a tool, checking that it declares what the later stories will read.
 *
 * The checks here are cheap and they run at import time, so a descriptor missing a field fails
 * the moment the registry is built rather than when Story 5 or Story 7 reaches for it. That
 * matters more than it looks: `reads` and `serverSupplied` are consumed by assertions in other
 * stories, and a tool that quietly omitted one would make those assertions pass by covering less.
 *
 * @param {object} tool
 * @param {string} tool.name Matches NFR5's `dpm_[a-z_]{6,}`; Story 5 asserts the word rule.
 * @param {string} tool.table The table the tool writes, or the primary one it reads.
 * @param {string} tool.description Shown by `tools/list`.
 * @param {object} tool.inputSchema Hand-written. See the note at the head of this file.
 * @param {string[]} tool.reads Tables this tool can return rows from — Story 5's reachability.
 * @param {Record<string, string>} [tool.serverSupplied] Columns the server fills, and how.
 * @param {string[]} [tool.body] Columns withheld unless `include_body` asks for them.
 * @param {boolean} [tool.paged] Whether the tool returns a page, and so takes `limit`/`offset`.
 * @param {boolean} tool.mutates Whether the tool writes. Required, and deliberately not derived
 *   from the verb in the name: NFR7 keeps a database from a newer plugin readable by serving its
 *   read tools and refusing its write ones, and the default a forgotten declaration would fall
 *   into is the one that writes to a schema this server does not understand.
 * @param {(args: object) => unknown} tool.handler Receives arguments already validated against
 *   `inputSchema` — see the wrapping below.
 * @returns {object} The tool, frozen.
 */
export function defineTool(tool) {
  const { name, table, description, reads, handler, body = [], paged = false, mutates } = tool;

  if (!/^dpm_[a-z_]+$/.test(name ?? '')) throw new Error(`not a dpm tool name: ${name}`);
  if (!table) throw new Error(`${name}: no table declared`);
  if (!description) throw new Error(`${name}: no description — tools/list is how a caller finds it`);
  if (!Array.isArray(reads) || reads.length === 0) {
    throw new Error(`${name}: 'reads' is empty — Story 5 asserts reachability from it`);
  }
  if (typeof handler !== 'function') throw new Error(`${name}: no handler`);
  if (!Array.isArray(body)) throw new Error(`${name}: 'body' must be an array of column names`);
  if (typeof mutates !== 'boolean') {
    throw new Error(`${name}: 'mutates' must be declared — NFR7 serves reads to a database this `
      + 'server is too old for, and an undeclared tool would be served as one');
  }

  if (tool.inputSchema?.type !== 'object' || tool.inputSchema.additionalProperties !== false) {
    throw new Error(`${name}: inputSchema must be an object schema with additionalProperties false`);
  }

  // FR13's two arguments are added here rather than by each tool, so what a tool declares about
  // itself and what a caller may send cannot disagree. A tool that had written either by hand
  // would be redeclaring a convention, so it is refused rather than merged over.
  const supplied = {
    ...(body.length > 0 ? bodyArgument(body) : {}),
    ...(paged ? PAGE_ARGUMENTS : {}),
  };

  const declared = tool.inputSchema.properties ?? {};

  for (const property of Object.keys(supplied)) {
    if (Object.hasOwn(declared, property)) {
      throw new Error(`${name}: '${property}' comes from the convention — do not declare it`);
    }
  }

  const inputSchema = { ...tool.inputSchema, properties: { ...declared, ...supplied } };

  for (const [property, rule] of Object.entries(inputSchema.properties)) {
    for (const keyword of Object.keys(rule)) {
      if (!KEYWORDS.has(keyword)) {
        throw new Error(`${name}.${property}: '${keyword}' is not validated — see convention.js`);
      }
    }
  }

  // **Validation is wrapped on, not left to the handler.** Written the other way round, each
  // handler would call `validate` with a schema of its own — a second copy of `inputSchema` free
  // to drift from the declared one, and a handler that simply forgot the call would accept
  // anything while `tools/list` advertised a contract it did not keep. Here a tool cannot skip
  // it, and the schema a caller is checked against is by construction the schema it was shown.
  return Object.freeze({
    serverSupplied: {},
    ...tool,
    body,
    paged,
    // The augmented schema, not the declared one: `tools/list` publishes this, and a caller
    // checked against a schema they were never shown is the drift the wrapping exists to prevent.
    inputSchema,
    handler: (args) => {
      const checked = validate(inputSchema, args ?? {}, name);
      const result = handler(checked);

      // The default is the summary, and it is applied here rather than materialised in `validate`
      // — an absent argument and an explicit `false` mean the same thing to a read, and neither
      // may become a `true` the caller did not send.
      return checked.include_body ? result : withoutBody(result, body);
    },
  });
}
