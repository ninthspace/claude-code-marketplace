/**
 * Epic 47-09 Story 5 — the twenty-two skills as one corpus.
 *
 * - "The twenty-two skills named in FR25 all exist, and no skill exists that FR25 does not name"
 *   [integration]
 * - "No skill writes a literal artefact number into a prose column; a reference to another
 *   artefact is written `{{ref:<id>}}` — swept across all twenty-two" [unit]
 * - "Every pipeline stage a CPM user can reach has a dpm skill, asserted by comparing the corpus
 *   against CPM's own skill directory" [integration]
 * - "must NOT — the pipeline-stage comparison reports success because CPM's `skills/` directory was
 *   absent, rather than failing on a fixture it could not read" [integration]
 * - "No skill file contains a filename pattern under `docs/`, a glob, a number-allocation
 *   procedure, or a progress-file lifecycle — swept across all twenty-two" [unit]
 * - "Every dpm SKILL.md contains no SQL keyword and no `sqlite3` invocation — swept across all
 *   twenty-two" [unit]
 * - "must NOT — a skill recovers an entity by reading a generated markdown file rather than by
 *   calling a read tool, swept across all twenty-two" [unit]
 * - "Every one of the twenty-two carries a passing facilitation criterion on its own story, checked
 *   here as a roll-up" [integration]
 *
 * **Each conversion epic already swept its own files, and that is why this exists.** A sweep run at
 * conversion time reports on a file as it was that afternoon; every one of these skills has been
 * edited since, three of them by Story 9 of this epic. The corpus sweep is the one that catches a
 * pattern reintroduced by a later edit to an earlier skill, which is precisely the edit no story
 * owns.
 *
 * **Five of the eight criteria are sweeps for something absent, and the eighth is why that is not
 * enough.** Twenty-two files each holding a title and a single tool call would satisfy every
 * negative check here. The retention criteria cannot be written corpus-wide — what facilitation
 * means differs per skill — so they live on the twenty-two conversion stories, and what belongs
 * here is the roll-up that fails when one of them has no such criterion or has one that never
 * passed.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, readdirSync, readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { openPlanningDatabase } from './support/planning-database.js';
import { spineTools } from '../src/tools/index.js';
import {
  skillSource, conventions, frontMatter, prose, toolNames, reachable,
  recoveries, sweep, SQL, CONSTRUCTIONS,
} from './support/skills.js';

/** The marketplace repository, which holds `cpm/` and `dpm/` as siblings in one commit. */
const REPO = join(import.meta.dirname, '..', '..');
const SKILLS = join(import.meta.dirname, '..', 'skills');
const EPICS = join(REPO, 'docs', 'epics');

/**
 * FR25's list, transcribed. **The one hand-kept list in this file, and it has to be** — it is the
 * requirement's own text, and deriving it from the directory it checks would make the check read
 * the answer off its subject.
 */
const NAMED = [
  'architect', 'archive', 'artifact', 'audit', 'brief', 'clean', 'consult', 'discover', 'do',
  'epics', 'inspect', 'library', 'party', 'pivot', 'present', 'quick', 'ralph', 'retro', 'review',
  'spec', 'status', 'templates',
];

/**
 * The directories under a skills root, or a failure naming the root.
 *
 * **Throwing rather than returning an empty array is the whole of the fourth criterion.** A set
 * comparison against nothing passes: every member of the empty set is present in the corpus, so a
 * suite run where `cpm/` is not beside `dpm/` — an extracted plugin copy, a partial checkout —
 * would report that every pipeline stage is covered on the strength of having found none. The
 * check exists to catch a short list, and an unreadable directory is the shortest list there is.
 */
function stageDirectories(root) {
  let entries;

  try {
    entries = readdirSync(root, { withFileTypes: true });
  } catch (cause) {
    throw new Error(`${root} is not readable, so the comparison has nothing to compare against `
      + 'and an empty set is satisfied by any corpus', { cause });
  }

  const names = entries.filter((entry) => entry.isDirectory()).map((entry) => entry.name).sort();
  if (names.length === 0) throw new Error(`${root} holds no skill directories, ${names.length} found`);

  return names;
}

const installed = stageDirectories(SKILLS);

// --- Criterion 1: the corpus is exactly FR25's list, both directions -----------------------------

test('the corpus is exactly the twenty-two skills FR25 names', () => {
  assert.equal(NAMED.length, 22, 'FR25\'s list was transcribed with the wrong number of names');

  // Both directions, and reported separately. A corpus short of one skill and a corpus holding an
  // unnamed twenty-third are different failures with different fixes, and a symmetric-difference
  // count tells the reader which of the two it is only by accident.
  assert.deepEqual(NAMED.filter((name) => !installed.includes(name)), [],
    'FR25 names a skill the corpus does not ship');
  assert.deepEqual(installed.filter((name) => !NAMED.includes(name)), [],
    'the corpus ships a skill FR25 does not name');

  // A directory is not a skill. Each carries a SKILL.md whose front matter names itself, which is
  // what the harness dispatches on — a directory renamed without its front matter is a skill that
  // exists at one name and answers to another.
  for (const name of installed) {
    assert.equal(frontMatter(skillSource(name)).name, name,
      `${name}/SKILL.md declares a different name from its directory`);
  }
});

// --- Criteria 3 and 4: every stage CPM offers, and the comparison failing on an absent fixture ---

test('every pipeline stage CPM offers has a dpm skill', () => {
  const stages = stageDirectories(join(REPO, 'cpm', 'skills'));

  // FR25's list could itself be short, which is the reason this comparison is not against `NAMED`.
  // CPM's directory is the population of stages a user can reach; the corpus has to cover it.
  assert.deepEqual(stages.filter((stage) => !installed.includes(stage)), [],
    'CPM offers a pipeline stage the dpm corpus has no skill for');
});

test('must NOT — the pipeline comparison reports success on a directory it could not read', () => {
  assert.throws(() => stageDirectories(join(REPO, 'cpm', 'no-such-skills-directory')),
    /nothing to compare against/,
    'an unreadable skills root produced a set rather than a failure');

  // And the emptier failure the first does not cover: a directory that exists and holds nothing.
  // `readdirSync` succeeds on it, so only the explicit count catches it.
  const empty = mkdtempSync(join(tmpdir(), 'dpm-corpus-'));

  try {
    assert.throws(() => stageDirectories(empty), /holds no skill directories/,
      'an empty skills root produced a set rather than a failure');
  } finally {
    rmSync(empty, { recursive: true, force: true });
  }

  // The control, and the reason the two above mean anything: the same reading of a root that *is*
  // populated returns the corpus. Without it a function that threw unconditionally would pass both.
  assert.equal(stageDirectories(SKILLS).length, 22);
});

// --- Criteria 5, 6 and 7: the subtractions and SQL, across all twenty-two ------------------------

test('no skill in the corpus names a path, a glob, an allocation, a progress file or SQL', () => {
  assert.equal(installed.length, 22, 'the sweep is not running over the whole corpus');

  for (const name of installed) {
    const source = skillSource(name);

    assert.deepEqual(recoveries(source), [],
      `${name} recovers something rather than calling a tool`);
    assert.deepEqual(sweep(source, CONSTRUCTIONS), [],
      `${name} carries a construction FR25 removes`);
    assert.deepEqual(sweep(source, SQL), [],
      `${name} reaches past the tool boundary FR3 draws`);
  }

  // The shared conventions are read by every skill in the corpus, so a pattern moved into that file
  // would leave twenty-two clean sweeps and reach every run regardless.
  const shared = conventions();

  assert.deepEqual(recoveries(shared), [], 'the shared conventions recover something');
  assert.deepEqual(sweep(shared, CONSTRUCTIONS), [], 'the shared conventions carry a construction');
  assert.deepEqual(sweep(shared, SQL), [], 'the shared conventions carry SQL');

  // The controls. Without them a pattern that stopped matching reports a clean corpus in exactly
  // the same shape as a clean corpus does.
  const planted = 'Glob docs/epics/*-epic-*.md, take the next available number, increment it and '
    + 'zero-pad it, then read the progress file at docs/plans/.cpm-progress-{session_id}.md, '
    + 'parsing **Status**: from its front matter with the Read tool.';

  assert.ok(recoveries(planted).length >= 6, 'the recovery sweep is not reading');
  assert.ok(sweep(planted, CONSTRUCTIONS).length >= 3, 'the construction sweep is not reading');

  for (const statement of [
    'SELECT * FROM story WHERE epic_id = ?',
    'INSERT INTO coverage (id, requirement_id) VALUES (?, ?)',
    'UPDATE story SET status = ?',
    'DELETE FROM dependency WHERE id = ?',
    'CREATE TABLE thing (id TEXT)',
    'JOIN dependency_kind ON dependency_kind.kind = dependency.kind',
    'PRAGMA foreign_keys = ON',
    'sqlite3 .dpm/planning.db "..."',
  ]) {
    assert.ok(sweep(statement, SQL).length >= 1, `${statement} passed the SQL sweep`);
  }
});

// --- Criterion 2: references in prose are markers, never numbers ---------------------------------

/**
 * A sentence naming an artefact by its human number — what FR28 exists to keep out of a prose
 * column.
 *
 * **The kind words are what make this narrow enough to run**, and they are the discriminator rather
 * than a convenience. These files count constantly: phases, steps, sections, stories, three days,
 * two or three agents. What none of them has any business doing is naming a *particular* artefact,
 * because a skill file ships before the project it runs in exists — so a kind word followed by a
 * number is either an example a run will copy or an instruction to write one.
 */
const NUMBERED_REFERENCES = [
  {
    pattern: /\b(spec|epic|problem brief|product brief|brief|adr|retro|review|audit|quick|runbook|discussion|communication|coverage matrix)s?\s+#?\d+/i,
    why: 'an artefact named by its number, which is the reference a renumber breaks',
  },
];

/**
 * The write tools that carry narrative prose, derived from the read surface rather than listed.
 *
 * A read tool's `body` columns are the schema's own answer to which columns hold prose — they are
 * the ones withheld until a caller asks for them, because they are the text rather than the
 * identity. A column added to that set later is picked up here without an edit, which is the whole
 * reason for deriving it.
 *
 * **`session` is the one exclusion, and it is not a prose column.** `state` is a blob the skill
 * defines and dpm does not interpret; nothing projects it, so a marker in it would never resolve
 * and a number in it would never render. Requiring the four skills that carry loop state to observe
 * a rule about rendered prose would be a citation with nothing behind it.
 */
function narrativeWriters(tools) {
  const bodied = new Set(tools
    .filter((tool) => Array.isArray(tool.body) && tool.body.length > 0)
    .map((tool) => tool.name.replace(/^(read|list|adopt|delete)_/, '')));

  bodied.delete('session');

  return new Set(tools
    .filter((tool) => /^(create|update)_/.test(tool.name))
    .filter((tool) => bodied.has(tool.name.replace(/^(create|update)_/, ''))));
}

test('a reference to another artefact is a marker, and no skill writes a number', (t) => {
  const tools = spineTools(openPlanningDatabase(t));
  const writers = new Set([...narrativeWriters(tools)].map((tool) => tool.name));

  // The negative half, over the whole corpus and over the file every skill in it reads.
  for (const name of [...installed, null]) {
    const source = name === null ? conventions() : skillSource(name);

    assert.deepEqual(sweep(source, NUMBERED_REFERENCES), [],
      `${name ?? 'the shared conventions'} names an artefact by a number that will move`);
  }

  // The control. Each of these is the sentence the spec cites as the case FR28 was written for.
  for (const planted of [
    'The merge half is Epic 47-04.',
    'Record the observation citing spec 47, which is where the requirement came from.',
    'Cross-reference ADR 12 in the rationale.',
    'This supersedes retro 33.',
  ]) {
    assert.equal(sweep(planted, NUMBERED_REFERENCES).length, 1, `${planted} passed the sweep`);
  }

  // And the other side of it: the counting these files do constantly is not a reference.
  for (const counted of [
    'Work through the phases one at a time, one gate per turn.',
    'Carry what it returns into Phase 5, where constraints meet recorded standards.',
    'A row whose `updated_at` is more than three days old is stale.',
    'Select two or three whose role and personality bear on the decision at hand.',
    'Each phase is one section, with its heading and its position.',
  ]) {
    assert.deepEqual(sweep(counted, NUMBERED_REFERENCES), [],
      'the reference sweep fires on ordinary counting');
  }

  // The positive half. A negative sweep is satisfied by a corpus that never references anything at
  // all, so the rule has to be reachable from every skill that writes a column a reference could
  // land in — and which skills those are is read off the tool surface, not decided here.
  const authoring = installed
    .filter((name) => toolNames(reachable(skillSource(name))).some((tool) => writers.has(tool)));

  assert.ok(authoring.length > 0 && authoring.length < installed.length,
    `the derivation collapsed — ${authoring.length} of ${installed.length} skills write prose, `
    + 'so it is separating nothing and the citation check below asserts nothing');

  for (const name of authoring) {
    assert.match(skillSource(name), /\*\*Cross-References\*\*/,
      `${name} writes a narrative column and never reaches the rule about what goes in one`);
  }

  // And the rule it reaches says both halves — the form to write, and the thing not to.
  const rule = prose(conventions(), 'Cross-References');

  assert.match(rule, /`\{\{ref:<id>\}\}`/, 'the shared rule does not give the marker form');
  assert.match(rule, /Never write the number/, 'the shared rule does not forbid the number');
  assert.match(rule, /structural reference/,
    'the shared rule does not separate a marker from a foreign key, so it reads as applying to both');
});

// --- Criterion 8: the facilitation roll-up -------------------------------------------------------

/**
 * Which skill each conversion story converts, and whether its facilitation criterion is verified —
 * joined across every conversion epic in the project.
 *
 * **Derived by scanning the epics rather than by listing the four**, so a conversion moved into a
 * fifth epic is picked up rather than silently dropped from the roll-up. A story converting a skill
 * is headed ``## Convert `x` ``; its coverage matrix sits at the same path with `-epic-` replaced,
 * which is the one derivation in this suite that reads a filename, and it reads one this repository
 * owns rather than one a skill constructs.
 */
function facilitation() {
  const found = new Map();

  for (const file of readdirSync(EPICS).filter((name) => /-epic-.*\.md$/.test(name))) {
    const epic = readFileSync(join(EPICS, file), 'utf8');
    const converts = [...epic.matchAll(/^## Convert `([a-z]+)`[^\n]*\n\*\*Story\*\*: (\d+)/gm)];
    if (converts.length === 0) continue;

    const matrix = readFileSync(join(EPICS, file.replace('-epic-', '-coverage-')), 'utf8');
    const rows = matrix.split('\n').filter((line) => line.startsWith('|'));
    const header = rows[0].split('|').map((cell) => cell.trim());
    const covered = header.indexOf('Covered by');
    const verified = header.indexOf('Verified');

    assert.ok(covered > 0 && verified > 0, `${file}'s coverage matrix has no 'Covered by' column`);

    const marks = new Map(rows
      .filter((row) => row.includes('facilitation survives'))
      .map((row) => row.split('|'))
      .map((cells) => [cells[covered].trim(), cells[verified].trim()]));

    for (const [, skill, story] of converts) {
      found.set(skill, { epic: file, story: `Story ${story}`, mark: marks.get(`Story ${story}`) });
    }
  }

  return found;
}

test('every one of the twenty-two carries a facilitation criterion that passed', () => {
  const rolled = facilitation();

  // The roll-up's own subject: a skill converted with no facilitation criterion at all. This is the
  // failure the story names — a conversion that succeeds at the subtraction and quietly discards
  // the part FR25 says is the reason for keeping the skill.
  assert.deepEqual(installed.filter((name) => !rolled.has(name)), [],
    'a skill in the corpus has no conversion story, so nothing asserts its facilitation survived');

  assert.deepEqual([...rolled.keys()].filter((name) => !installed.includes(name)), [],
    'a conversion story converts a skill the corpus does not ship');

  const unverified = [...rolled]
    .filter(([, row]) => row.mark !== '✓')
    .map(([skill, row]) => `${skill} (${row.epic} ${row.story}): ${row.mark ?? 'no facilitation row'}`);

  assert.deepEqual(unverified, [],
    'a skill\'s facilitation criterion is unverified, or its story has no facilitation row at all');

  assert.equal(rolled.size, 22, 'the roll-up did not reach twenty-two skills');
});
