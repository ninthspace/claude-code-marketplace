import { create } from '../fixtures/tool-surface.js';
/**
 * A spec whose coverage is deliberately uneven — the fixture the report has something to say about.
 *
 * `fullCorpus` holds one requirement, one criterion and one binding, which is right for the sweeps
 * that read it and useless here: every list the report returns would be empty or singular, and a
 * count agreeing with an empty list is a green over nothing. The defect this whole story exists to
 * make visible is a miscount, and a miscount needs numbers bigger than one to be wrong by.
 *
 * **Every row goes through a create tool.** The report reads what the tools write, so a fixture
 * assembled by statement would be asserting that the report agrees with the fixture's idea of the
 * schema rather than with the surface a project actually uses.
 *
 * **Each list gets a member and a non-member.** A list that returned everything and a list that
 * returned nothing both pass against a fixture that only plants members, and the two failures look
 * nothing alike from the outside — so the planted absences below are load-bearing, not padding.
 *
 * **Nothing here is addressed by position.** Requirements come back by `label` and criteria by the
 * handle the builder returns, because a fixture indexed into a shared array is extensible only at
 * the tail: inserting a row in the middle silently re-aims an assertion at a different subject, and
 * the suite stays green while doing it.
 */

/**
 * Build the uneven spec.
 *
 * @param {object} call The tool surface, as `handlers(spineTools(db))` returns it.
 * @param {object} [options]
 * @param {string} [options.slug] Distinguishes two corpora in one database, which is what the
 *   statement-count measurement needs: the same shape at two sizes, in one connection.
 * @param {number} [options.filler] Extra fully-bound requirements, each with its own story
 *   criterion and binding. The bound is a claim about growth, so a measurement at one size is a
 *   fact about that size and nothing more.
 * @returns {object} The ids an assertion needs to name what it is about.
 */
export function unevenSpec(call, { slug = 'uneven', filler = 0 } = {}) {
  const spec = call.create_spec({ slug, title: 'A spec covered unevenly' });
  const epic = call.create_epic({ parent_id: spec.id, slug: `${slug}-work`, title: 'The work' });
  const story = call.create_story({
    epic_id: epic.id, number: 1, title: 'Deliver some of it', position: 0,
  });

  // Declared before the helpers that increment it. It worked below them — nothing runs until the
  // first call — but a reader meeting `positions.requirement++` three lines above the declaration
  // has to go looking for it.
  const positions = { requirement: 0, criterion: 0, coverage: 0 };

  const requirement = (label, extra) => call.create_requirement({
    spec_id: spec.id, label, class: 'functional', position: positions.requirement++,
    text: `${label} says something a criterion can quote.`, ...extra,
  });

  const criterion = (text) => call.create_story_criterion({
    story_id: story.id, text, polarity: 'must', position: positions.criterion++,
  });

  const bind = (target, criterionRow, fragment) => call.create_coverage({
    requirement_id: target.id,
    spec_fragment: fragment,
    story_criterion_id: criterionRow.id,
    position: positions.coverage++,
  });

  // --- standing: one requirement at each of the three ------------------------------------------
  // `verified` needs its binding marked, `partial` needs two bindings with one marked, and
  // `unbound` needs a requirement nothing quotes. The three are the criterion's whole subject, so
  // each is built rather than any of them arrived at by leaving something out.
  const verified = requirement('FR1', { moscow: 'must' });
  const partial = requirement('FR2', { moscow: 'must' });
  const unbound = requirement('FR3', { moscow: 'should' });

  const verifiedCriterion = criterion('The verified one is delivered');
  const partialFirst = criterion('The first half of the partial one');
  const partialSecond = criterion('The second half of the partial one');

  const verifiedBinding = bind(verified, verifiedCriterion, 'FR1 says something');
  const partialVerified = bind(partial, partialFirst, 'FR2 says something');
  const partialUnverified = bind(partial, partialSecond, 'a criterion can quote');

  // **The partial requirement carries one of each**, which is what makes `partial` a state rather
  // than a synonym for unverified: a requirement whose bindings are all unverified is still
  // distinguishable from one where some are, and a report collapsing the two would pass against a
  // fixture whose middle requirement had nothing verified at all.
  for (const row of [verifiedBinding, partialVerified]) {
    call.update_coverage({ id: row.id, verified: true });
  }

  // --- unaccounted: one member, and the non-member most easily mistaken for it ------------------
  // Neither carries a binding. The difference is the warrant, and it is the whole of the
  // difference: one is a gap and the other is finished work that had nothing to quote, which is the
  // distinction `src/coverage/warrant.js` exists to draw. A report reading only the coverage rows
  // calls both of them gaps and looks right doing it.
  // The warrant names an **accepted** decision, which the create tool's guard insists on: a
  // proposal nobody agreed to would let a criterion read as accounted for on the strength of a
  // decision that was never taken.
  //
  // **Proposed, then optioned, then accepted — three calls, because the surface refuses the
  // shortcut.** Register entry 8 holds that an accepted ADR has exactly one chosen option, and the
  // guard fires at create. Going the long way round is the point rather than a nuisance: a fixture
  // that reached `accepted` by statement would build a row the tools cannot produce, and this
  // corpus exists to be read by a report that runs against rows the tools did produce.
  const decision = call.create_adr({
    parent_id: spec.id,
    slug: `${slug}-warrant`,
    title: 'Something the story has to do whether or not a requirement says so',
    decision: 'It is done this way.',
  });

  call.create_adr_option({
    adr_id: decision.id, name: 'Do it this way', chosen: true, position: 0,
  });
  call.update_adr({ id: decision.id, decision_status: 'accepted' });

  const unaccounted = criterion('Nothing accounts for this one');
  const warranted = call.create_story_criterion({
    story_id: story.id,
    text: 'An accepted decision accounts for this one',
    polarity: 'must',
    position: positions.criterion++,
    warrant_adr_id: decision.id,
  });

  // --- untagged: the list with no exercise anywhere in the real corpus --------------------------
  // Every other criterion here carries a tag; this one does not. Across all five of this project's
  // own specs the untagged list reads zero, so without a planted member it is a list nothing has
  // ever seen return a row — and an empty list is also what a broken query returns.
  const untagged = criterion('This one carries no approach tag');

  // --- must_have: the non-member that a report ignoring `moscow` would sweep in ------------------
  // Bound, tagged, and serving a `should`. It differs from the must-have criteria in one column.
  const shouldRequirement = requirement('FR4', { moscow: 'should' });
  const shouldOnly = criterion('This one serves a should, not a must');

  bind(shouldRequirement, shouldOnly, 'FR4 says something');

  // **The untagged criterion is bound, so it is a member of one list and not two.** Left unbound it
  // is also unaccounted for — which is true, and common in a real corpus, and wrong for a fixture
  // whose job is to isolate one column at a time: an assertion that the unaccounted list holds one
  // row would then be resting on two facts at once, and a report that confused the two lists would
  // still satisfy it.
  bind(shouldRequirement, untagged, 'says something a criterion can quote');

  for (const row of [verifiedCriterion, partialFirst, partialSecond, unaccounted, warranted,
    shouldOnly]) {
    call.create_story_criterion_approach({ story_criterion_id: row.id, tag: 'integration' });
  }

  for (let index = 0; index < filler; index += 1) {
    const extra = requirement(`FR${100 + index}`, { moscow: 'must' });
    const extraCriterion = criterion(`Filler criterion ${index}`);

    bind(extra, extraCriterion, `FR${100 + index} says something`);
    call.create_story_criterion_approach({ story_criterion_id: extraCriterion.id, tag: 'unit' });
  }

  return {
    spec,
    epic,
    story,
    requirements: { verified, partial, unbound },
    requirementShould: shouldRequirement,
    decision,
    criteria: {
      verified: verifiedCriterion,
      partialFirst,
      partialSecond,
      unaccounted,
      warranted,
      untagged,
      shouldOnly,
    },
    bindings: { verified: verifiedBinding, partialVerified, partialUnverified },
  };
}

/**
 * A spec in which all three of FR9's warnings fire and nothing is a gap.
 *
 * **Separate from `unevenSpec` rather than an option on it**, because the two corpora are built for
 * opposite properties: that one is uneven so the gap lists have members, and this one is *clean* so
 * they do not. Folding them together would give every assertion about a gap list a warning row to
 * trip over, and every assertion about a warning a gap to explain away.
 *
 * The epic here closes cleanly by the rules that exist today — every story criterion is bound or
 * warranted, and every one is tagged — which is what makes it the control the story asks for. All
 * three warnings fire on it, so the claim that none of them is a gap is checked where it matters:
 * on an epic whose close the warnings must not block.
 *
 * Each warning gets a non-member differing in one column: a claim already made, a requirement ruled
 * out of scope, a text repeated under one story rather than two.
 */
export function specWithWarnings(call, { slug = 'warned', db = null } = {}) {
  const spec = call.create_spec({ slug, title: 'A spec with three warnings and no gaps' });
  const epic = call.create_epic({ parent_id: spec.id, slug: `${slug}-work`, title: 'Clean work' });

  const positions = { requirement: 0, criterion: 0, coverage: 0, story: 0 };

  const story = (number, title) => call.create_story({
    epic_id: epic.id, number, title, position: positions.story++,
  });

  const requirement = (label, extra) => call.create_requirement({
    spec_id: spec.id, label, class: 'functional', moscow: 'must', position: positions.requirement++,
    text: `${label} says something a criterion can quote.`, ...extra,
  });

  const criterion = (storyRow, text) => {
    const row = call.create_story_criterion({
      story_id: storyRow.id, text, polarity: 'must', position: positions.criterion++,
    });

    // Tagged as it is made. An untagged criterion here would put a row in a gap list and make the
    // control a corpus that does not close, which is the one thing it has to be.
    call.create_story_criterion_approach({ story_criterion_id: row.id, tag: 'integration' });

    return row;
  };

  const bind = (target, criterionRow, fragment, { verify = true } = {}) => {
    const row = call.create_coverage({
      requirement_id: target.id,
      spec_fragment: fragment,
      story_criterion_id: criterionRow.id,
      position: positions.coverage++,
    });

    if (verify) call.update_coverage({ id: row.id, verified: true });

    return row;
  };

  const first = story(1, 'The first story');
  const second = story(2, 'The second story');

  // --- claimable: every binding verified, claim never made -------------------------------------
  const claimable = requirement('FR1');
  bind(claimable, criterion(first, 'FR1 is delivered'), 'FR1 says something');
  call.create_acceptance_criterion({
    requirement_id: claimable.id, text: 'FR1 holds', polarity: 'must', position: 0,
  });

  // Non-member one: verified throughout *and already claimed*. The claim is the only difference.
  const claimed = requirement('FR2');
  bind(claimed, criterion(first, 'FR2 is delivered'), 'FR2 says something');
  call.create_acceptance_criterion({
    requirement_id: claimed.id, text: 'FR2 holds', polarity: 'must', position: 0,
  });
  call.update_requirement({ id: claimed.id, coverage_claimed: true });

  // Non-member two: unclaimed, but a binding is still unverified. "Every binding verified" is the
  // half a report could drop while still looking like it read the claim.
  const unfinished = requirement('FR3');
  bind(unfinished, criterion(first, 'FR3 is delivered'), 'FR3 says something', { verify: false });
  call.create_acceptance_criterion({
    requirement_id: unfinished.id, text: 'FR3 holds', polarity: 'must', position: 0,
  });

  // --- no acceptance criterion, and in scope ----------------------------------------------------
  // Bound, so it is not a gap by any other reading — the only thing wrong with it is that nobody
  // wrote down how anyone would know it held.
  //
  // **Its bindings are left unverified on purpose**, so it is a member of this warning and of no
  // other. Verified throughout it would also be claimable, and an assertion that the claimable list
  // holds one row would then be resting on two warnings at once.
  const uncriteried = requirement('FR4');
  bind(uncriteried, criterion(second, 'FR4 is delivered'), 'FR4 says something', { verify: false });

  // Non-member: also carries no acceptance criterion, and is ruled out of the iteration. A
  // requirement nobody is delivering is supposed to have none, so the exclusion is the difference.
  // Unbound as well, which keeps it out of the claimable list for the same reason.
  const excluded = requirement('FR5', { moscow: 'should', exclusion: 'out_of_scope' });

  // --- one text, live, under two stories --------------------------------------------------------
  // The two differ in whitespace, which is what the normalisation is for: written a week apart,
  // criteria differ in their line breaks far more often than in their meaning.
  const duplicatedText = 'The same obligation, written twice';
  const here = criterion(first, duplicatedText);
  const there = criterion(second, `The same obligation,\n   written twice  `);

  bind(claimable, here, 'FR1 says something a criterion can quote');
  bind(uncriteried, there, 'FR4 says something a criterion can quote', { verify: false });

  // Non-member: the same text twice under **one** story. That is a different problem with a
  // different owner, and reporting it here would put it under this warning's name.
  //
  // **Written past the tool, because FR13 now refuses it.** Epic 05-02 made a second live criterion
  // with the same text under one story a rejection at the write, so this state arrives only the way
  // a restore brings it — and the warning must still decline to report it, which is what this
  // non-member is here to show. A caller that passes no `db` gets the twin built through the tool
  // and will meet that refusal, which is the honest failure rather than a silent skip.
  const twiceHere = criterion(second, 'Repeated under one story');
  const twiceHereAgain = db
    ? create(db, 'story_criterion', {
      story_id: second.id, text: 'Repeated under one story', polarity: 'must',
      position: positions.criterion++,
    })
    : criterion(second, 'Repeated under one story');

  if (db) {
    call.create_story_criterion_approach({
      story_criterion_id: twiceHereAgain.id, tag: 'integration',
    });
  }

  bind(unfinished, twiceHere, 'FR3 says something a criterion can quote', { verify: false });
  bind(unfinished, twiceHereAgain, 'says something a criterion can quote', { verify: false });

  return {
    spec,
    epic,
    stories: { first, second },
    requirements: { claimable, claimed, unfinished, uncriteried, excluded },
    criteria: { here, there, twiceHere, twiceHereAgain },
    duplicatedText,
  };
}
