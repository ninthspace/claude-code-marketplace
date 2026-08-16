/**
 * The registry — create, read, update and list for every entity type in the schema.
 *
 * `acceptance_criterion` is here alongside `story_criterion` because they are the two halves of
 * one join: `coverage` binds a spec-side criterion to a story-side one, and tooling either alone
 * would have left it reachable from one end only. `document` carries thirteen of the types rather
 * than one, because the kinds are one table distinguished by `kind`. That is why the count of
 * tools is not the count of tables, and why anything asserting either derives it from this list
 * rather than restating a number.
 *
 * **What is not here is asserted rather than assumed.** `dpm/tests/parity.test.js` compares the
 * live table list against this registry in both directions, and every table it passes over carries
 * its reason beside it. Story 5's reachability assertion reads each tool's `reads` the same way —
 * what is covered is a property of this registry, never of a list kept next to it.
 */

import { ulid } from '../id/ulid.js';
// The neighbour check, threaded through `context` so the integrity tool can report it. `src/tools/`
// reaching into `src/server/` closes no cycle: that module imports the filesystem, the path
// helpers and the version parser, and nothing else.
import { currentSkew } from '../server/neighbour.js';
import { stampSkew } from '../server/stamp.js';
import { ToolError } from './convention.js';
import { dependencyTools } from './cross/dependency.js';
import { integrityTools } from './cross/integrity.js';
import { numberingTools } from './cross/numbering.js';
import { publishTools } from './cross/publish.js';
import { templateTools } from './cross/template.js';
import { artifactTools } from './entity/artifacts.js';
import { milestoneTools } from './entity/milestones.js';
import { reviewRetroTools } from './entity/review-retro.js';
import { listTools } from './list.js';
import { searchTools } from './search.js';
import { sessionTools } from './session.js';
import { coverageTools } from './spine/coverage.js';
import { criterionTools } from './spine/criterion.js';
import { deliveryTools } from './spine/delivery.js';
import { DETAIL, detailChildTools } from './spine/detail.js';
import { documentTools } from './spine/document.js';
import { requirementTools } from './spine/requirement.js';
import { sectionTools } from './spine/section.js';
import { vocabularies, vocabularyJoins } from './vocabulary.js';

/**
 * Build every spine tool against one database.
 *
 * `now` and `newId` are injected rather than reached for, so a test can pin a timestamp and read
 * back exactly what it wrote. The dump work in Epic 47-02 needed a normalisation rule for one
 * machine-local timestamp it could not pin; there is no reason to create more of them here.
 *
 * @param {import('node:sqlite').DatabaseSync} db
 * @param {object} [options]
 * @param {() => string} [options.now] ISO 8601.
 * @param {() => string} [options.newId]
 * @param {string} [options.root] The repository root `publish` writes into — the server's own
 *   working directory in life, and injected for the same reason `now` is: a test that cannot pin
 *   it publishes a corpus into whichever directory the test runner happened to start in.
 * @returns {object[]} Every tool, in a stable order.
 */
/**
 * Why a database this server is too old for is served read-only (NFR7).
 *
 * @param {{found: number, supported: number}} version
 * @returns {string}
 */
export const versionSkew = ({ found, supported }) =>
  `this database is at schema version ${found} and this server understands up to ${supported}. `
  + 'Reads are answered; writes are refused until the plugin is updated, so an older release '
  + 'cannot write rows a newer schema constrains.';

/**
 * The same registry with every write refused, for whichever reason applies.
 *
 * **The write tools stay listed rather than being dropped.** Withholding them would answer a
 * create call with *Method not found*, which is what a caller sees when a server is broken or a
 * tool was renamed — and would tell them nothing about the reason that actually applies. Listed
 * and refusing, the refusal explains itself. NFR7's clause is that a user is not locked out of
 * their own planning history; a lockout with a misleading error is the worst of the available
 * outcomes, not a safe default.
 *
 * **The reason is a parameter because there are two of them and only one mechanism.** A database
 * from a newer plugin and a server launched to observe are different situations with the same
 * answer — every mutating tool refuses, every read still answers, and the wire form of the list is
 * untouched, which is what `listChanged: false` promises a client. Building the sentence at the
 * call site is what keeps that one implementation from acquiring a mode.
 *
 * @param {object[]} tools
 * @param {{reason: string}} why One of the two sentences above.
 * @returns {object[]}
 */
export function readOnlyTools(tools, { reason }) {
  return tools.map((tool) => (tool.mutates
    ? Object.freeze({
      ...tool,
      handler: () => {
        throw new ToolError(`${tool.name}: ${reason}`);
      },
    })
    : tool));
}

export function spineTools(
  db,
  {
    now = () => new Date().toISOString(), newId = ulid, root = '.',
    skew = currentSkew, stamp = stampSkew,
  } = {},
) {
  const context = { db, now, newId, root, skew, stamp };

  // **The kinds come from `document_kind`, not from a list here.** A hand-kept enumeration in this
  // file is what left eleven kinds without tools through Epic 47-03 and had the breakdown that
  // found it name ten of them — and the same list would have to be edited again for every kind
  // seeded afterwards. Read from the table, a kind acquires its three tools by being seeded, which
  // is FR10's "from the outset" holding by construction rather than by anyone remembering.
  const kinds = db.prepare('SELECT kind FROM document_kind ORDER BY kind').all().map((row) => row.kind);

  const spine = [
    ...kinds.flatMap((kind) => documentTools(context, { kind, detail: DETAIL[kind] ?? null })),
    ...sectionTools(context),
    ...detailChildTools(context),
    ...requirementTools(context),
    ...criterionTools(context, {
      table: 'acceptance_criterion', parent: 'requirement_id', owner: 'requirement',
    }),
    ...criterionTools(context, {
      table: 'story_criterion', parent: 'story_id', owner: 'story',
    }),
    ...deliveryTools(context, {
      table: 'story',
      parent: 'epic_id',
      // FR4. CPM appends `[plan]` to the story's `##` heading and reads it back off there; here
      // `epics` sets a column and `do` asks the story. Declared 0/1 rather than a boolean so the
      // argument and `CHECK (plan IN (0, 1))` are the same set, which is what AD10's conformance
      // seam compares — a boolean at the tool boundary would have nothing to check against.
      extra: {
        plan: {
          type: 'integer',
          enum: [0, 1],
          default: 0,
          description: 'whether this story is planned in full before any of its tasks are executed',
        },
      },
    }),
    ...deliveryTools(context, {
      table: 'task',
      parent: 'story_id',
      extra: { description: { type: 'string' } },
    }),
    ...coverageTools(context),
    // In the spine rather than below with the other cross-entity tools, because `list_dependency`
    // takes its body columns from `read_dependency` and `listTools` is handed the spine to find
    // them in. An edge is a create/read pair like any other; what makes it cross-entity is which
    // tables it points at, not how it is built.
    ...dependencyTools(context),
    ...reviewRetroTools(context),
    ...artifactTools(context),
    ...milestoneTools(context),
    ...vocabularies(context),
    ...vocabularyJoins(context),

    // FR6's discoverability pair, in the spine rather than below because `list_document_kind` is
    // derived from `LISTS` and takes its body columns from `read_document_kind` — which has to
    // exist by the time `listTools` runs. `spineTools` is handed down rather than imported over
    // there, because the preview seeds its example through the ordinary create tools and an import
    // would close a cycle back through this module while it is still being built.
    ...templateTools(context, (scratch) => spineTools(scratch)),
  ];

  return [
    ...spine,

    // Built from the spine rather than beside it: each list tool takes its body columns from the
    // read tool of the same type, so the two cannot answer the same question differently.
    ...listTools(context, spine),

    // FR9's tool, over both indexes. It sits beside the list tools rather than in `spine` because
    // it belongs to no entity type: what it returns is a hit naming one, and the entity vocabulary
    // it accepts is read out of the schema at build time.
    ...searchTools(context),

    // FR11's table. It sits here rather than in Epic 47-05 — where the parity enumeration counts
    // it — because session lifecycle is a server concern every skill needs from the first
    // conversion. The epic's Notes carry the reasoning.
    ...sessionTools(context),

    // The three that belong to no single entity: a number, the sweep over everything, and the one
    // that writes the tree rather than a row (AD11).
    ...numberingTools(context),
    ...integrityTools(context),
    ...publishTools(context),
  ];
}
