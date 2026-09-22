/**
 * Epic 05-03 Story 2 — the requirement's coverage claim is dated by the server (FR1).
 *
 * The same swap Story 1 made one level down, and the reason is the same one level up. A coverage
 * row's ✓ says a fragment was checked; a *claim* says the bound set accounts for the requirement
 * whole — the judgement a human makes and the date a spec's completeness is read off. Supplied by
 * the caller, that date was a plausible value nobody read off a clock, and nothing downstream could
 * tell it from a real one.
 *
 * **The hash was already the server's, which is what makes this the last half rather than a new
 * rule.** `claimComplete` has never accepted a digest: a digest chosen by the party making the
 * claim records nothing. The time was the remaining thing a caller could choose about their own
 * claim, and after this story it is not.
 *
 * **The clock is pinned to an instant this file passes as an argument nowhere**, for Story 1's
 * reason — "the claim holds the server's clock" checked against a value the test also supplies is
 * satisfied by a handler that stored the caller's string.
 *
 * **And the claim is still read after the edits, never before.** `requirement_unclaim_on_text_edit`
 * clears a claim written first, so a call that amends the text *and* claims in one go must end
 * claimed. That ordering predates this story and the swap could quietly break it, so it is driven
 * here rather than assumed.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { openPlanningDatabase as planning, handlers } from './support/planning-database.js';
import { spineTools } from '../src/tools/index.js';
import { claimHash, claimState } from '../src/coverage/claim.js';

/** What the pinned server clock reads. Passed as an argument nowhere below. */
const CLOCK = '2026-09-21T17:31:49.663Z';

/** A time a caller might invent, and the one the must-NOT tries to supply. */
const SUPPLIED = '2026-01-01T00:00:00.000Z';

const TEXT = 'The server supplies the clock for a requirement\'s coverage claim.';

/** A requirement with two bindings beneath it, and the surface that made them. */
function surface(t) {
  const db = planning(t);
  const tools = spineTools(db, { now: () => CLOCK });
  const call = handlers(tools);

  const spec = call.create_spec({ slug: 'claims', title: 'Server-supplied stamps' });
  const epic = call.create_epic({ parent_id: spec.id, slug: 'clock', title: 'The clock' });
  const story = call.create_story({ epic_id: epic.id, number: 1, title: 'Claim it', position: 0 });
  const requirement = call.create_requirement({
    spec_id: spec.id, label: 'FR1', class: 'functional', position: 0, text: TEXT,
  });

  // Two, because a claim is about a *set*: with one binding, "the digest covers what is bound"
  // cannot be told from "the digest covers the only row there is".
  ['The server supplies the clock', "a requirement's coverage claim"].forEach((fragment, position) => {
    const criterion = call.create_story_criterion({
      story_id: story.id, text: `Criterion ${position}`, polarity: 'must', position,
    });

    call.create_coverage({
      requirement_id: requirement.id,
      spec_fragment: fragment,
      story_criterion_id: criterion.id,
      position,
    });
  });

  return { db, tools, call, requirement };
}

/** Run something expected to be refused, and hand back the error it raised. */
function refused(run, message) {
  let caught;

  try {
    run();
  } catch (error) {
    caught = error;
  }

  assert.ok(caught, message ?? 'the call was accepted when it should have been refused');

  return caught;
}

// --- Criterion 1 (must): the claim is dated by the clock, hashed over the bound set ---------------

test('a claim supplying no time is dated by the server\'s clock [integration]', (t) => {
  const { db, call, requirement } = surface(t);

  const claimed = call.update_requirement({ id: requirement.id, coverage_claimed: true });

  assert.equal(claimed.coverage_claimed_at, CLOCK, 'the claim is not dated by the clock');

  // **The digest over the bound set, recomputed here rather than taken from the row**, so a change
  // to what is hashed fails this instead of agreeing with itself.
  assert.equal(claimed.coverage_claim_hash, claimHash(db, requirement.id),
    'the hash is not over the fragment set the claim is about');

  assert.deepEqual(claimState(db, requirement.id), { claimed: true, current: true, bound: 2 });

  // **And the claim is still written after the edits.** `requirement_unclaim_on_text_edit` clears
  // a claim written first, so amending and claiming in one call must end claimed — an ordering
  // this swap could have broken by reading the clock at the top of the handler and writing early.
  const together = call.update_requirement({
    id: requirement.id,
    text: `${TEXT} Neither tool accepts a time from its caller.`,
    coverage_claimed: true,
  });

  assert.equal(together.coverage_claimed_at, CLOCK,
    'the claim was written before the text edit that clears it');
  assert.equal(claimState(db, requirement.id).claimed, true);
});

// --- Criterion 2 (must NOT): a supplied time is not accepted and not stored ------------------------

test('must NOT — a call supplying a time for a coverage claim is accepted [integration]', (t) => {
  const { db, call, requirement } = surface(t);

  // Read for the argument's name and never for the sentence: `additionalProperties: false`
  // generates this message, and FR23 will reword it to list the arguments the tool does accept.
  assert.match(
    refused(() => call.update_requirement({
      id: requirement.id, coverage_claimed_at: SUPPLIED,
    }), 'a caller chose the date of its own completeness claim').message,
    /coverage_claimed_at/,
  );

  // The columns, not the throw. A refusal after the write would satisfy an exception check and
  // leave a claim dated by whoever made it.
  const stored = db
    .prepare('SELECT coverage_claimed_at, coverage_claim_hash FROM requirement WHERE id = ?')
    .get(requirement.id);

  assert.equal(stored.coverage_claimed_at, null);
  assert.equal(stored.coverage_claim_hash, null);

  // The digest is refused with it, and was before this story — asserted here because the two are
  // one pair and a swap that reopened either half would be the same failure.
  refused(() => call.update_requirement({ id: requirement.id, coverage_claim_hash: 'a'.repeat(64) }),
    'a caller chose the digest that vouches for its own claim');

  // And a claim already standing is unmoved by the refusal.
  call.update_requirement({ id: requirement.id, coverage_claimed: true });
  refused(() => call.update_requirement({ id: requirement.id, coverage_claimed_at: SUPPLIED }));

  assert.equal(call.read_requirement({ id: requirement.id }).coverage_claimed_at, CLOCK);
});

// --- Criterion 3 (control): the same call with the time omitted records the claim ------------------

test('control — the same call with `coverage_claimed` records the claim [integration]', (t) => {
  const { db, call, requirement } = surface(t);

  // The rejection's own call, differing in one argument. Without this the refusal above is equally
  // satisfied by a tool that refused every claim.
  assert.equal(
    call.update_requirement({ id: requirement.id, coverage_claimed: true }).coverage_claimed_at,
    CLOCK,
  );

  // **`false` withdraws, and takes the hash with it** — the third state, and the one a swap that
  // read the boolean as "claim if truthy" would have dropped. A digest beside a requirement
  // claiming nothing is the pair the `CHECK` forbids.
  const withdrawn = call.update_requirement({ id: requirement.id, coverage_claimed: false });

  assert.equal(withdrawn.coverage_claimed_at, null);
  assert.equal(withdrawn.coverage_claim_hash, null);
  assert.equal(claimState(db, requirement.id).claimed, false);

  // **Omitting it leaves the claim alone**, which is what makes withdrawal a decision rather than
  // a side effect of editing the row's position.
  call.update_requirement({ id: requirement.id, coverage_claimed: true });
  const moved = call.update_requirement({ id: requirement.id, position: 4 });

  assert.equal(moved.position, 4);
  assert.equal(moved.coverage_claimed_at, CLOCK, 'an unrelated edit disturbed the claim');
  assert.ok(moved.coverage_claim_hash);

  // A call carrying neither is still refused as nothing to do, which is the behaviour the boolean
  // replaced an `undefined` check to keep.
  refused(() => call.update_requirement({ id: requirement.id }), 'an empty update was accepted');
});

// --- The declaration, which is what a caller is shown ---------------------------------------------

test('update_requirement declares both halves of the claim as the server\'s [unit]', (t) => {
  const { tools } = surface(t);
  const tool = tools.find((entry) => entry.name === 'update_requirement');
  const properties = tool.inputSchema.properties;

  assert.equal('coverage_claimed_at' in properties, false,
    'the caller is still offered the date of its own claim');
  assert.equal('coverage_claim_hash' in properties, false);
  assert.equal(properties.coverage_claimed?.type, 'boolean');

  assert.equal(tool.serverSupplied.coverage_claimed_at, 'clock');
  assert.equal(tool.serverSupplied.coverage_claim_hash, 'derived from the bound fragment set');

  // **`create_requirement` offers neither, and that is not this story's doing.** A requirement is
  // never born claimed — there is nothing bound to it yet — so the boolean would have one honest
  // value. Asserted because the swap passed through the same file and the cheap way to make both
  // tools agree would have been to put the argument on both.
  const create = tools.find((entry) => entry.name === 'create_requirement');

  assert.equal('coverage_claimed' in create.inputSchema.properties, false,
    'a requirement can now be born claiming a set it has no bindings in');
});
