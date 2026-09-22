/**
 * Epic 05-06 Story 6 — no rule claims a capability the host does not have (ENV6).
 *
 * **A rule promising a safety net that is not there is worse than the rule's absence**, because a
 * run leans on it. Told the host refuses a badly-formed gate, a run stops checking its own gates;
 * told a turn can hand off to a fresh context, it writes an instruction that silently does nothing.
 * The rule then fails in the one way nobody looks for: quietly, on the runs where it mattered.
 *
 * ENV6 names three claims by example, and the sweep reads all three plus the class they belong to.
 * Its subject is **every skill body and the document they all read at startup** — the shared
 * conventions are in scope precisely because a claim there reaches twenty-three runs at once.
 *
 * **The control is planted rather than argued.** A sweep over prose can stop matching without
 * stopping passing, so each of the three claims is fed through the same reading and required to be
 * caught. Stories 2 to 5 each asserted this for their own rule as it was written; this is the
 * corpus-wide reading none of them could do.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readdirSync } from 'node:fs';
import { conventions, skillSource } from './support/skills.js';

const SKILLS = new URL('../skills/', import.meta.url).pathname;

const CORPUS = readdirSync(SKILLS, { withFileTypes: true })
  .filter((entry) => entry.isDirectory())
  .map((entry) => entry.name)
  .sort();

/**
 * The claims ENV6 forbids, each as what it would promise rather than as a phrase.
 *
 * **Read as a class, not as a blocklist of sentences.** A pattern matching one wording passes the
 * paraphrase, and a rule's author paraphrases. Each entry here matches the *promise* — something
 * the host does on the run's behalf — so a new wording of an old claim is caught by the entry it
 * belongs to rather than needing one of its own.
 */
const FORBIDDEN = [
  {
    claim: 'the host polices a gate',
    pattern: /\b(the )?host\b[^.]{0,60}\b(refuses|rejects|enforces|blocks|validates|police[sd]?)\b/i,
  },
  {
    claim: 'a thinking level is pinned per skill',
    // Either order, because "set the thinking level" and "the thinking level is set" are the same
    // claim and the first draft caught only the second.
    pattern: /\b(pin|set|fix|configur)\w*\b[^.]{0,40}\b(think(ing)?|reasoning)\s+(level|effort|budget)\b|\b(think(ing)?|reasoning)\s+(level|effort|budget)\b[^.]{0,40}\b(pin|set|fix|configur)/i,
  },
  {
    claim: 'a turn ends by handing off to a fresh context',
    pattern: /\bhand(s|ed|ing)?\s+(off|over)\b[^.]{0,60}\b(fresh|new|clean)\s+(context|session|turn)\b/i,
  },
  {
    claim: 'the harness does the work for the run',
    pattern: /\bthe (host|harness) (automatically|will)\b/i,
  },
];

/** Everything ENV6's subject covers: every skill body, and the file they all read at startup. */
function corpusTexts() {
  return [
    ...CORPUS.map((skill) => [`skills/${skill}`, skillSource(skill)]),
    ['shared/skill-conventions.md', conventions()],
  ];
}

/** Every forbidden claim a text makes, as `where · what`. */
function claimsMade([where, text]) {
  const flat = text.replace(/\s+/g, ' ');

  return FORBIDDEN
    .filter(({ pattern }) => pattern.test(flat))
    .map(({ claim }) => `${where} · ${claim}`);
}

// --- Criterion 1 (must NOT): no body claims a capability the host does not have -------------------

test('must NOT — a skill body or the shared conventions claim a host capability [unit]', () => {
  // **The whole corpus, plus the one document every body opens with.** A claim in the shared file
  // reaches twenty-three runs at once, so leaving it out would exempt the highest-reach text in
  // the project from the rule written about reach.
  const texts = corpusTexts();

  assert.equal(texts.length, CORPUS.length + 1);
  assert.ok(CORPUS.length >= 20, `only ${CORPUS.length} skills were swept`);

  assert.deepEqual(texts.flatMap(claimsMade), []);
});

// --- Criterion 2 (control): a planted claim is caught ----------------------------------------------

test('control — each forbidden claim planted in a body makes the sweep report it [unit]', () => {
  // **One planting per claim, through the same reading.** A sweep over prose can stop matching
  // without stopping passing; three patterns that never fire report a clean corpus exactly as a
  // clean corpus does.
  const planted = [
    ['skills/planted', 'The host refuses a badly-formed gate, so a gate needs no checking here.'],
    ['skills/planted', 'Set the thinking level for this skill to high before Step 2.'],
    ['skills/planted', 'End the turn by handing off to a fresh context, which carries the state.'],
    ['skills/planted', 'The harness will clean the scratch directory once the run finishes.'],
  ];

  for (const text of planted) {
    assert.notDeepEqual(claimsMade(text), [], `an ENV6 claim passed the sweep: ${text[1]}`);
  }

  // Each of the four patterns fires on its own example, so no entry is carrying another's weight.
  assert.equal(new Set(planted.flatMap(claimsMade)).size, FORBIDDEN.length,
    'two plantings were caught by one pattern, so a pattern is doing nothing');

  // **And the reading is not simply matching everything**, which would pass the assertions above
  // and fail the corpus. Real sentences from the rules this epic wrote, each about what the *run*
  // does, are left alone.
  for (const innocent of [
    'A gate is two steps, and it is performed as two steps.',
    'Nothing a gate decides is written before it is answered.',
    'The session\'s scratchpad directory is what this means where the harness provides one.',
    'Never add coverage pages up by hand.',
  ]) {
    assert.deepEqual(claimsMade(['skills/planted', innocent]), [],
      `the sweep reported a rule that claims nothing: ${innocent}`);
  }
});

// --- The claims are read as a class rather than as a blocklist -------------------------------------

test('a paraphrase of a forbidden claim is caught by the claim it belongs to [unit]', () => {
  // ENV6 names three claims by example, and an author who rewords one is not making a new claim.
  // Matching the promise rather than the phrasing is what makes the rule survive being restated.
  const paraphrases = [
    'The host validates every gate before it reaches the user.',
    'Pin the reasoning effort for this skill at the highest setting.',
    'Finish by handing over to a new session, which picks up where this one stopped.',
  ];

  for (const line of paraphrases) {
    assert.notDeepEqual(claimsMade(['skills/planted', line]), [],
      `a paraphrase slipped past the sweep: ${line}`);
  }
});
