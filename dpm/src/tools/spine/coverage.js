/**
 * `coverage` — one matrix row: a verbatim fragment of a requirement bound to one story criterion.
 *
 * **The natural key is `(requirement_id, spec_fragment, story_criterion_id)`, and `position` is no
 * part of it.** `004-delivery.sql` records what an earlier draft cost by keying on `position`
 * instead of `spec_fragment`: it accepted the same fragment bound to the same criterion twice at
 * two positions — two identical rows, each independently verifiable, each counting toward a
 * roll-up — while rejecting two genuinely different fragments that happened to share a position.
 * The tool inherits that. `position` is an argument because the column is `NOT NULL` with no
 * default, and it is display order; nothing here reads it to decide whether a binding exists.
 *
 * **`verified_at` and `binding_hash` are set together or not at all**, which the table's `CHECK`
 * enforces and this tool does not duplicate. What these tools do add is that the pair can only be
 * set *correctly*, and neither half is a caller's to choose: `verified` is a boolean saying the
 * check happened, `verified_at` is this server's clock at the moment of the call, and
 * `binding_hash` is computed from the row's own two texts by `src/coverage/binding.js`. A time
 * supplied by the party making the claim is a time nobody read off a clock, and nothing downstream
 * can tell that row from a real one — while verification time is exactly what the coverage matrix
 * publishes as proof. So a skill writing a ✓ says *that* it checked; the server says when, and
 * over what.
 *
 * **The boolean carries all three states**, which is what keeps it a swap rather than a narrowing:
 * omitted leaves the mark and its hash alone, `true` stamps both, `false` clears both. Unverifying
 * is a decision a caller can still make — what it can no longer do is date one.
 *
 * **Retirement is its own verb, and `update_coverage` does not offer it.** `retire_coverage` takes
 * an id and a reason; the timestamp is the server's. The alternative — `retired_at` and
 * `retired_reason` as two more fields on the update tool, the way `artifact` carries them — would
 * make withdrawing a binding indistinguishable at the tool boundary from moving its display order,
 * and would let a mistyped update un-retire one. Withdrawing a binding is a decision with a reason;
 * `position` is a detail. `coverage` is not a vocabulary, so the tool is written here rather than
 * produced by `vocabulary.js`'s factory, but the shape is that factory's deliberately: same
 * server-supplied clock, same refusal to retire twice.
 */

import { defineTool, SUPPLIED, ToolError } from '../convention.js';
import { bindingHash, fragmentPlacement } from '../../coverage/binding.js';
import { withRequirementLabel } from '../../coverage/label.js';
import { refuseCrossEpicDelivery } from './closing.js';
import { deleteByKey, insert, readById, update } from '../crud.js';
import { entityTools } from '../entity.js';

const BINDING = {
  requirement_id: { type: 'string', minLength: 1 },
  spec_fragment: {
    type: 'string',
    minLength: 1,
    description: 'A verbatim fragment of the requirement — part of identity, not a summary',
  },
  story_criterion_id: { type: 'string', minLength: 1 },
};

const STATE = {
  position: { type: 'integer', minimum: 0, description: 'Display order only; not identity' },
  verified: {
    type: 'boolean',
    description: 'True records the ✓ at the server\'s clock, false clears it; the server computes '
      + 'the binding hash that accompanies it. Omit to leave the mark alone',
  },
};

/**
 * Refuse a binding whose fragment is nowhere in the requirement it names (FR2).
 *
 * **The refusal names where the fragment does belong, because that is the whole difference between
 * a diagnosis and a complaint.** A caller told only that their quote was not found has to go and
 * read every requirement in the spec to find out whether they mistyped it or aimed it at the wrong
 * row. Told that it is FR9's text, they have the answer and the fix in one line — which is NFR4's
 * rule, that every refusal names what to do instead rather than only what was wrong.
 *
 * Where nothing in the spec holds it, the refusal says so plainly. That is the mistyped-quote case,
 * and inventing a nearest match for it would be a guess presented as a finding.
 *
 * @param {import('node:sqlite').DatabaseSync} db
 * @param {object} args The create call's arguments.
 * @param {string} where The tool name, for the message's prefix.
 * @throws {ToolError} When the fragment occurs nowhere in the named requirement's text.
 */
function refuseUnfoundFragment(db, args, where) {
  const placement = fragmentPlacement(db, args);

  if (placement.found) return;

  throw new ToolError(
    `${where}: the fragment is nowhere in ${placement.label}'s text`
    + (placement.sibling
      ? ` — it belongs to ${placement.sibling.label}, so bind it to that requirement`
      : ' — a binding quotes its requirement verbatim, so check the quote against the text'),
  );
}

/**
 * @param {object} context
 * @param {import('node:sqlite').DatabaseSync} context.db
 * @param {() => string} context.now
 * @param {() => string} context.newId
 * @returns {object[]}
 */
export function coverageTools({ db, now, newId }) {
  return [
    defineTool({
      name: 'create_coverage',
      table: 'coverage',
      description: 'Bind a requirement fragment to a story criterion. One matrix row.',
      reads: ['coverage'],
      mutates: true,
      serverSupplied: {
        id: SUPPLIED.ulid,
        verified_at: SUPPLIED.clock,
        binding_hash: SUPPLIED.derived('the bound texts'),
      },
      inputSchema: {
        type: 'object',
        additionalProperties: false,
        properties: { ...BINDING, ...STATE },
        required: ['requirement_id', 'spec_fragment', 'story_criterion_id', 'position'],
      },
      handler: (args) => {
        // FR2 — the fragment has to be *in* the requirement it names. Refused here rather than
        // reported by the integrity register later: a paraphrased or mistyped quote reads as a
        // sound binding in every roll-up until somebody runs the check, and by then it has been
        // counted toward a requirement being discharged. The register keeps its own copy for what
        // a restore brings in, which passes through no tool.
        refuseUnfoundFragment(db, args, 'create_coverage');

        return insert(db, 'coverage', {
          id: newId(),
          requirement_id: args.requirement_id,
          spec_fragment: args.spec_fragment,
          story_criterion_id: args.story_criterion_id,
          position: args.position,
          // FR1 — the stamp is this server's clock, never a value the caller carried in. A row
          // born unverified is the ordinary case, so the absent argument and an explicit `false`
          // mean the same thing here: no mark, and no hash beside one.
          verified_at: args.verified ? now() : null,
          // Computed from the arguments rather than read back, because the row is not there yet —
          // and the criterion is, which is the half that has to be looked up either way. Skipped
          // for an unverified row: a `binding_hash` beside a NULL `verified_at` is a binding
          // recorded for a verification that was never made, which is the state FR21's decay
          // triggers exist to prevent arising the other way round.
          binding_hash: args.verified ? bindingHash(db, args) : null,
        }, 'create_coverage');
      },
    }),

    defineTool({
      name: 'read_coverage',
      table: 'coverage',
      description: 'Read one coverage row by id, with its verification state as columns.',
      reads: ['coverage'],
      mutates: false,
      body: ['spec_fragment'],
      // FR10. The row names its requirement by an id, which is not something a caller can check an
      // answer against — so a read-back is compared with an id held from an earlier call, and that
      // checks two calls agree rather than that either is right. Declared on the read alone: the
      // list takes it from here, so the two cannot answer differently.
      derived: (value) => withRequirementLabel(db, value),
      inputSchema: {
        type: 'object',
        additionalProperties: false,
        properties: { id: { type: 'string', minLength: 1 } },
        required: ['id'],
      },
      handler: (args) => readById(db, 'coverage', args.id, 'read_coverage'),
    }),

    defineTool({
      name: 'update_coverage',
      table: 'coverage',
      description: "Update a coverage row's position, or record its verification.",
      reads: ['coverage'],
      mutates: true,
      serverSupplied: {
        verified_at: SUPPLIED.clock,
        binding_hash: SUPPLIED.derived('the bound texts'),
      },
      inputSchema: {
        type: 'object',
        additionalProperties: false,
        properties: { id: { type: 'string', minLength: 1 }, ...STATE },
        required: ['id'],
      },
      // The mark and its binding move together, in all three of the states a caller can express.
      // Omitting `verified` leaves both alone. `true` hashes off the **stored** row rather than
      // off anything the caller holds: a verification is a statement about the texts as they are
      // now, and a caller working from a copy read earlier would otherwise stamp a hash over text
      // that has since moved. `false` clears the hash with the mark — a binding left behind by an
      // unverification is the stale mark of a verification nobody made.
      //
      // **`verified` is read here and never written**, because it is not a column: the columns are
      // `verified_at` and `binding_hash`, and the boolean is the caller's way of asking for both
      // or for neither.
      handler: ({ id, verified, ...changes }) => {
        if (verified === undefined) {
          return update(db, 'coverage', id, changes, 'update_coverage');
        }

        const stamp = verified
          ? {
            verified_at: now(),
            binding_hash: bindingHash(db, readById(db, 'coverage', id, 'update_coverage')),
          }
          : { verified_at: null, binding_hash: null };

        return update(db, 'coverage', id, { ...changes, ...stamp }, 'update_coverage');
      },
    }),

    defineTool({
      name: 'retire_coverage',
      table: 'coverage',
      description: 'Withdraw a binding, with the reason it was withdrawn. The row stays readable '
        + 'and stops counting toward the requirement. Not reversible through the tools.',
      reads: ['coverage'],
      mutates: true,
      serverSupplied: { retired_at: SUPPLIED.clock },
      inputSchema: {
        type: 'object',
        additionalProperties: false,
        properties: {
          id: { type: 'string', minLength: 1 },
          reason: {
            type: 'string',
            minLength: 1,
            description: 'Why the binding was withdrawn — the fragment was wrong, or the criterion '
              + 'it named was superseded. Required, and the only prose a coverage row carries',
          },
        },
        required: ['id', 'reason'],
      },
      // `additionalProperties: false` over two named arguments is where criterion 3's refusal
      // actually lives: `retired_at` is not reachable from a caller at all, here or through
      // `update_coverage`, so the pair cannot be set half-way or un-set by a mistyped update. The
      // `CHECK` on the table forbids the half state too; this forbids expressing it.
      handler: (args) => {
        const where = 'retire_coverage';
        const row = readById(db, 'coverage', args.id, where);

        // Reported rather than silently restamped, as `retire_taxonomy` does it. Retiring twice is
        // a caller that has lost track, and moving the date would erase when the decision was made.
        if (row.retired_at !== null) {
          throw new ToolError(`${where}: already retired at ${row.retired_at}`);
        }

        // **`verified_at` is left exactly as it stands, and that is the decision rather than an
        // omission.** A ✓ was true of the two texts it was made about, and retiring the binding
        // does not make it untrue — what changes is that the row is no longer offered as live, which
        // `list_coverage`'s derived clause already handles. A retirement that cleared the mark would
        // destroy the record retirement exists to keep, and would do it in the one column a later
        // reader trusts without asking around it.
        return update(db, 'coverage', args.id, {
          retired_at: now(),
          retired_reason: args.reason,
        }, where);
      },
    }),

    // "Covered by: Story 2, Story 4" — a criterion may be delivered by more than the story that
    // declares it. Rare (three rows in a 393-artefact corpus) and real, and the reason it is a
    // join rather than a second `story_id` column on `coverage`.
    ...entityTools({ db, newId }, {
      table: 'coverage_story',
      noun: 'the record that a story also delivers a coverage row',
      key: ['coverage_id', 'story_id'],
      fields: {
        coverage_id: { type: 'string', minLength: 1 },
        story_id: { type: 'string', minLength: 1 },
      },
      // FR14 — the two stories are meant to be doing one epic's work, so a story from another epic
      // delivering this binding is an id from the wrong place.
      guard: (row, where) => refuseCrossEpicDelivery(db)(row, where),
    }),

    defineTool({
      name: 'delete_coverage_story',
      table: 'coverage_story',
      description:
        'Remove the record that a story also delivers a coverage row, returning it as it was. '
        + 'The recovery for a binding attached to the wrong story. The coverage row itself is '
        + 'untouched — this removes the extra delivery, never the binding.',
      reads: ['coverage_story'],
      mutates: true,
      inputSchema: {
        type: 'object',
        additionalProperties: false,
        properties: {
          coverage_id: { type: 'string', minLength: 1 },
          story_id: { type: 'string', minLength: 1 },
        },
        required: ['coverage_id', 'story_id'],
      },
      // **Written here rather than produced by `entityTools`, and deletion stays opt-in.** A
      // `deletable` flag on the factory would hand every join a delete tool, and which rows may be
      // removed rather than withdrawn is a decision per table — `coverage` itself must never have
      // one, and a criterion asserts so. Naming the two tools that do is cheaper than auditing the
      // ones that would.
      //
      // **Named by its key, because it has no id to be named by.** That is the whole of what this
      // story needed from the shared helper: `deleteByKey` in `crud.js`, which `deleteById` now
      // delegates to so the read-before rule lives in one statement rather than two.
      handler: (args) => deleteByKey(db, 'coverage_story', {
        coverage_id: args.coverage_id,
        story_id: args.story_id,
      }, 'delete_coverage_story'),
    }),
  ];
}
