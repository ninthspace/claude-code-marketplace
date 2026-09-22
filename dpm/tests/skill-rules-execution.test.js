/**
 * Epic 05-06 Story 4 — the four execution rules (FR21).
 *
 * FR21 opens *"Four smaller rules hold in the execution skill"*, and `do` is the execution skill —
 * one consumer, so by ADR 05-05 they go in its own body and not in the shared conventions. Story
 * 1's table says so; this file asserts both halves of that, because a rule in the wrong place is
 * still a rule and reads perfectly well from there.
 *
 * Each rule is placed beside the step it governs rather than gathered into a section of its own.
 * The observation rule sits at Step 6 where the observation is written, the unmet-criterion rule
 * immediately before the gate it qualifies, the coverage-count rule in the roll-up, and the
 * scratch-file rule beside the other two rules about how this skill touches a working tree. A run
 * reads the rule at the point it would otherwise break it.
 *
 * As everywhere in this epic, the assertions are over what each rule requires and never over how it
 * is worded, with whitespace collapsed first.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readdirSync } from 'node:fs';
import { conventions, section, skillSource } from './support/skills.js';

const SKILLS = new URL('../skills/', import.meta.url).pathname;

const CORPUS = readdirSync(SKILLS, { withFileTypes: true })
  .filter((entry) => entry.isDirectory())
  .map((entry) => entry.name)
  .sort();

/** `do`'s body with the hard wrapping collapsed. */
const execution = () => skillSource('do').replace(/\s+/g, ' ');

// --- Criterion 1: one observation per story, further categories on the same row -------------------

test('one observation per story, and a second category goes on the existing row [unit]', () => {
  const rule = execution();

  assert.match(rule, /One observation per story/);
  assert.match(rule, /a second category goes on the existing row/);

  // **Why, and the why is the part that stops a run reasoning around it**: `/dpm:retro` groups by
  // category, so two observations saying one thing count the story twice.
  assert.match(rule, /not two observations saying the same thing/);
  assert.match(rule, /would count the story twice/);
});

// --- Criterion 2: the unmet criterion is rendered before the gate ---------------------------------

test('an unmet criterion is rendered in full before the gate that asks about it [unit]', () => {
  const rule = execution();

  assert.match(rule, /Render each unmet criterion in full before that gate/);

  // **What the assessment found**, not that it failed — the half a summary drops.
  assert.match(rule, /with what the assessment actually found/);
  assert.match(rule, /the assertion that went red|the output/);

  // And the rule says what it is protecting against, so a run that shortens it knows the cost.
  assert.match(rule, /asking the user to approve a summary of it/);
});

// --- Criterion 3: coverage pages are not added up by hand -----------------------------------------

test('coverage pages are never added up by hand [unit]', () => {
  const rule = execution();

  assert.match(rule, /Never add coverage pages up by hand/);

  // The alternative is named, which is what makes it a rule rather than a prohibition: one call
  // answers the roll-up.
  assert.match(rule, /`mcp__plugin_dpm_dpm__check_coverage` answers the roll-up in one call/);

  // **Both failure modes**, because a run told only "do not total pages" will total them carefully
  // instead of not totalling them.
  assert.match(rule, /a second page it did not ask for is missing from the total/);
  assert.match(rule, /a page read twice is counted twice/);
});

// --- Criterion 4: scratch files are accounted for and removed -------------------------------------

test('a scratch file sits where the ignore rules account for it, and is removed [unit]', () => {
  const rule = execution();

  assert.match(rule, /the repository's ignore rules already account for it/);
  assert.match(rule, /removed once it has been read/);

  // The reason, in terms of the next status check — which is the thing that actually goes wrong.
  assert.match(rule, /`git status` stays quiet about/);
  assert.match(rule, /committed by somebody who could not tell it from the change/);
});

// --- Placement: one consumer, so one body ---------------------------------------------------------

test('the four rules are in the execution skill and in no shared section [unit]', () => {
  const shared = conventions();

  // **One consumer, read as "who carries the rules" rather than by a proxy for it.** The first cut
  // asked which skills call `update_task` and got `do` and `pivot` — `pivot` amends a breakdown and
  // touches tasks doing it, without running any. A proxy that misfires on the second skill it meets
  // is a worse answer than the direct one, so the assertion is that `do` alone carries the four.
  const carriers = CORPUS.filter((skill) => /One observation per story/
    .test(skillSource(skill).replace(/\s+/g, ' ')));

  assert.deepEqual(carriers, ['do'], 'a rule with one consumer is in more than one body');

  // None of the four leaked into the shared conventions, which is where a rule with one consumer
  // costs twenty-two skills a paragraph they cannot act on.
  const conventionsProse = shared.replace(/\s+/g, ' ');

  for (const rule of [
    /One observation per story/,
    /Never add coverage pages up by hand/,
    /Render each unmet criterion in full/,
  ]) {
    assert.doesNotMatch(conventionsProse, rule, 'a single-consumer rule reached the shared file');
  }

  assert.equal(section(shared, 'Execution Rules'), '',
    'a section was created for rules with one consumer');
});

test('none of the four claims an enforcement the harness does not have [unit]', () => {
  const rule = execution();

  // ENV6 again, held as the rules are written. The scratch-file rule is the one that invites it —
  // a run would like to be told the harness cleans up after it.
  assert.doesNotMatch(rule, /the host (refuses|rejects|enforces|cleans)/i);
  assert.doesNotMatch(rule, /automatically (removed|cleaned|deleted) (for you|by the host)/i);
});
