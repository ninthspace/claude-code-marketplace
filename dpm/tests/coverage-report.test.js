/**
 * Epic 05-01 Story 1 — the coverage report for one spec (FR5).
 *
 * Two skills compute this in prose today, once each, and the two can disagree without anything
 * noticing. What replaces them has to be checkable in the two ways prose never was: the lists have
 * to discriminate, and the call has to cost the same whatever the corpus holds.
 *
 * **Every list is asserted with a planted member and a planted non-member.** A list that returns
 * everything and a list that returns nothing both pass against a fixture holding only members, and
 * the two defects look identical from outside. The non-members are chosen to differ from the
 * members in exactly one column — a criterion with a warrant against one without, a binding to a
 * `should` against one to a `must` — so what the assertion proves is that the report reads that
 * column rather than something correlated with it.
 *
 * **The bound is measured, not reasoned about.** Criterion 4 is a property of what runs, and a
 * `.map()` that grew a lookup inside it looks exactly like the version that did not. `counting()`
 * is the same instrument spec 03 used for the same shape of claim, and it is used the same way: a
 * count at one size is a fact about that size, so the assertion is that two sizes cost the same.
 *
 * **Reads that feed an assertion pass `include_body`.** A withheld column arrives as `undefined`
 * and compares equal to another absent field, so the comparison passes on the exact defect it was
 * written to catch. That has cost this project three red runs in three separate epics.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { LABEL_FIELD } from '../src/coverage/label.js';
import { coverageReport } from '../src/coverage/report.js';
import { ACCOUNTED_FIELD, withAccountedFor } from '../src/coverage/warrant.js';
import { spineTools } from '../src/tools/index.js';
import { specWithWarnings, unevenSpec } from './support/coverage-corpus.js';
import { handlers, openPlanningDatabase } from './support/planning-database.js';
import { counting } from './support/statements.js';

/** The uneven spec, built through the tool surface the report reads behind. */
function corpus(t, options) {
  const db = openPlanningDatabase(t);

  return { db, fixture: unevenSpec(handlers(spineTools(db)), options) };
}

/** The report for that fixture's spec. */
const reportFor = (db, fixture) => coverageReport(db, { specId: fixture.spec.id });

/** A requirement by its label, never by its position in the returned array. */
const byLabel = (report, label) => report.requirements.find((row) => row.label === label);

/** Whether a list names a criterion, by id. */
const names = (list, criterion) => list.some((row) => row.id === criterion.id);

// --- Criterion 1: every requirement with its standing, from its coverage rows --------------------

test('every requirement comes back with a standing computed from its bindings [integration]', (t) => {
  const { db, fixture } = corpus(t);
  const report = reportFor(db, fixture);

  // Every requirement, including the one nothing binds — which is the one a reader needs most and
  // the one an inner join would drop. Asserted as a set of labels so an added fixture row fails
  // here rather than silently widening what the test is about.
  assert.deepEqual(report.requirements.map((row) => row.label).sort(), ['FR1', 'FR2', 'FR3', 'FR4']);

  const verified = byLabel(report, 'FR1');
  const partial = byLabel(report, 'FR2');
  const unbound = byLabel(report, 'FR3');

  assert.deepEqual(
    { standing: verified.standing, bound: verified.bound, verified: verified.verified },
    { standing: 'verified', bound: 1, verified: 1 },
  );

  // The middle state is the one that has to be distinguishable from both others: bound, so it is
  // not a breakdown's problem, and not fully verified, so it is not finished either.
  assert.deepEqual(
    { standing: partial.standing, bound: partial.bound, verified: partial.verified },
    { standing: 'partial', bound: 2, verified: 1 },
  );

  assert.deepEqual(
    { standing: unbound.standing, bound: unbound.bound, verified: unbound.verified },
    { standing: 'unbound', bound: 0, verified: 0 },
  );

  // **The standing comes from the rows and from nothing on the requirement**, which is checkable
  // by moving a row: verifying the partial one's outstanding binding moves it to `verified`
  // without the requirement itself being touched.
  handlers(spineTools(db)).update_coverage({
    id: fixture.bindings.partialUnverified.id, verified: true,
  });

  assert.equal(byLabel(reportFor(db, fixture), 'FR2').standing, 'verified',
    'the standing did not follow the coverage rows');
});

// --- Criterion 2: the three lists, each with a member and a non-member ---------------------------

test('the three lists each discriminate, member against non-member [integration]', (t) => {
  const { db, fixture } = corpus(t);
  const report = reportFor(db, fixture);
  const { criteria } = fixture;

  // **Unaccounted.** Neither of these two carries a binding; the warrant is the only difference,
  // and it is what separates a gap from finished work that had nothing to quote.
  assert.equal(names(report.unaccounted, criteria.unaccounted), true,
    'a criterion with neither a binding nor a warrant was not reported as unaccounted for');
  assert.equal(names(report.unaccounted, criteria.warranted), false,
    'a criterion warranted by an accepted decision was reported as a gap');
  assert.equal(names(report.unaccounted, criteria.verified), false,
    'a criterion carrying a live binding was reported as unaccounted for');

  // **Untagged.** This list reads zero on every one of this project's own specs, so the planted
  // member is the only thing that has ever made it return a row.
  assert.equal(names(report.untagged, criteria.untagged), true,
    'a criterion carrying no approach tag was not reported');
  assert.equal(names(report.untagged, criteria.verified), false,
    'a tagged criterion was reported as untagged');

  // **Must-have.** The non-member differs in one column: its binding reaches a `should`. A report
  // that listed every bound criterion would sweep it in and look right doing it.
  assert.equal(names(report.must_have, criteria.verified), true,
    'a criterion bound to a must-have requirement was not reported as one');
  assert.equal(names(report.must_have, criteria.shouldOnly), false,
    'a criterion bound only to a should-have requirement was reported as a must-have');

  // **The rule this report reads set-wise is the one `warrant.js` reads per row**, and the two are
  // compared on the same criteria rather than trusted to agree. Two readings of one rule is how a
  // rule stops being one rule, which is the whole reason this report exists.
  const stored = db.prepare('SELECT * FROM story_criterion WHERE story_id = ?').all(fixture.story.id);
  const perRow = withAccountedFor(db, { items: stored }).items;
  const unaccountedHere = new Set(report.unaccounted.map((row) => row.id));

  for (const row of perRow) {
    assert.equal(unaccountedHere.has(row.id), !row[ACCOUNTED_FIELD],
      `the two readings disagree about ${row.text}`);
  }
});

test('a criterion is named by its text, which is the only thing that names it [integration]', (t) => {
  const { db, fixture } = corpus(t);
  const entry = reportFor(db, fixture).unaccounted.find(
    (row) => row.id === fixture.criteria.unaccounted.id,
  );

  // A criterion has no title, so a report listing ids names nothing anyone can act on. Compared
  // against the text the create tool returned rather than against a literal repeated here.
  assert.equal(entry.text, fixture.criteria.unaccounted.text);
  assert.equal(entry.story_id, fixture.story.id);
});

// --- Criterion 3: every number agrees with the list it summarises --------------------------------

test('every count agrees with what it summarises [unit]', (t) => {
  const { db, fixture } = corpus(t);
  const report = reportFor(db, fixture);

  // Compared against the lengths of the arrays in the same response, which is the comparison that
  // would have caught the miscount this criterion is written from — a run reporting twelve of
  // twelve over thirteen rows, two computations of one number agreeing until they did not.
  assert.equal(report.counts.requirements, report.requirements.length);
  assert.equal(report.counts.unaccounted, report.unaccounted.length);
  assert.equal(report.counts.untagged, report.untagged.length);
  assert.equal(report.counts.must_have, report.must_have.length);
  assert.equal(report.counts.bound, report.requirements.filter((row) => row.bound > 0).length);
  assert.equal(report.counts.unbound, report.requirements.filter((row) => row.bound === 0).length);

  // **And against the fixture, which is the half that catches a report agreeing with itself.** A
  // response whose every field came from one broken query is internally consistent; these numbers
  // are what the corpus was built to hold. Four requirements, three of them bound, five bindings of
  // which one is verified, seven criteria — every planted member belongs to exactly one list, so a
  // report that confused two of them fails here rather than passing on an overlap.
  assert.deepEqual(report.counts, {
    requirements: 4,
    bound: 3,
    unbound: 1,
    bindings: 5,
    verified_bindings: 2,
    criteria: 7,
    unaccounted: 1,
    untagged: 1,
    must_have: 3,
  });
});

// --- Criterion 4: one call, and no per-requirement read behind it --------------------------------

test('the report costs the same whatever the spec holds [integration]', (t) => {
  const counted = counting(openPlanningDatabase(t));
  const call = handlers(spineTools(counted.db));

  // Two corpora in one connection, so the measurement is of the report and not of two databases.
  const small = unevenSpec(call, { slug: 'small' });
  const large = unevenSpec(call, { slug: 'large', filler: 20 });

  const cost = (fixture) => {
    counted.reset();
    coverageReport(counted.db, { specId: fixture.spec.id });

    return counted.statements();
  };

  const smallCost = cost(small);
  const largeCost = cost(large);

  // The corpus really is bigger, or the equality below is a claim about two identical things.
  const largeReport = coverageReport(counted.db, { specId: large.spec.id });
  const smallReport = coverageReport(counted.db, { specId: small.spec.id });

  assert.equal(smallReport.counts.requirements, 4);
  assert.equal(largeReport.counts.requirements, 24, 'the large corpus is not larger');

  // **Equal, not merely small.** A per-requirement lookup fails this by the amount it costs and the
  // message says what the amount was, which is the difference between a control and a coincidence.
  // The mutation was run: moving the standings onto a lookup per requirement took the larger figure
  // from 10 to 50 — two statements for each of the twenty extra requirements — so the failure scales
  // with the corpus rather than being a fixed penalty.
  assert.equal(smallCost, largeCost,
    `the report cost ${largeCost} statements against 24 requirements and ${smallCost} against 4 `
    + `— a difference of ${largeCost - smallCost} means a read per requirement rather than per spec`);

  // **The epic-scoped call is measured too, and that is the scope the requirement names.** NFR3 is
  // about *a closing coverage summary for one epic*, which is the call a run actually makes at the
  // end of an epic — and it is a different code path from the spec-scoped one measured above. The
  // roll-up costs a fixed two statements more whatever the epic holds, so the bound is the same
  // claim at the scope that motivated it.
  const scopedCost = (fixture) => {
    counted.reset();
    coverageReport(counted.db, { specId: fixture.spec.id, epicId: fixture.epic.id });

    return counted.statements();
  };

  const smallScoped = scopedCost(small);
  const largeScoped = scopedCost(large);

  assert.equal(smallScoped, largeScoped,
    `the epic summary cost ${largeScoped} statements against 24 requirements and ${smallScoped} `
    + 'against 4 — the scope NFR3 names is the one a run pays at an epic close');

  assert.equal(largeScoped, largeCost + 2, 'the roll-up should cost exactly its two queries');
});

// --- Story 2, criterion 1: the roll-up an epic adds ----------------------------------------------

test('naming an epic adds a roll-up and narrows nothing else [integration]', (t) => {
  const { db, fixture } = corpus(t);

  const wide = reportFor(db, fixture);
  const scoped = coverageReport(db, { specId: fixture.spec.id, epicId: fixture.epic.id });

  // **The spec-level half is identical.** An epic argument that quietly filtered the requirements
  // would answer a different question under the same field names, and a skill quoting `counts`
  // would report an epic's figures as the spec's without anything looking wrong.
  assert.deepEqual(scoped.counts, wide.counts);
  assert.deepEqual(scoped.requirements, wide.requirements);

  // One shape either way: absent is `null`, not missing, so a consumer reads the same field.
  assert.equal(wide.epic, null, 'a report nobody scoped to an epic carried a roll-up');

  assert.equal(scoped.epic.epic_id, fixture.epic.id);
  assert.deepEqual(scoped.epic.stories.map((row) => row.number), [1]);
  assert.equal(scoped.epic.counts.stories, 1);

  // Verified is a subset of bound, and the fixture makes the two different numbers — equal ones
  // would be satisfied by a roll-up that returned the same figure twice.
  assert.equal(scoped.epic.counts.bindings, 5);
  assert.equal(scoped.epic.counts.verified_bindings, 2);
});

test('an epic is credited with its own bindings, not its neighbours [integration]', (t) => {
  const { db, fixture } = corpus(t);
  const call = handlers(spineTools(db));

  // A second epic under the same spec, binding the same requirement. The requirement belongs to the
  // spec and is shared; the binding belongs to whichever epic's criterion quotes it. A roll-up
  // counting by requirement would credit both epics with both rows.
  const neighbour = call.create_epic({
    parent_id: fixture.spec.id, slug: 'neighbour', title: 'Another epic entirely',
  });
  const story = call.create_story({
    epic_id: neighbour.id, number: 1, title: 'Work under the neighbour', position: 0,
  });
  const criterion = call.create_story_criterion({
    story_id: story.id, text: 'The neighbour delivers some of FR1 too', polarity: 'must', position: 0,
  });

  call.create_coverage({
    requirement_id: fixture.requirements.verified.id,
    spec_fragment: 'FR1 says something a criterion can quote',
    story_criterion_id: criterion.id,
    position: 9,
  });

  const mine = coverageReport(db, { specId: fixture.spec.id, epicId: fixture.epic.id });
  const theirs = coverageReport(db, { specId: fixture.spec.id, epicId: neighbour.id });

  assert.equal(mine.epic.counts.bindings, 5, 'the original epic was credited with a neighbour row');
  assert.equal(theirs.epic.counts.bindings, 1, 'the neighbour was credited with more than its own');

  // The spec-level total sees both, which is what makes the two figures different questions rather
  // than the same one asked twice.
  assert.equal(mine.counts.bindings, 6);
});

// --- Story 2, criterion 2: thirteen bindings, and the numbers agree ------------------------------

test('on a fixture of thirteen bindings the roll-up says thirteen [unit]', (t) => {
  const db = openPlanningDatabase(t);
  const call = handlers(spineTools(db));

  // Five from the uneven shape and eight fillers. Thirteen is the criterion's own number, and the
  // miscount behind it was a run reporting twelve of twelve over thirteen rows — so the figure is
  // asserted against the rows in the table as well as against the fixture's arithmetic.
  const fixture = unevenSpec(call, { slug: 'thirteen', filler: 8 });
  const report = coverageReport(db, { specId: fixture.spec.id, epicId: fixture.epic.id });

  const inTheTable = db.prepare(`
    SELECT count(*) AS n FROM coverage c
      JOIN story_criterion sc ON sc.id = c.story_criterion_id
      JOIN story s ON s.id = sc.story_id
     WHERE s.epic_id = ? AND c.retired_at IS NULL`).get(fixture.epic.id).n;

  assert.equal(inTheTable, 13, 'the fixture does not hold thirteen bindings');
  assert.equal(report.epic.counts.bindings, 13);

  // **And it agrees with the list it summarises.** The stories count is the length of the list
  // returned beside it, which is the property that makes the block quotable: a skill reading the
  // number and a skill reading the rows cannot render different answers.
  assert.equal(report.epic.counts.stories, report.epic.stories.length);
  assert.equal(report.epic.counts.verified_bindings, 2);

  // The spec-level block agrees with the same rows from the other direction — every binding here
  // belongs to the one epic, so the two totals coincide, and a divergence would mean one of the two
  // queries has drifted from the other.
  assert.equal(report.counts.bindings, 13);
});

// --- Story 3, criteria 1-3: the three warnings, each member against non-member -------------------

/** The clean spec on which all three warnings fire. */
function warned(t) {
  const db = openPlanningDatabase(t);
  const fixture = specWithWarnings(handlers(spineTools(db)), { db });

  return { db, fixture, report: coverageReport(db, { specId: fixture.spec.id, epicId: fixture.epic.id }) };
}

/** Whether a warning list names a requirement, by id. */
const warns = (list, requirement) => list.some((row) => row.id === requirement.id);

test('a requirement verified throughout and never claimed is reported as claimable [integration]', (t) => {
  const { fixture, report } = warned(t);
  const { claimable } = report.warnings;

  assert.equal(warns(claimable, fixture.requirements.claimable), true,
    'a requirement whose every binding is verified and whose claim was never made was not reported');

  // The claim is the only difference between this one and the member above.
  assert.equal(warns(claimable, fixture.requirements.claimed), false,
    'a requirement whose claim was already made was reported as claimable');

  // And this one differs only in having a binding still unverified — "every binding verified" is
  // the half a report could drop while still looking like it had read the claim.
  assert.equal(warns(claimable, fixture.requirements.unfinished), false,
    'a requirement carrying an unverified binding was reported as claimable');

  // **A requirement nothing binds must not be claimable either**, which no fixture row above
  // catches: "every binding is verified" is vacuously true of no bindings, and the warning would
  // invite a claim that the fragments account for a requirement no fragment quotes.
  assert.equal(warns(claimable, fixture.requirements.excluded), false,
    'a requirement with no bindings satisfied "every binding verified" vacuously');
});

test('an in-scope requirement with no acceptance criterion is reported [integration]', (t) => {
  const { fixture, report } = warned(t);
  const { no_criterion: noCriterion } = report.warnings;

  assert.equal(warns(noCriterion, fixture.requirements.uncriteried), true,
    'an in-scope requirement carrying no acceptance criterion was not reported');

  // Ruled out of the iteration, and carrying none for that reason. The exclusion is the only
  // difference between the two.
  assert.equal(warns(noCriterion, fixture.requirements.excluded), false,
    'a requirement ruled out of scope was reported for carrying no criterion');

  assert.equal(warns(noCriterion, fixture.requirements.claimable), false,
    'a requirement that does carry an acceptance criterion was reported');

  // **The state is invisible to any gap computed from criteria**, which is the criterion's own
  // claim and is structural rather than incidental: a gap is a criterion nothing accounts for, and
  // this requirement contributes no criteria to that population at all. Asserted by showing the gap
  // list is empty on the very corpus where this warning fires.
  assert.deepEqual(report.unaccounted, [],
    'the corpus has gaps, so the claim that this state is invisible to them is untested here');
});

test('one criterion text live under two stories is reported as duplicated [integration]', (t) => {
  const { fixture, report } = warned(t);
  const { duplicated } = report.warnings;

  assert.equal(duplicated.length, 1, 'expected exactly the planted duplicate');

  const [entry] = duplicated;

  // Normalised, so the pair is found although one of them carries a line break and trailing spaces.
  // An exact comparison finds almost none of the duplicates this exists to find.
  assert.equal(entry.text, fixture.duplicatedText);
  assert.deepEqual(
    entry.criteria.map((row) => row.id).sort(),
    [fixture.criteria.here.id, fixture.criteria.there.id].sort(),
  );

  // Two stories, not one — which is what the rule is about.
  assert.equal(new Set(entry.criteria.map((row) => row.story_id)).size, 2);

  // The non-member: the same text twice under one story. That is a different problem with a
  // different owner, and reporting it here would put it under this warning's name.
  const underOneStory = duplicated.some(
    (row) => row.criteria.some((entryRow) => entryRow.id === fixture.criteria.twiceHere.id),
  );

  assert.equal(underOneStory, false, 'a text repeated under one story was reported as duplicated');
});

// --- Story 3, criterion 4 (must NOT): none of the three is a gap ---------------------------------

test('must NOT — a warning is reported as a gap [integration]', (t) => {
  const { fixture, report } = warned(t);

  // **The refused thing is read first**, and the rest of this test is its control rather than a
  // second subject. A rejection sharing a test with the positive it complements is only verified
  // when the mutation happens to fail the rejection's assertion first, and assertion order inside a
  // test is not something to depend on.
  const gaps = new Set([
    ...report.unaccounted.map((row) => row.id),
    ...report.untagged.map((row) => row.id),
  ]);

  const warnedRequirements = [
    fixture.requirements.claimable.id,
    fixture.requirements.uncriteried.id,
  ];
  const warnedCriteria = report.warnings.duplicated.flatMap((row) => row.criteria.map((c) => c.id));

  for (const id of [...warnedRequirements, ...warnedCriteria]) {
    assert.equal(gaps.has(id), false, `${id} was warned about and also reported as a gap`);
  }

  for (const rows of [report.warnings.claimable, report.warnings.no_criterion,
    report.warnings.duplicated]) {
    assert.ok(rows.length > 0, 'a warning did not fire, so the absence above proves nothing');
  }

  // The control, asserted afterwards and only as a control: the three warnings did fire, so the
  // absence above is the rejection holding rather than the warnings never having been computed.
  //
  // **Non-empty rather than an exact count, deliberately.** Pinned to `{1, 1, 1}` this line made
  // the rejection fail on every mutation that changed *which* rows a warning holds — so the
  // rejection went red for somebody else's reason and its own evidence was never tested. The
  // mutations were run and that is how it was found. What the rejection needs from the control is
  // only that the warnings were computed at all.
});

// --- Story 3, criterion 5 (control): the epic still closes ---------------------------------------

test('an epic that closed cleanly before the warnings existed still closes [integration]', (t) => {
  const { report } = warned(t);

  // **Its own rows, not the rejection's.** A control living inside another criterion's test reads
  // as verified whenever that criterion is the one that moved, and this one has to answer a
  // question the rejection cannot: not merely that the warnings are kept out of the gap lists, but
  // that an epic whose close depends on those lists still closes with all three firing.
  assert.deepEqual(report.unaccounted, [], 'a criterion is unaccounted for, so this epic would not close');
  assert.deepEqual(report.untagged, [], 'a criterion is untagged, so this epic would not close');

  // All three firing, on the same corpus, at the same moment. Without this the assertions above are
  // satisfied by a spec that simply has nothing wrong with it.
  for (const [warning, rows] of [
    ['claimable', report.warnings.claimable],
    ['no_criterion', report.warnings.no_criterion],
    ['duplicated', report.warnings.duplicated],
  ]) {
    assert.ok(rows.length > 0, `${warning} did not fire, so this epic closing proves nothing`);
  }
});

// --- Story 4: the requirement label on coverage rows --------------------------------------------

test('a coverage row read back names its requirement by label [integration]', (t) => {
  const { db, fixture } = corpus(t);
  const call = handlers(spineTools(db));

  // **Checked against a label, which is the whole point of the field.** The alternative is holding
  // an id from the create call and comparing against that, which shows the two calls agree rather
  // than that either named the right requirement.
  const row = call.read_coverage({ id: fixture.bindings.verified.id, include_body: true });

  assert.equal(row[LABEL_FIELD], 'FR1');

  // The list answers the same, because it takes the derivation from the read tool rather than
  // computing its own — two implementations of one rule being the failure this shares with the
  // body columns beside it.
  const page = call.list_coverage({ requirement_id: fixture.requirements.partial.id });

  assert.deepEqual(page.items.map((item) => item[LABEL_FIELD]), ['FR2', 'FR2']);

  // **A label is not an id.** Without this the assertions above are satisfied by a field that
  // echoed `requirement_id` back under a friendlier name.
  assert.notEqual(row[LABEL_FIELD], row.requirement_id);

  // It follows the requirement rather than a copy taken at bind time: relabelling moves it, which a
  // stored column would not do without something remembering to update it.
  call.update_requirement({ id: fixture.requirements.verified.id, label: 'FR1a' });

  assert.equal(call.read_coverage({ id: fixture.bindings.verified.id })[LABEL_FIELD], 'FR1a');
});

test('the rows the report returns carry the label too [integration]', (t) => {
  const { db, fixture } = corpus(t);
  const report = coverageReport(db, { specId: fixture.spec.id, epicId: fixture.epic.id });

  // Same field name as the read path, which is what makes it one field rather than two that happen
  // to mean the same thing. A skill quoting it does not need to know which call produced the row.
  for (const binding of report.epic.bindings) {
    assert.ok(binding[LABEL_FIELD], 'a binding the report returned carries no requirement label');
  }

  // And it is the right label, not merely present — asserted against the labels the fixture's
  // requirements actually carry rather than against a count.
  assert.deepEqual(
    [...new Set(report.epic.bindings.map((row) => row[LABEL_FIELD]))].sort(),
    ['FR1', 'FR2', 'FR4'],
  );

  // The unverified ones are nameable, which is what a run closing an epic needs the field for.
  assert.deepEqual(
    report.epic.bindings.filter((row) => row.verified_at === null).map((row) => row[LABEL_FIELD]),
    ['FR2', 'FR4', 'FR4'],
  );
});

test('the skill that quotes the label names the field, because no sweep can [unit]', () => {
  // **This is the field's only pressure and the test says so.** A value computed after the read
  // reaches neither the schema nor the tool registry, so every derived sweep in this suite is blind
  // to it: nothing here would notice if the derivation were deleted except the tests in this file
  // and the skill sentence that consumes it. That makes the sentence load-bearing rather than
  // documentation, which is why it is asserted rather than assumed.
  const skill = readFileSync(new URL('../skills/do/SKILL.md', import.meta.url), 'utf8');

  assert.ok(skill.includes('`' + LABEL_FIELD + '`'),
    'the skill that reports what it verified no longer names the label field');

  // The control: the assertion is about this field rather than about the file being non-empty, and
  // a name the field does not have is not found in the same text.
  assert.equal(skill.includes('`requirement_name`'), false);
});

// --- Story 5: the seams no single story can see from inside itself -------------------------------

test('the response is one shape whichever scope was asked for [integration]', (t) => {
  const { db, fixture } = corpus(t);

  const wide = reportFor(db, fixture);
  const scoped = coverageReport(db, { specId: fixture.spec.id, epicId: fixture.epic.id });

  // **The same top-level keys either way.** A field that appears only when an epic was named makes
  // a consuming skill test for its existence before reading it, and the skill that forgets renders
  // an absence — which reads as a section that was not needed rather than as a question not asked.
  assert.deepEqual(Object.keys(wide).sort(), Object.keys(scoped).sort());

  // **The shape is pinned here, and that is deliberate rather than brittle.** The counts block
  // exists so a skill quotes a number instead of deriving one, which makes every field name a
  // promise: renaming one breaks a consuming skill silently, because a skill quoting a count that
  // is no longer there renders nothing and nothing reports an error. This test is where that
  // promise is kept.
  assert.deepEqual(Object.keys(wide.counts).sort(), [
    'bindings', 'bound', 'criteria', 'must_have', 'requirements', 'unaccounted', 'unbound',
    'untagged', 'verified_bindings',
  ]);

  assert.deepEqual(Object.keys(scoped.epic).sort(), ['bindings', 'counts', 'epic_id', 'stories']);
  assert.deepEqual(Object.keys(scoped.epic.counts).sort(),
    ['bindings', 'stories', 'verified_bindings']);

  // **One field name per question, across the two scopes.** A skill asking how many bindings were
  // verified reads `verified_bindings` whichever block it is holding, so the sentence it renders
  // does not have to know which call produced the number.
  for (const shared of ['bindings', 'verified_bindings']) {
    assert.ok(shared in wide.counts && shared in scoped.epic.counts,
      `${shared} is named differently at the two scopes`);
  }

  // And the two answer about different populations, which is what makes them worth having both:
  // equal figures here would mean the epic block was a copy rather than a roll-up.
  assert.equal(wide.counts.bindings, scoped.epic.counts.bindings,
    'this fixture has one epic, so the two totals should coincide');
});

test('naming an epic does not narrow the spec-level lists [integration]', (t) => {
  const { db, fixture } = corpus(t);
  const call = handlers(spineTools(db));

  // **A second epic, because with one epic the claim is untestable.** Scoping to the only epic
  // there is filters nothing, so every assertion that an epic argument "narrows nothing else"
  // passes against a report that narrows everything. The mutation was run: filtering the criteria
  // by epic survived the whole suite until this fixture existed.
  const other = call.create_epic({
    parent_id: fixture.spec.id, slug: 'elsewhere', title: 'Work under another epic',
  });
  const story = call.create_story({
    epic_id: other.id, number: 1, title: 'Elsewhere', position: 0,
  });

  call.create_story_criterion({
    story_id: story.id, text: 'A criterion belonging to the other epic', polarity: 'must',
    position: 0,
  });

  const wide = reportFor(db, fixture);
  const scoped = coverageReport(db, { specId: fixture.spec.id, epicId: fixture.epic.id });

  // The other epic's criterion is unaccounted for and untagged, so it shows in both lists — and it
  // must show whichever epic the caller happened to name.
  assert.equal(wide.counts.criteria, scoped.counts.criteria);
  assert.deepEqual(wide.unaccounted, scoped.unaccounted);
  assert.deepEqual(wide.untagged, scoped.untagged);
  assert.deepEqual(wide.must_have, scoped.must_have);

  // The control: the fixture really does span two epics, or the equalities above are about one.
  assert.equal(new Set(
    db.prepare(`SELECT s.epic_id FROM story_criterion sc JOIN story s ON s.id = sc.story_id
                 JOIN document e ON e.id = s.epic_id WHERE e.parent_id = ?`)
      .all(fixture.spec.id).map((row) => row.epic_id),
  ).size, 2, 'the fixture does not span two epics, so nothing above was narrowed');
});

test('the warnings sit beside the standings and move none of them [integration]', (t) => {
  const { db, fixture, report } = warned(t);

  // Both present in one response — the whole point of the report being one call.
  assert.ok(report.requirements.length > 0 && report.warnings.counts.claimable > 0);

  // **No standing moved.** Checked against the rows rather than against another run of the same
  // code: the standings are recomputed here straight from `coverage`, so a warning that had
  // perturbed one would disagree with the table rather than merely with itself.
  for (const requirement of report.requirements) {
    const rows = db.prepare(
      'SELECT verified_at FROM coverage WHERE requirement_id = ? AND retired_at IS NULL',
    ).all(requirement.id);

    const verified = rows.filter((row) => row.verified_at !== null).length;

    assert.equal(requirement.bound, rows.length, `${requirement.label} bound count moved`);
    assert.equal(requirement.verified, verified, `${requirement.label} verified count moved`);
  }

  // The requirement every warning names is still reported with an ordinary standing, rather than
  // being displaced into the warning and out of the list a reader counts.
  const claimable = report.requirements.find(
    (row) => row.id === fixture.requirements.claimable.id,
  );

  assert.equal(claimable.standing, 'verified');
  assert.equal(claimable.claimed, false, 'the claimable one is reported as already claimed');
});
