/**
 * Story 4 — bounded reads, and the two ways a bound can be a lie.
 *
 * FR13 has one positive half per criterion and a must-NOT that names both failures at once: "a
 * query tool returns an unbounded row set when no limit is supplied, or refuses a limit the caller
 * raised". They pull in opposite directions, which is why they are one requirement — a tool that
 * capped hard would satisfy the first and fail the second, and a tool that ignored `limit` would
 * do the reverse. So every assertion here is paired: the default bounds, *and* the raise is
 * honoured; the body is withheld, *and* asking for it returns it.
 *
 * **The seeding is deliberately one row past the default.** Fifty-one of every type, so that "no
 * limit supplied" has something to truncate for every list tool rather than for the one type a
 * test happened to bulk-create. A must-NOT checked on one tool of eight is a must-NOT the other
 * seven can fail silently.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { openPlanningDatabase } from './support/planning-database.js';
import { spineTools } from '../src/tools/index.js';
import { DEFAULT_LIMIT } from '../src/tools/convention.js';
import { dispatch, methods } from '../src/server/mcp.js';

function surface(t) {
  const db = openPlanningDatabase(t);
  const tools = spineTools(db);

  return { db, tools, call: Object.fromEntries(tools.map((tool) => [tool.name, tool.handler])) };
}

/** One more than the default, so an unbounded answer and a bounded one differ. */
const MANY = DEFAULT_LIMIT + 1;

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

/** A row of every type, so a read has something to summarise. */
function chain(call) {
  const spec = call.dpm_create_spec({ slug: 'dpm', title: 'dpm SQLite persistence' });
  const requirement = call.dpm_create_requirement({
    spec_id: spec.id,
    label: 'FR13',
    class: 'functional',
    text: 'Query tools return summaries rather than whole bodies unless a body is requested',
    position: 0,
  });
  const acceptance_criterion = call.dpm_create_acceptance_criterion({
    requirement_id: requirement.id,
    text: 'a read without an explicit body request returns strictly fewer bytes than one with it',
    position: 0,
  });
  const epic = call.dpm_create_epic({ parent_id: spec.id, slug: 'spine', title: 'Spine tools' });
  const story = call.dpm_create_story({
    epic_id: epic.id, number: 4, title: 'Bound reads by default', position: 3,
  });
  const task = call.dpm_create_task({
    story_id: story.id,
    number: 1,
    title: 'Add summary and body read modes',
    description: 'The summary is the default; the body is requested explicitly.',
    position: 0,
  });
  const story_criterion = call.dpm_create_story_criterion({
    story_id: story.id, text: 'every list-returning tool declares a limit', position: 0,
  });
  const coverage = call.dpm_create_coverage({
    requirement_id: requirement.id,
    spec_fragment: 'unless a body is explicitly requested',
    story_criterion_id: story_criterion.id,
    position: 0,
  });

  // Story 6's table. It is here because the body sweep below is over *every* read tool that
  // declares a body, and a type missing from this chain is a tool the sweep skips silently.
  const session = call.dpm_create_session({
    id: 'session-0000',
    skill: 'cpm:do',
    phase: 'Story 4',
    state: JSON.stringify({ epic: '47-03', story: 4, note: 'the blob a progress file used to be' }),
  });

  // Epic 47-05 Story 1's types, here for the same reason and not for coverage of their own: nine
  // of them declare a body, so leaving them out would have shrunk this sweep from every read tool
  // with something to withhold to the six that existed when it was written.
  const document_section = call.dpm_create_document_section({
    document_id: spec.id,
    heading: 'Data Model',
    body: 'The prose that no other column can find the row by, held where a reader put it.',
    position: 0,
  });

  const adr = call.dpm_create_adr({
    parent_id: spec.id, slug: 'summaries', title: 'Read summaries by default',
    decision: 'A read returns a summary unless the caller asks for the body.',
  });
  const adr_option = call.dpm_create_adr_option({
    adr_id: adr.id, name: 'Return everything', position: 0,
    rationale: 'Simplest, and unbounded on exactly the column that grows without limit.',
  });
  const adr_option_tradeoff = call.dpm_create_adr_option_tradeoff({
    option_id: adr_option.id, axis: 'cost',
    assessment: 'Cheap to write and expensive on every call that did not want the prose.',
  });

  const quick = call.dpm_create_quick({ slug: 'bound', title: 'Bound the reads' });
  const quick_criterion = call.dpm_create_quick_criterion({
    quick_id: quick.id, text: 'the default page is smaller than the table', position: 0,
  });

  const review = call.dpm_create_review({
    parent_id: spec.id, slug: 'reads', title: 'Review of the read surface',
  });
  const finding = call.dpm_create_finding({
    review_id: review.id, position: 0,
    category_id: 'finding:testability-concerns', severity_id: 'severity:warning',
    summary: 'A bound that cannot be raised is a truncation rather than a default.',
  });

  const retro = call.dpm_create_retro({ parent_id: epic.id, slug: 'reads', title: 'Reads retro' });
  const observation = call.dpm_create_observation({
    retro_id: retro.id, story_id: story.id, position: 0,
    text: 'The body split earned its keep the first time a section body was stored.',
    synthesis: 'Declare the columns; let the convention add the argument.',
  });
  const retro_application = call.dpm_create_retro_application({
    retro_id: retro.id, applied_to_id: epic.id, disposition: 'applied',
    note: 'Every new read tool declares its body columns rather than filtering by hand.',
  });

  const artifact = call.dpm_create_artifact({
    url: 'https://example.invalid/reads', title: 'The read surface',
    description: 'A published walk through the bound and the body split.',
    published_at: '2026-08-09T00:00:00.000Z',
  });

  // A persona the plugin does not ship, which is FR24's append case and the only vocabulary with
  // prose long enough to be a body.
  const agent = call.dpm_create_agent({
    name: 'archivist',
    display_name: 'Wren',
    icon: '🗄️',
    role: 'Archivist',
    personality: 'Keeps the record of what was decided and refuses to let it be quietly rewritten.',
    communication_style: 'Cites the artefact and the date, then stops.',
    position: 20,
  });

  const milestone = call.dpm_create_milestone({
    spec_id: spec.id, label: 'M2', title: 'Spine and projection', position: 1,
    summary: 'The earliest point where the design can be judged against real use.',
  });

  return {
    spec, requirement, acceptance_criterion, epic, story, task, story_criterion, coverage, session,
    document_section, adr, adr_option, adr_option_tradeoff, quick, quick_criterion, review,
    finding, retro, observation, retro_application, artifact, agent, milestone,
  };
}

/**
 * Fifty-one of every type, hung off one root so each list tool has a scope to be given and a set
 * to be denied. Everything is created through the tools, so what is counted is what the surface
 * can actually produce.
 */
function crowd(call) {
  const home = call.dpm_create_spec({ slug: 'home', title: 'Home' });
  const spread = (n) => Array.from({ length: n }, (unused, index) => index);

  // The first spec is one of the fifty-one, so every type has the same count.
  spread(MANY - 1).forEach((index) =>
    call.dpm_create_spec({ slug: `spec-${index}`, title: `Spec ${index}` }));

  const epics = spread(MANY).map((index) =>
    call.dpm_create_epic({ parent_id: home.id, slug: `epic-${index}`, title: `Epic ${index}` }));

  // `crowd` is in the text because `requirement` is an indexed table, which makes these fifty-one
  // rows the corpus `dpm_search` is bounded against as well as the ones `dpm_list_requirement`
  // pages. One word in one place, so the two tools are held to the same row set.
  const requirements = spread(MANY).map((index) => call.dpm_create_requirement({
    spec_id: home.id, label: `FR${index}`, class: 'functional',
    text: `requirement ${index} crowd`, position: index,
  }));

  const stories = spread(MANY).map((index) => call.dpm_create_story({
    epic_id: epics[0].id, number: index + 1, title: `Story ${index}`, position: index,
  }));

  // Tasks under *two* stories, both numbered from one. `UNIQUE (story_id, number)` means the
  // numbers are unique within a story and tie across the table, so an unscoped list has fifty-one
  // pairs of rows the sort cannot separate. That is what the `id` tiebreaker is for, and without
  // rows that actually tie, dropping it is a mutation no test can see.
  [stories[0], stories[1]].forEach((story) => spread(MANY).forEach((index) =>
    call.dpm_create_task({
      story_id: story.id, number: index + 1, title: `Task ${index}`,
      description: `task ${index}`, position: index,
    })));

  spread(MANY).forEach((index) => call.dpm_create_acceptance_criterion({
    requirement_id: requirements[0].id, text: `criterion ${index}`, position: index,
  }));

  const criteria = spread(MANY).map((index) => call.dpm_create_story_criterion({
    story_id: stories[0].id, text: `story criterion ${index}`, position: index,
  }));

  spread(MANY).forEach((index) => call.dpm_create_session({
    id: `session-${String(index).padStart(4, '0')}`, skill: 'cpm:do', phase: `step ${index}`,
    state: JSON.stringify({ index }),
  }));

  spread(MANY).forEach((index) => call.dpm_create_coverage({
    requirement_id: requirements[0].id, spec_fragment: `fragment ${index}`,
    story_criterion_id: criteria[0].id, position: index,
  }));

  // The four vocabularies. They arrive seeded, so unlike every type above they are not empty to
  // begin with — which is why the sweeps below count what the database holds rather than what was
  // created here, and why fifty-one *added* terms is more than enough to make the bound bite.
  spread(MANY).forEach((index) => call.dpm_create_taxonomy({
    id: `observation:crowd-${index}`, domain: 'observation',
    name: `Crowd ${index}`, position: index,
  }));

  spread(MANY).forEach((index) => call.dpm_create_agent({
    name: `agent-${index}`, display_name: `Crowd ${index}`, icon: '🧭', role: `Role ${index}`,
    personality: `personality ${index}`, communication_style: `style ${index}`, position: index,
  }));

  spread(MANY).forEach((index) => call.dpm_create_test_approach({
    tag: `approach-${index}`, kind: 'level', position: index,
  }));

  spread(MANY).forEach((index) => call.dpm_create_dependency_kind({
    kind: `kind-${index}`, position: index,
  }));

  return { home, epic: epics[0], story: stories[0], requirement: requirements[0] };
}

/**
 * How many rows a list tool can reach, asked of the database rather than of the seeding.
 *
 * Both narrowings are read off the tool rather than named here: a `document` list is pinned to one
 * kind, and a vocabulary list hides retired terms. Restating either would make this agree with the
 * tools by coincidence.
 */
function held(db, tool) {
  // `dpm_search` reaches hits and not rows, so what it can return is the size of the match — asked
  // of both indexes, because a count of one of them is the must-NOT this story is about.
  if (tool.name === 'dpm_search') {
    return db.prepare(
      "SELECT (SELECT COUNT(*) FROM document_fts WHERE document_fts MATCH 'crowd') "
      + "+ (SELECT COUNT(*) FROM entry_fts WHERE entry_fts MATCH 'crowd') AS rows",
    ).get().rows;
  }

  const kind = tool.table === 'document' ? tool.name.replace('dpm_list_', '') : null;
  const sql = `SELECT COUNT(*) AS rows FROM ${tool.table}`
    + (kind ? ` WHERE kind = '${kind}'` : '')
    + (tool.live ? ` WHERE ${tool.live} IS NULL` : '');

  return db.prepare(sql).get().rows;
}

/** Every bounded read, taken from the registry by what it declares rather than by its name. */
const paged = (tools) => tools.filter((tool) => tool.paged);

/**
 * The bounded reads that page **a table**, which is every one of them but `dpm_search`.
 *
 * The split arrived with Epic 47-05 Story 5 and is a real distinction rather than an accommodation
 * of one tool. A list tool returns rows of its `table` in an order it declares; `dpm_search`
 * returns hits merged from two FTS indexes in `rank` order, over six tables between them. FR13
 * governs both — an unbounded search over a large corpus is exactly what the requirement forbids —
 * so every assertion about the *bound* sweeps `paged`. Only the assertions about a table's rows
 * and a table's key use this narrower set, and each says why below.
 */
const listed = (tools) => paged(tools).filter((tool) => tool.order);

/** The arguments a bounded read needs before `limit` means anything. `dpm_search` needs a query. */
const enough = (tool) => (tool.name === 'dpm_search' ? { query: 'crowd' } : {});

/** Every read tool with something to withhold. */
const withBody = (tools) =>
  tools.filter((tool) => tool.name.startsWith('dpm_read_') && tool.body.length > 0);

// --- Criterion 1: a summary is smaller than a body ----------------------------------------------

test('a read without a body request is strictly smaller than one with it', (t) => {
  const { tools, call } = surface(t);
  const created = chain(call);

  const swept = withBody(tools);
  assert.ok(swept.length > 0, 'no read tool declares a body, so nothing was compared');

  for (const tool of swept) {
    const type = tool.name.replace('dpm_read_', '');
    const row = created[type];

    // A type absent from the chain is the silent skip the chain's own comment warns about, so it
    // fails here rather than shrinking the sweep by one.
    assert.ok(row, `${tool.name} has no row in the chain, so the sweep would pass over it`);

    // The key is read off what the tool declares it requires, not assumed to be `id`. A join
    // table is identified by both its columns, and hard-coding `{id}` would have restricted this
    // sweep to the tools that happen to have a surrogate key.
    const key = Object.fromEntries(
      tool.inputSchema.required.map((column) => [column, row[column]]),
    );

    const summary = call[tool.name](key);
    const full = call[tool.name]({ ...key, include_body: true });

    // Serialised, because "fewer bytes" is a claim about what crosses the wire, and compared
    // against the other response rather than a number — a fixed threshold would be a second
    // definition of "summary", kept by hand, wrong the first time a column is added.
    assert.ok(
      JSON.stringify(summary).length < JSON.stringify(full).length,
      `${tool.name} returned no fewer bytes without its body than with it`,
    );

    // And what the difference consists of is exactly what the tool declared, so the saving is the
    // body and not some other column that went missing.
    assert.deepEqual(
      Object.keys(full).filter((column) => !Object.hasOwn(summary, column)).sort(),
      [...tool.body].sort(),
      `${tool.name} withheld something other than its declared body`,
    );
  }
});

test('an absent body request and an explicit false mean the same thing', (t) => {
  const { call } = surface(t);
  const { requirement } = chain(call);

  assert.deepEqual(
    call.dpm_read_requirement({ id: requirement.id }),
    call.dpm_read_requirement({ id: requirement.id, include_body: false }),
  );

  // The control, and the one that matters: the body is there when it is asked for. Without it,
  // a read tool that returned nothing at all would satisfy every assertion above.
  assert.equal(
    call.dpm_read_requirement({ id: requirement.id, include_body: true }).text,
    requirement.text,
  );
});

test('a tool with nothing to withhold does not advertise the argument', (t) => {
  const { tools, call } = surface(t);
  const { spec } = chain(call);

  const bodyless = tools.filter((tool) =>
    tool.name.startsWith('dpm_read_') && tool.body.length === 0);

  assert.ok(bodyless.length > 0, 'every read tool has a body, so this control checks nothing');

  for (const tool of bodyless) {
    assert.equal(tool.inputSchema.properties.include_body, undefined,
      `${tool.name} offers a body request with no body behind it`);
  }

  const error = refused(() => call.dpm_read_spec({ id: spec.id, include_body: true }));
  assert.match(error.message, /unknown argument 'include_body'/);
});

test('a list withholds bodies on the same terms as the read of its own type', (t) => {
  const { tools, call } = surface(t);
  const { requirement } = chain(call);

  const list = tools.find((tool) => tool.name === 'dpm_list_requirement');
  const read = tools.find((tool) => tool.name === 'dpm_read_requirement');

  // Taken from the read tool rather than restated, so the two cannot answer differently about the
  // same rows — which is the pair a caller compares most often.
  assert.deepEqual(list.body, read.body);
  assert.ok(list.body.length > 0);

  const summary = call.dpm_list_requirement({ spec_id: requirement.spec_id });
  const full = call.dpm_list_requirement({ spec_id: requirement.spec_id, include_body: true });

  assert.equal(Object.hasOwn(summary.items[0], 'text'), false);
  assert.equal(full.items[0].text, requirement.text);
  assert.ok(JSON.stringify(summary).length < JSON.stringify(full).length);
});

// --- Criterion 2: a defaulted limit the caller can raise -----------------------------------------

test('every list-returning tool declares a limit with a default and no ceiling', (t) => {
  const { tools } = surface(t);
  const lists = paged(tools);

  assert.ok(lists.length >= 8, 'the spine types did not all get a list tool');

  for (const tool of lists) {
    const { limit, offset } = tool.inputSchema.properties;

    assert.equal(limit?.type, 'integer', `${tool.name} declares no limit`);
    assert.equal(limit.default, DEFAULT_LIMIT, `${tool.name}'s limit has no default`);
    assert.equal(limit.minimum, 1, tool.name);

    // No `maximum`, and that absence is the requirement rather than an omission: "The bound is a
    // default that costs nothing to override, not a limit."
    assert.equal(Object.hasOwn(limit, 'maximum'), false,
      `${tool.name} caps its limit, which is the must-NOT`);

    assert.equal(offset?.type, 'integer', `${tool.name} bounds without a way past the first page`);
  }

  // The two sets agree, so a bounded read built outside a factory — and therefore without the
  // limit the factory injects — is caught by the name it would still have to carry. There are two
  // verbs that return more than one row and `dpm_search` is the second; naming it here rather than
  // loosening the pattern to "any tool" keeps the assertion's content, which is that a third verb
  // is a decision someone has to write down.
  assert.deepEqual(
    lists.map((tool) => tool.name).sort(),
    tools.map((tool) => tool.name)
      .filter((name) => name.startsWith('dpm_list_') || name === 'dpm_search')
      .sort(),
  );
});

test('a caller who raises the limit receives the larger result, on every list tool', (t) => {
  const { db, tools, call } = surface(t);
  crowd(call);

  for (const tool of paged(tools)) {
    const bounded = call[tool.name](enough(tool));
    const raised = call[tool.name]({ ...enough(tool), limit: 1000 });

    assert.equal(bounded.returned, DEFAULT_LIMIT, `${tool.name} ignored its own default`);
    assert.equal(bounded.more, true, `${tool.name} says there is no more when there is`);

    // Against the row count, so "the larger result" is the whole of what is there and not merely
    // a bigger number — a tool that doubled its default would pass a relative comparison alone.
    assert.equal(raised.returned, held(db, tool), `${tool.name} did not honour the raise`);
    assert.equal(raised.more, false, `${tool.name} still reports more after returning everything`);

    assert.ok(raised.returned > bounded.returned, `${tool.name}'s raise changed nothing`);
  }
});

test('a limit far past the row count is answered, not refused', (t) => {
  const { call } = surface(t);
  crowd(call);

  const everything = call.dpm_list_task({ limit: 100_000 });

  assert.equal(everything.returned, MANY * 2);
  assert.equal(everything.more, false);

  // And the other end: a limit below one is not a raise, it is a malformed argument.
  assert.match(refused(() => call.dpm_list_task({ limit: 0 })).message, /at least 1/);
});

// --- must NOT: an unbounded set, or a refused raise ----------------------------------------------

test('no list tool returns an unbounded set when no limit is supplied', (t) => {
  const { db, tools, call } = surface(t);
  crowd(call);

  for (const tool of paged(tools)) {
    const page = call[tool.name](enough(tool));

    assert.equal(page.items.length, DEFAULT_LIMIT, `${tool.name} returned an unbounded set`);
    assert.equal(page.limit, DEFAULT_LIMIT, `${tool.name} does not report the bound it applied`);
  }

  // The control, and the only one that makes the assertion above mean anything: there really was
  // more than the bound within reach of every tool it swept. Counted from the database rather than
  // from the seeding, so a `crowd` that silently created fewer would fail here rather than pass
  // above — and through `held`, so the count is what that tool can actually reach rather than what
  // its declared table happens to hold.
  for (const tool of paged(tools)) {
    const rows = held(db, tool);

    assert.ok(rows > DEFAULT_LIMIT, `${tool.name} reaches ${rows} rows — the bound cut nothing`);
  }
});

test('the integrity report is exempt from the bound, deliberately', (t) => {
  const { tools, call } = surface(t);

  const integrity = tools.find((tool) => tool.name === 'dpm_check_integrity');

  // NFR6's false pass is a report that says nothing is wrong because the row that was wrong fell
  // off the end of a page. Story 4 swept every list-returning tool and this one is not among them.
  assert.equal(integrity.paged, false);
  assert.match(refused(() => call.dpm_check_integrity({ limit: 10 })).message, /unknown argument/);

  assert.equal(call.dpm_check_integrity({}).ok, true);
});

// --- Paging that a second call can rely on -------------------------------------------------------

test('pages tile the result set exactly once, in a stable order', (t) => {
  const { call } = surface(t);
  crowd(call);

  // Unscoped and over the table where numbers tie in pairs, so the walk is over a set the sort
  // cannot fully order on its own. **This does not catch a dropped tiebreaker** — measured, and
  // it passes: SQLite answered the same tied order at every offset. That mutation is caught by
  // the structural test below instead, and the distinction is worth keeping straight, because a
  // walk that happens to work is not the same claim as an order that cannot come apart.
  const total = MANY * 2;
  const size = 10;
  const seen = [];

  for (let offset = 0; offset < total + size; offset += size) {
    const page = call.dpm_list_task({ limit: size, offset });

    seen.push(...page.items.map((row) => row.id));
    if (!page.more) break;
  }

  const whole = call.dpm_list_task({ limit: total }).items.map((row) => row.id);

  assert.equal(new Set(seen).size, seen.length, 'a row appeared on two pages');
  assert.equal(seen.length, total, 'walking the pages did not reach every row');
  assert.deepEqual(seen, whole, 'walking the pages does not reconstruct the ordered set');

  // The order is the one the tool declares, not insertion order that happens to agree with it:
  // each number appears twice, adjacently, because the sort is by number before anything else.
  assert.deepEqual(
    whole.map((unused, index) => Math.floor(index / 2) + 1),
    call.dpm_list_task({ limit: total }).items.map((row) => row.number),
  );
});

test('the tiebreaker on every list order is a key the table guarantees unique', (t) => {
  const { db, tools } = surface(t);

  // This is the assertion that holds the tiebreaker, and it took a mutation to establish that:
  // dropping `id` from all eight orders left the paging test above green, because SQLite's sort
  // returned the same tied order at every offset it was asked for. It is entitled not to, and the
  // day it stops is the day a page repeats a row — so the guard has to be that the order ends on
  // something the table guarantees unique, read out of the live schema rather than assumed to be
  // `id`, which is the same rule AD10 puts on the enums.
  for (const tool of listed(tools)) {
    const keys = db.prepare(`PRAGMA table_info(${tool.table})`).all()
      .filter((column) => column.pk > 0)
      .map((column) => column.name);

    assert.equal(keys.length, 1, `${tool.table} has no single-column primary key to break ties on`);
    assert.equal(tool.order.at(-1), keys[0],
      `${tool.name} orders by columns that can tie, so its pages can repeat and skip rows`);
    assert.ok(tool.order.length > 1, `${tool.name} orders by its key alone`);
  }

  // `dpm_search` is the one bounded read this cannot ask, and the exclusion is derived rather than
  // named: it has no `order` because it does not page a table, and an FTS index has no primary key
  // to break a tie on. Its tiebreaker is `entity, entity_id` after `rank`, asserted in
  // `search.test.js` against the thing that actually matters — that two pages tile the result set.
  assert.deepEqual(
    paged(tools).filter((tool) => !tool.order).map((tool) => tool.name),
    ['dpm_search'],
  );
});

test('a scope narrows a list, and its absence does not', (t) => {
  const { call } = surface(t);
  const { home, epic, story } = crowd(call);

  const scoped = call.dpm_list_story({ epic_id: epic.id, limit: MANY });
  const unscoped = call.dpm_list_story({ limit: MANY });

  assert.equal(scoped.returned, MANY);
  assert.deepEqual(scoped.items.map((row) => row.id), unscoped.items.map((row) => row.id));

  // A second epic with one story of its own separates the two: scoped stays at fifty-one,
  // unscoped grows. Without it, the equality above would hold for a tool ignoring `epic_id`.
  const other = call.dpm_create_epic({ parent_id: home.id, slug: 'other', title: 'Other' });
  call.dpm_create_story({ epic_id: other.id, number: 1, title: 'Elsewhere', position: 0 });

  assert.equal(call.dpm_list_story({ epic_id: epic.id, limit: MANY + 1 }).returned, MANY);
  assert.equal(call.dpm_list_story({ limit: MANY + 1 }).returned, MANY + 1);
  assert.equal(call.dpm_list_story({ epic_id: other.id }).items[0].title, 'Elsewhere');

  // And a list named for a kind answers for that kind only, the same rule its read tool holds to.
  assert.equal(call.dpm_list_epic({ parent_id: home.id, limit: MANY }).items
    .every((row) => row.kind === 'epic'), true);
  assert.equal(call.dpm_list_spec({ limit: MANY }).items.every((row) => row.kind === 'spec'), true);

  assert.ok(call.dpm_list_task({ story_id: story.id }).returned > 0);
});

// --- Over the protocol ---------------------------------------------------------------------------

test('a page comes back as MCP content with its bound reported', (t) => {
  const { tools, call } = surface(t);
  crowd(call);

  const table = methods(tools);
  const answered = dispatch({
    jsonrpc: '2.0', id: 1, method: 'tools/call',
    params: { name: 'dpm_list_requirement', arguments: {} },
  }, table);

  const { structuredContent } = answered.result;

  assert.equal(structuredContent.returned, DEFAULT_LIMIT);
  assert.equal(structuredContent.more, true);
  assert.equal(structuredContent.limit, DEFAULT_LIMIT);
  assert.equal(structuredContent.offset, 0);
  assert.equal(structuredContent.items.length, DEFAULT_LIMIT);

  assert.deepEqual(
    JSON.parse(answered.result.content[0].text),
    JSON.parse(JSON.stringify(structuredContent)),
    'the text and structured halves of one page disagree',
  );

  // The bound is visible in what a caller is shown before they call, too.
  const listed = table['tools/list']().tools.find((tool) => tool.name === 'dpm_list_requirement');
  assert.equal(listed.inputSchema.properties.limit.default, DEFAULT_LIMIT);
});
