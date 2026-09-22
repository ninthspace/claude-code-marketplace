/**
 * Epic 05-06 Story 1 — a shared rule reaches the runs it was written for (ADR 05-05).
 *
 * The epic's own shaping note states the failure: the ban on speaking a document id aloud sat in
 * its own shared section from 0.6.0 and went on being broken, because **one** skill of twenty-three
 * cited that section. The rule existed, was well worded, and reached nothing.
 *
 * So placement is a count, and the count is asserted rather than trusted. ADR 05-05 decides the
 * rule — a rule goes in the shared section its consumers already cite, and only a rule with one or
 * two consumers goes in those skills' own bodies — and this file is the sweep that holds it.
 *
 * **Both directions, over the whole corpus.** A sweep over the skills a story happened to edit
 * cannot tell a rule that reaches everything from one that reaches what was in front of it, which
 * is the same defect one level up. So: no skill cites a section that is not there, and no section
 * is cited by nobody.
 *
 * **Both directions found a live fault on their first run**, neither introduced by this epic.
 * `do` cited `**Implementation Guidelines**`, which is a section of *CPM's* conventions and not of
 * these — a run told to follow a rule whose text is nowhere. And `A Closing Note on Length and
 * Tone` was cited by no skill at all, which is criterion 3's must-NOT already true in the tree.
 * Both were invisible because `section()` returns `''` for a heading that is not there and
 * `reachable()` reads only `shared **X**`, never the `uses` line — so neither mechanism looked.
 *
 * **Nothing here asserts how a rule is phrased.** A test pinning a sentence fires the day somebody
 * improves the wording, and whoever fixes it learns that the test was about the string — after
 * which the rule is no longer checked by anything.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readdirSync } from 'node:fs';
import { conventions, section, skillSource } from './support/skills.js';

const SKILLS = new URL('../skills/', import.meta.url).pathname;

/** Every skill in the corpus, by name. Read from the directory, never listed. */
const CORPUS = readdirSync(SKILLS, { withFileTypes: true })
  .filter((entry) => entry.isDirectory())
  .map((entry) => entry.name)
  .sort();

/** Every `## ` heading the shared conventions carry. */
function headings() {
  return conventions().split('\n')
    .filter((line) => /^## /.test(line))
    .map((line) => line.slice(3).trim());
}

/**
 * Every bolded name in a source, normalised.
 *
 * **Whitespace is collapsed because the files are hard-wrapped**, and a section name straddles a
 * line break as often as not: five of the twenty-three cite `**Written\nDeliverable Length**`. A
 * reading that took the name verbatim reported those five as citing a section that does not
 * exist — the sweep's own first run, and a fault in the reading rather than in the corpus.
 */
const bolded = (text) => [...text.matchAll(/\*\*([^*]+?)\*\*/gs)]
  .map((hit) => hit[1].replace(/\s+/g, ' ').trim());

/**
 * The shared sections one skill cites: any bolded name that is a heading of the shared file.
 *
 * **Read by what it names rather than by the sentence around it**, because there turned out to be
 * three forms and no reason to think three is the number. `This skill uses **X** … from it.` is
 * the declaration, `Follow the shared **X** procedure` is the delegation, and `see **X** in the
 * shared conventions` is how `status` reaches **Naming a Document** — which the first two-form
 * reading reported as an orphan section. A fourth form would have been missed the same way.
 */
const cites = (source, sections) => new Set(bolded(source).filter((name) => sections.has(name)));

/**
 * The sections a skill *claims*, which is where a name that is not a section is a fault.
 *
 * Narrower than `cites` on purpose: a bolded phrase in ordinary prose is emphasis, and holding
 * every one of them to being a heading would make the sweep an argument about wording. The three
 * forms above are the places a skill says *go and read this*, and a name there that resolves to
 * nothing is a run sent somewhere empty.
 */
function claims(source) {
  const declared = source.match(/This skill uses([\s\S]*?)from it\./);

  return new Set([
    ...bolded(declared?.[1] ?? ''),
    ...[...source.matchAll(/shared \*\*([^*]+?)\*\*/gs)]
      .map((hit) => hit[1].replace(/\s+/g, ' ').trim()),
    ...[...source.matchAll(/\*\*([^*]+?)\*\* in the shared conventions/gs)]
      .map((hit) => hit[1].replace(/\s+/g, ' ').trim()),
  ]);
}

/** Which skills cite each section, across the whole corpus. */
function citations() {
  const sections = new Set(headings());
  const byName = new Map(headings().map((heading) => [heading, []]));
  const dangling = [];

  for (const skill of CORPUS) {
    for (const cited of cites(skillSource(skill), sections)) byName.get(cited).push(skill);

    for (const claimed of claims(skillSource(skill))) {
      if (!sections.has(claimed)) dangling.push(`${skill} cites **${claimed}**`);
    }
  }

  return { byName, dangling };
}

/**
 * Where each rule this epic places in a shared section lands, and who it is for.
 *
 * **The counts are measurements, not predictions**, taken from this working tree. Stories 2 and 3
 * add their rule's row as it lands; a rule placed without its consumers citing the section fails
 * here rather than reaching nobody quietly.
 */
const PLACED = [
  { rule: 'FR16 — a gate is written and performed as two steps', into: 'Gate Presentation' },
  { rule: 'FR19 — the rows say what was written, not the session state', into: 'Session Startup' },
  {
    rule: 'FR17 — a criterion names the rejected outcome as though it happened',
    into: 'Writing a Criterion',
    // **Three consumers, which is over the line and only just.** ADR 05-05 puts a rule with more
    // than two into a shared section, so this is the narrowest section in the file and the one a
    // later count could move. It is named here rather than left to the general bound below.
    consumers: ['epics', 'quick', 'spec'],
  },
];

// --- The corpus is what it says it is -------------------------------------------------------------

test('every skill in the corpus is swept, and the corpus is read rather than listed [unit]', () => {
  // **The reading that makes the two directions below mean anything.** A sweep pointed at one
  // skill passes whatever the other twenty-two say, which is exactly the shape this epic exists
  // to remove.
  assert.ok(CORPUS.length >= 20, `only ${CORPUS.length} skills were swept`);
  assert.ok(CORPUS.includes('do') && CORPUS.includes('epics') && CORPUS.includes('templates'));

  // Every one of them opens by naming the file, which is the channel a shared rule has at all.
  for (const skill of CORPUS) {
    assert.match(skillSource(skill), /dpm\/shared\/skill-conventions\.md/,
      `${skill} never names the shared conventions, so nothing shared reaches it`);
  }

  assert.ok(headings().length > 8, 'the shared conventions were read as fewer sections than they have');
});

// --- Criterion 3's must-NOT, in both directions ---------------------------------------------------

test('no skill cites a shared section that does not exist [unit]', () => {
  // **A run told to follow a rule whose text is nowhere.** `do` cited `**Implementation
  // Guidelines**` — a section of CPM's conventions, not of these — and nothing noticed, because
  // `section()` answers a missing heading with an empty string.
  assert.deepEqual(citations().dangling, []);
});

test('must NOT — a rule sits in a shared section that no skill cites [unit]', () => {
  const { byName } = citations();
  const orphans = [...byName].filter(([, skills]) => skills.length === 0).map(([name]) => name);

  // `A Closing Note on Length and Tone` was one of these: its content duplicated **Conversational
  // Output**, which every skill cites, and the sentence that was not duplicated is now there.
  assert.deepEqual(orphans, []);
});

// --- Criteria 1 and 2: each rule lands where its count says -------------------------------------

test('every rule this epic shares is cited by each skill it was counted for [unit]', () => {
  const { byName } = citations();

  const unreachable = [];

  for (const { rule, into, consumers } of PLACED) {
    const citers = byName.get(into);

    assert.ok(citers, `${rule} is placed in **${into}**, which the shared conventions do not have`);

    // **More than two consumers is what put it in a shared section**, so a section carrying one of
    // these with two citers means the count was wrong or the citations were dropped — either way
    // the rule is in the wrong place.
    if (citers.length <= 2) unreachable.push(`${rule} → **${into}**, cited by ${citers.length}`);

    // Where the count named its consumers, each of them is checked by name. A bound on the number
    // is satisfied by the wrong three skills citing it.
    for (const consumer of consumers ?? []) {
      if (!citers.includes(consumer)) unreachable.push(`${rule} → ${consumer} does not cite it`);
    }
  }

  assert.deepEqual(unreachable, []);

  // The two sections these rules land in are the two most widely cited in the corpus, which is
  // why they were chosen — asserted so a later narrowing of either is visible here.
  assert.ok(byName.get('Gate Presentation').length >= 18);
  assert.ok(byName.get('Conversational Output').length === CORPUS.length,
    'the section every skill cites stopped being cited by every skill');
});

test('a rule with one or two consumers is in those skills\' bodies, not in a shared section [unit]', () => {
  const shared = conventions();

  // **The three single-consumer rules this epic places**, asserted as absences from the shared
  // file and presences in the one body each is for. FR18 and FR15 are `epics`, FR21 is `do`.
  // Stories 2 to 6 write them; what this asserts today is the one already moved.
  assert.equal(section(shared, 'Implementation Guidelines'), '',
    'a single-consumer rule was put back into the shared conventions');

  const execution = skillSource('do');

  assert.match(execution, /## How this skill changes a codebase/,
    "do lost the rules it used to reach for in a section that was not there");
  assert.match(execution, /Version control stays with the user/);
  assert.doesNotMatch(execution, /\*\*Implementation Guidelines\*\*/,
    'the dangling citation came back');
});

// --- The sweep is shown to be able to fail ---------------------------------------------------------

test('the sweep reports a planted dangling citation and a planted orphan [unit]', () => {
  const shared = conventions();

  // The controls, and they are what make the three answers above mean anything. Each is the real
  // reading applied to a planted source, so a sweep whose pattern had stopped matching would fail
  // here rather than report a clean corpus.
  const sections = new Set(headings());
  const planted = 'This skill uses **Gate Presentation** and **A Section Nobody Wrote** from it.';

  // `claims` sees both; `cites` keeps only the one that resolves, which is what makes a dangling
  // name a fault rather than a citation of nothing.
  assert.deepEqual([...claims(planted)].sort(), ['A Section Nobody Wrote', 'Gate Presentation']);
  assert.deepEqual([...cites(planted, sections)], ['Gate Presentation']);
  assert.equal(sections.has('A Section Nobody Wrote'), false);

  // **All three citation forms are read**, which the first draft did not do: it knew the `uses`
  // line and the delegation, and reported `status`'s **Naming a Document** as an orphan section.
  assert.ok(claims('Follow the shared **Library Check** procedure with scope keyword `do`.')
    .has('Library Check'));
  assert.ok(claims('see **Naming a Document** in the shared conventions.').has('Naming a Document'));

  // And a name wrapped across a line is the same name, since the files are hard-wrapped.
  assert.ok(cites('This skill uses **Written\nDeliverable Length** from it.', sections)
    .has('Written Deliverable Length'));

  // And a section genuinely present resolves to its text rather than to the empty string a missing
  // heading gives — the silence that hid the dangling citation for four releases.
  assert.ok(section(shared, 'Gate Presentation').length > 0);
  assert.equal(section(shared, 'A Section Nobody Wrote'), '');
});
