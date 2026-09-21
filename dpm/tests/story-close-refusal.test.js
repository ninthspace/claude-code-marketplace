/**
 * Epic 05-02 Story 2 — a story cannot be finished over an outstanding task (FR3).
 *
 * The state this removes is quiet rather than loud: a task left `pending` under a story somebody
 * closed is work no report counts, because the story above it says the work is done. Nothing errors
 * and nothing looks wrong — which is the shape every refusal in this epic shares.
 *
 * **Both controls here are load-bearing and neither is decoration.** The first shows the refusal
 * discriminates rather than the close being broken. The second shows the *task* path is untouched,
 * which is the contract that made this story one to design in full: `deliveryTools` builds the tools
 * for both tables, so a condition written into the factory rather than passed into it would have
 * silently acquired a closing rule for tasks as well.
 *
 * **Each rejection is driven on its own rows**, so no assertion here depends on another's order.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { openPlanningDatabase as planning, handlers } from './support/planning-database.js';
import { spineTools } from '../src/tools/index.js';

/** A story with tasks beneath it, and the handles to drive either. */
function surface(t) {
  const db = planning(t);
  const call = handlers(spineTools(db));

  const spec = call.create_spec({ slug: 'closing', title: 'Closing conditions' });
  const epic = call.create_epic({ parent_id: spec.id, slug: 'guards', title: 'Guards' });

  const story = (number, title) => call.create_story({
    epic_id: epic.id, number, title, position: number - 1,
  });
  const task = (owner, number, title) => call.create_task({
    story_id: owner.id, number, title, position: number - 1,
  });

  return { db, call, story, task };
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

// --- Criterion 1 (must NOT): the story is not finished over outstanding work ---------------------

test('must NOT — a story with an outstanding task beneath it is set finished [integration]', (t) => {
  const { call, story, task } = surface(t);
  const subject = story(1, 'Deliver the guard');

  task(subject, 1, 'Write it');

  refused(() => call.update_story({ id: subject.id, status: 'complete' }),
    'a story was closed over a task nobody had resolved');

  // **The stored status, not the exception.** A guard that refused *after* the write would satisfy
  // a check on the throw and leave exactly the state this exists to prevent — a `pending` task
  // under a `complete` story, which is the quiet outcome the whole epic is about.
  assert.equal(call.read_story({ id: subject.id }).status, 'pending',
    'the close was refused and the story is finished anyway');

  // **Retiring it is not refused**, which is the line between a claim and a decision. A story whose
  // work was dropped has outstanding tasks by definition, so a guard firing on every terminal
  // status would make the legitimate way to stop unreachable.
  assert.equal(
    call.update_story({ id: subject.id, status: 'withdrawn', status_note: 'the feature was cut' })
      .status,
    'withdrawn',
  );
});

// --- Criterion 2: the refusal lists the outstanding tasks -----------------------------------------

test('the refusal names every outstanding task, and only those [integration]', (t) => {
  const { call, story, task } = surface(t);
  const subject = story(2, 'Deliver the other guard');

  const first = task(subject, 1, 'Write the condition');
  task(subject, 2, 'Write its tests');
  const dropped = task(subject, 3, 'Fold into the first');

  call.update_task({ id: dropped.id, status: 'withdrawn', status_note: 'folded into task 1' });

  const error = refused(() => call.update_story({ id: subject.id, status: 'complete' }));

  // **The story's own number, which only the resolved row carries.** A caller setting `status` and
  // nothing else supplies no number, so a hook judging the call's arguments has none to name — and
  // the mutation that swapped the resolved row for the arguments survived every other assertion
  // here until this one was added. Story 3's condition depends on that resolution outright.
  assert.match(error.message, /story 2 has/,
    'the hook was handed the call rather than the row the edit would leave');

  // Both pending tasks, by number and title. A refusal naming one of two performs half the
  // reconciliation and sends the caller back to list the rest.
  assert.match(error.message, /1\. Write the condition/);
  assert.match(error.message, /2\. Write its tests/);

  // **And not the retired one**, which is the half that says the rule reads the status rather than
  // counting rows. A task somebody withdrew is a question answered.
  assert.doesNotMatch(error.message, /Fold into the first/,
    'a withdrawn task was reported as outstanding');

  // Finishing one leaves the other named, so the list tracks the rows rather than being computed
  // once — the state a caller reaches by working through the refusal.
  call.update_task({ id: first.id, status: 'complete' });

  const remaining = refused(() => call.update_story({ id: subject.id, status: 'complete' }));

  assert.doesNotMatch(remaining.message, /Write the condition/);
  assert.match(remaining.message, /2\. Write its tests/);
});

// --- Criterion 3 (control): the story closes when its tasks are done ------------------------------

test('control — a story whose every task is finished is closed [integration]', (t) => {
  const { call, story, task } = surface(t);
  const subject = story(3, 'Deliver a third');

  const one = task(subject, 1, 'Write it');
  const two = task(subject, 2, 'Test it');

  call.update_task({ id: one.id, status: 'complete' });
  call.update_task({ id: two.id, status: 'complete' });

  assert.equal(call.update_story({ id: subject.id, status: 'complete' }).status, 'complete',
    'a story with nothing outstanding was refused');

  // A story with no tasks at all closes too — there is nothing outstanding, and a rule that refused
  // an empty set would block every story whose work was never broken down.
  const bare = story(4, 'Nothing beneath it');

  assert.equal(call.update_story({ id: bare.id, status: 'complete' }).status, 'complete');
});

// --- Criterion 4 (control): the task path passes none of this -------------------------------------

test('control — a task is finished exactly as it was, passing no closing hook [integration]', (t) => {
  const { call, story, task } = surface(t);
  const subject = story(5, 'A story with nested work');
  const parent = task(subject, 1, 'A task of its own');

  // **The seam's contract, asserted rather than assumed.** Both tables are built by one factory, so
  // a condition written into it rather than passed to it would give tasks a closing rule nobody
  // asked for. A task carries no children, so any such rule would be vacuous today and wrong the
  // moment one did — and vacuous is exactly what no test would notice.
  assert.equal(call.update_task({ id: parent.id, status: 'complete' }).status, 'complete');

  // Every status, in both directions, with a story left deliberately open above it. If the hook
  // reached tasks at all, one of these would be the call that found it.
  for (const status of ['pending', 'superseded', 'withdrawn', 'complete']) {
    assert.equal(
      call.update_task({ id: parent.id, status, status_note: 'moving through the vocabulary' })
        .status,
      status,
      `a task would not take '${status}' — the closing hook reached the task path`,
    );
  }

  // And the story above it is still open, so the task's freedom was not bought by the story having
  // been closed first.
  assert.equal(call.read_story({ id: subject.id }).status, 'pending');
});

test('the task registration passes no closing hook, which behaviour cannot show [unit]', () => {
  // **This is asserted structurally because it cannot be asserted behaviourally, and that was
  // measured rather than assumed.** Handing `storyClosing` to `task` as well is a mutation the four
  // tests above all survive: the condition reads the tasks whose parent is the row being closed,
  // and no task is the parent of a task, so it finds nothing and waves every call through. It is
  // inert *today* and wrong the moment any closing condition looks at something a task has.
  //
  // So the registration is read instead. A behavioural test here would be a control that cannot
  // fail, which is the thing this epic's whole retro gate was about.
  const source = readFileSync(new URL('../src/tools/index.js', import.meta.url), 'utf8');
  const registration = source.slice(source.indexOf("table: 'task',"));
  const block = registration.slice(0, registration.indexOf('}),'));

  assert.ok(block.includes("parent: 'story_id'"), 'the task registration was not the block read');
  assert.equal(block.includes('closing'), false,
    'the task table was given a closing hook — the seam reached the path it must not');

  // The control for the reading: the same slice taken at the story registration does find one, so
  // an absence above is the registration's rather than the search's.
  const story = source.slice(source.indexOf("table: 'story',"));

  assert.ok(story.slice(0, story.indexOf('}),')).includes('closing'),
    'the story registration has no closing hook either — this reading finds nothing anywhere');
});
