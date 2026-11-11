import { expect, test } from 'claude-code/testing'
import type { On } from 'claude-code'

import { checkSignature, settledMark } from './progress'
import type { Times } from './timing'

// The plugin is loaded afresh for each test, so its module state (isChecking, isStarted, docsFolders,
// nudges, nudgeContext, the loop models and the writers) starts empty in every one.

const ROOT = '/w/proj'
const EPIC = `${ROOT}/docs/epics/01-01-epic-first.md`
const OTHER = `${ROOT}/docs/epics/01-02-epic-second.md`
const ORDER = `${ROOT}/docs/specifications/01-build-order.json`

const epicText = (title: string, status: string, count = 1) => `# ${title}

**Status**: In Progress
**Blocked by**: —

## The story
**Story**: 1
**Status**: ${status}
**Blocked by**: —
${Array.from({ length: count - 1 }, (_, i) => `
## Story ${i + 2}
**Story**: ${i + 2}
**Status**: Pending
**Blocked by**: —
`).join('')}`

type File = { text: string; mtimeMs: number; listed?: { mtimeMs: number; size: number } }

/**
 * The world beneath the plugin: a project's files with listings whose mtime can lag the file (a write
 * the listing has not caught up with), a store, the clock, and a model loop answered by `answeredBy`.
 */
function world(on: On, count = 1) {
  const files = new Map<string, File>([
    [EPIC, { text: epicText('First', 'Pending', count), mtimeMs: 1000 }],
    [OTHER, { text: epicText('Second', 'Pending'), mtimeMs: 1000 }],
    [ORDER, { text: JSON.stringify({ title: '01 build order', phases: [{ label: 'p', items: [...Array.from({ length: count }, (_, i) => ({ epic: '01-01', story: i + 1 })), { epic: '01-02', story: 1 }] }] }), mtimeMs: 1000 }],
  ])
  const store = new Map<string, unknown>()
  const reads: string[] = []
  const toasts: string[] = []
  const prompts: { text: string; context?: string[] }[] = []
  /** The artifact's collections as the database holds them; `applyPending` writes a pending file's writes into them. */
  const live = new Map<string, { id: string; version: number; data: Record<string, unknown> }[]>()
  const state = { answeredBy: 'claude-opus-5-5' as string | null, now: 1000, toolResult: { result: 'ok' } as Record<string, unknown>, chunks: [] as unknown[], stepError: null as Error | null, duringStep: null as null | (() => Promise<unknown>), artifactReads: 0 }
  const dirs = new Set([`${ROOT}/docs/specifications`, `${ROOT}/docs/epics`])

  on('session.cwd', () => ({ value: ROOT }))
  on('env.get', () => ({ value: '/home' }))
  on('clock.now', () => ({ value: state.now }))
  on('fs.exists', (_$, e) => ({ value: files.has(e.path) || dirs.has(e.path) }))
  on('fs.read', (_$, e) => {
    reads.push(e.path)
    if (e.path.endsWith('/page/tracker.html')) return { value: '<p>{{TITLE}}</p><section id="detail"></section>' }
    const file = files.get(e.path)
    if (file === undefined) throw new Error(`no file ${e.path}`)

    return { value: file.text }
  })
  on('fs.write', (_$, e) => {
    files.set(e.path, { text: e.text, mtimeMs: state.now })

    return { value: undefined }
  })
  on('fs.list', (_$, e) => ({
    value: [...files].filter(([path]) => path.slice(0, path.lastIndexOf('/')) === e.path).map(([path, file]) => ({
      name: path.slice(path.lastIndexOf('/') + 1), kind: 'file' as const, size: file.listed?.size ?? file.text.length, mtimeMs: file.listed?.mtimeMs ?? file.mtimeMs, isLink: false,
    })),
  }))
  on('store.get', (_$, e) => ({ value: store.get(e.key) }))
  on('store.set', (_$, e) => {
    store.set(e.key, e.value)

    return { value: undefined }
  })
  on('store.delete', (_$, e) => {
    store.delete(e.key)

    return { value: undefined }
  })
  on('store.keys', () => ({ value: [...store.keys()] }))
  on('ui.invalidate', () => ({ value: undefined }))
  on('ui.toast', (_$, e) => {
    toasts.push(String((e as { text?: unknown }).text ?? ''))

    return { value: undefined }
  })
  on('tool.call', (_$, e) => {
    if (e.tool !== 'ArtifactData') return state.toolResult as never
    state.artifactReads += 1
    const docs = live.get(String((e as { collection?: unknown }).collection)) ?? []

    return { result: '', text: docs.map(d => JSON.stringify(d)).join('\n') } as never
  })
  on('prompt.submit', (_$, e) => {
    prompts.push(e as never)

    return { text: (e as { text: string }).text } as never
  })
  on('turn.step', async function* (_$, e) {
    for (const chunk of state.chunks) yield chunk as never
    if (state.duringStep !== null) await state.duringStep()
    if (state.stepError !== null) throw state.stepError

    return { turnId: e.turnId, index: e.index, answer: '', toolUses: [], stopReason: 'end_turn', usage: state.answeredBy === null ? null : { model: state.answeredBy, input_tokens: 0, output_tokens: 0, cache_read_input_tokens: 0, cache_creation_input_tokens: 0 } } as never
  })

  /** Sets a story's status in an epic doc as a write does: new text, a new mtime, and a listing that shows it unless `isListed` is false. */
  const setStatus = (path: string, status: string, at: number, isListed = true) => {
    const file = files.get(path)
    if (file === undefined) throw new Error(`no file ${path}`)
    const text = file.text.replace(/(\*\*Story\*\*: 1\n\*\*Status\*\*: )\S.*/, `$1${status}`)
    files.set(path, { text, mtimeMs: at, ...(isListed ? {} : { listed: { mtimeMs: file.mtimeMs, size: file.text.length } }) })
  }
  const catchUp = (path: string) => {
    const file = files.get(path)
    if (file !== undefined) files.set(path, { text: file.text, mtimeMs: file.mtimeMs })
  }
  const times = () => (store.get(`times:${ROOT}`) ?? {}) as Times

  const applyPending = (name: string) => {
    const pending = JSON.parse(files.get(`${ROOT}/.claude/cpm-next-progress/${name}.pending.json`)?.text ?? '{"batches":[]}') as { batches: { op: string; collection: string; doc_id: string; data: Record<string, unknown> }[][] }
    for (const write of pending.batches.flat()) {
      const docs = (live.get(write.collection) ?? []).filter(d => d.id !== write.doc_id)
      const before = (live.get(write.collection) ?? []).find(d => d.id === write.doc_id)
      if (write.op === 'set') docs.push({ id: write.doc_id, version: (before?.version ?? 0) + 1, data: write.data })
      live.set(write.collection, docs)
    }
  }

  /** The listing signature a check of this project computes, in the form the release before the row-schema version stored it. */
  const listings = () => [`${ROOT}/docs/specifications`, `${ROOT}/docs/epics`]
    .map(dir => [...files].filter(([path]) => path.slice(0, path.lastIndexOf('/')) === dir && /(-build-order\.json|-epic-.*\.md)$/.test(path))
      .map(([path, file]) => `${path.slice(path.lastIndexOf('/') + 1)}:${file.mtimeMs}:${file.text.length}`).sort().join(','))
    .join('|')
  /** Drops the fields this release added from the artifact's rows and meta, as an older release left them. */
  const stripNewFields = () => {
    for (const doc of live.get('items') ?? []) for (const key of ['model', 'modelPlanned', 'effort', 'took', 'criteria', 'needs']) delete doc.data[key]
    for (const doc of live.get('meta') ?? []) for (const key of ['timed', 'typical', 'unmatched']) delete doc.data[key]
  }

  return { files, state, setStatus, catchUp, times, reads, toasts, prompts, applyPending, listings, stripNewFields, live, store: (key: string) => store.get(key), seed: (key: string, value: unknown) => store.set(key, value) }
}

/** One model step of a loop, drained, returning the chunks the caller saw. */
async function step($: { turn: { step: (input: never) => AsyncIterable<unknown> & PromiseLike<unknown> } }, model: string, agentId?: string): Promise<unknown[]> {
  const seen: unknown[] = []
  const stream = $.turn.step({ turnId: 't', index: 0, model, messageCount: 1, ...(agentId === undefined ? {} : { agentId }) } as never)
  for await (const chunk of stream) seen.push(chunk)

  return seen
}

/** A tool call in a loop. */
const call = ($: { tool: { call: (input: never) => Promise<unknown> } }, input: Record<string, unknown>) => $.tool.call(input as never)

const bash = (command: string, agentId?: string) => ({ tool: 'Bash', command, ...(agentId === undefined ? {} : { agentId }) })
const edit = (tool: string, filePath: string, agentId?: string) => ({ tool, file_path: filePath, old_string: 'a', new_string: 'b', ...(agentId === undefined ? {} : { agentId }) })

test('a subagent answered by Sonnet that sets a story In Progress is recorded as its writer, from the check its Edit triggered', async ($, on) => {
  const w = world(on)
  await call($, bash('ls'))
  expect(w.times()['01-01 S1']).toEqual({ status: 'Pending', effort: 'medium' })

  w.state.answeredBy = 'claude-sonnet-5-5'
  await step($, 'claude-sonnet-5-5', 'a1')
  w.setStatus(EPIC, 'In Progress', 2000)
  await call($, edit('Edit', EPIC, 'a1'))

  expect(w.times()['01-01 S1']).toEqual({ status: 'In Progress', effort: 'medium', started: 2000, model: 'sonnet' })
})

test('a start is credited to the last writer of its file, not to the loop whose call let the check see it', async ($, on) => {
  const w = world(on)
  await call($, bash('ls'))

  w.state.answeredBy = 'claude-haiku-5-5'
  await step($, 'claude-haiku-5-5', 'a1')
  // The listing still shows the old mtime, so the check the Edit triggers skips on its signature.
  w.setStatus(EPIC, 'In Progress', 2000, false)
  await call($, edit('Edit', EPIC, 'a1'))
  expect(w.times()['01-01 S1']?.status).toBe('Pending')

  w.state.answeredBy = 'claude-opus-5-5'
  await step($, 'claude-opus-5-5')
  w.catchUp(EPIC)
  await call($, bash('git status'))

  expect(w.times()['01-01 S1']).toEqual({ status: 'In Progress', effort: 'medium', started: 2000, model: 'haiku' })
})

test('a start in a file written by two loops records the later writer', async ($, on) => {
  const w = world(on)
  await call($, bash('ls'))
  w.state.answeredBy = 'claude-haiku-5-5'
  await step($, 'claude-haiku-5-5', 'a1')
  await call($, edit('Write', EPIC, 'a1'))
  w.state.answeredBy = 'claude-sonnet-5-5'
  await step($, 'claude-sonnet-5-5', 'a2')
  w.setStatus(EPIC, 'In Progress', 2000)
  await call($, edit('MultiEdit', EPIC, 'a2'))

  expect(w.times()['01-01 S1']?.model).toBe('sonnet')
})

const NO_WRITER: [string, Record<string, unknown>, Record<string, unknown>][] = [
  ['a Read of the epic doc', { tool: 'Read', file_path: EPIC }, { result: 'ok' }],
  ['a NotebookEdit', { tool: 'NotebookEdit', notebook_path: EPIC, new_source: 'x' }, { result: 'ok' }],
  ['a Bash naming no epic doc', bash('sed -i s/a/b/ docs/specifications/notes.txt'), { result: 'ok' }],
  ['a denied Edit', edit('Edit', EPIC), { deny: 'refused' }],
  ['an Edit that errors', edit('Edit', EPIC), { result: 'boom', isError: true }],
]

for (const [label, input, result] of NO_WRITER) {
  test(`${label} records no writer`, async ($, on) => {
    const w = world(on)
    await call($, bash('ls'))
    await step($, 'claude-opus-5-5')
    w.state.toolResult = result
    await call($, input)
    w.state.toolResult = { result: 'ok' }
    // The start is seen by a later check that no write of the epic doc triggered.
    w.setStatus(EPIC, 'In Progress', 2000)
    await call($, bash('true'))

    expect(w.times()['01-01 S1']).toEqual({ status: 'In Progress', effort: 'medium', started: 2000 })
  })
}

const WRITER: [string, Record<string, unknown>][] = [
  ['a Bash naming the epic doc', bash("perl -pi -e 's/Pending/In Progress/' docs/epics/01-01-epic-first.md")],
  ['an Edit', edit('Edit', EPIC)],
  ['a Write', edit('Write', EPIC)],
  ['a MultiEdit', edit('MultiEdit', EPIC)],
]

for (const [label, input] of WRITER) {
  test(`${label} records its loop as the writer`, async ($, on) => {
    const w = world(on)
    await call($, bash('ls'))
    await step($, 'claude-opus-5-5')
    w.setStatus(EPIC, 'In Progress', 2000)
    await call($, input)

    expect(w.times()['01-01 S1']).toEqual({ status: 'In Progress', effort: 'medium', started: 2000, model: 'opus' })
  })
}

test('a writer of one epic doc is not credited with a start in another', async ($, on) => {
  const w = world(on)
  await call($, bash('ls'))
  await step($, 'claude-opus-5-5')
  await call($, edit('Edit', EPIC))
  w.setStatus(OTHER, 'In Progress', 2000)
  await call($, bash('true'))

  expect(w.times()['01-02 S1']).toEqual({ status: 'In Progress', effort: 'medium', started: 2000 })
  // Control: the same start, with a writer for its own file, records it.
  w.setStatus(EPIC, 'In Progress', 3000)
  await call($, edit('Edit', EPIC))
  expect(w.times()['01-01 S1']?.model).toBe('opus')
})

test('the turn.step hook passes every chunk and the result through, and lets an error propagate', async ($, on) => {
  const w = world(on)
  w.state.chunks = [{ kind: 'text', index: 0, text: 'a' }, { kind: 'text', index: 0, text: 'b' }]
  expect(await step($, 'claude-opus-5-5')).toEqual(w.state.chunks)

  w.state.stepError = new Error('the request failed')
  let caught: unknown
  try {
    await step($, 'claude-opus-5-5')
  } catch (error) {
    caught = error
  }
  // The engine wraps what the bottom threw; the call rejects rather than resolving with a result.
  expect(caught).toBeInstanceOf(Error)
})

test('a tool call made during a step sees the model the step asked for; one after sees the model that answered', async ($, on) => {
  const w = world(on)
  await call($, bash('ls'))
  w.state.answeredBy = 'claude-opus-5-5'
  w.state.duringStep = () => call($, edit('Edit', EPIC, 'a1'))
  await step($, 'claude-haiku-5-5', 'a1')
  w.state.duringStep = null
  w.setStatus(EPIC, 'In Progress', 2000)
  await call($, bash('true'))
  expect(w.times()['01-01 S1']?.model).toBe('haiku')

  w.setStatus(OTHER, 'In Progress', 3000)
  await call($, edit('Edit', OTHER, 'a1'))
  expect(w.times()['01-02 S1']?.model).toBe('opus')
})

test('a step with no usage keeps the model the loop asked for; one with usage replaces it', async ($, on) => {
  const w = world(on)
  await call($, bash('ls'))
  w.state.answeredBy = null
  await step($, 'claude-haiku-5-5', 'a1')
  w.setStatus(EPIC, 'In Progress', 2000)
  await call($, edit('Edit', EPIC, 'a1'))
  expect(w.times()['01-01 S1']?.model).toBe('haiku')

  // Control: the same step answered with a usage replaces the model.
  w.state.answeredBy = 'claude-sonnet-5-5'
  await step($, 'claude-haiku-5-5', 'a1')
  w.setStatus(OTHER, 'In Progress', 3000)
  await call($, edit('Edit', OTHER, 'a1'))
  expect(w.times()['01-02 S1']?.model).toBe('sonnet')
})

test('a subagent\'s turn.complete forgets its loop, while the files it wrote keep its model', async ($, on) => {
  const w = world(on)
  on('turn.complete', () => ({ text: '' }) as never)
  await call($, bash('ls'))
  w.state.answeredBy = 'claude-haiku-5-5'
  await step($, 'claude-haiku-5-5', 'a1')
  await call($, edit('Edit', EPIC, 'a1'))
  await $.turn.complete({ answer: '', durationMs: 1, isAborted: false, turnId: 't', agentId: 'a1', reason: 'answer' } as never)

  // A start seen after the loop ended, in the file it wrote, still records its model.
  w.setStatus(EPIC, 'In Progress', 2000)
  await call($, bash('true'))
  expect(w.times()['01-01 S1']?.model).toBe('haiku')

  // The loop itself is forgotten: a later write in its name records no writer.
  w.setStatus(OTHER, 'In Progress', 3000)
  await call($, edit('Edit', OTHER, 'a1'))
  expect(w.times()['01-02 S1']).toEqual({ status: 'In Progress', effort: 'medium', started: 3000 })
})

test('a story not started takes the planned model from the project-scoped install of cpm-next before the user one, read once per check', async ($, on) => {
  const w = world(on)
  const order = JSON.parse(w.files.get(ORDER)?.text ?? '{}') as Record<string, unknown>
  w.files.set(ORDER, { text: JSON.stringify({ ...order, artifact: 'https://claude.ai/artifact/abc' }), mtimeMs: 1000 })
  // Two trackers in one check: the SKILL.md is still read once.
  w.files.set(`${ROOT}/docs/specifications/02-build-order.json`, { text: JSON.stringify({ ...order, artifact: 'https://claude.ai/artifact/def' }), mtimeMs: 1000 })
  w.files.set('/home/.claude/plugins/installed_plugins.json', {
    text: JSON.stringify({ plugins: { 'cpm-next@m': [{ scope: 'user', installPath: '/user/cpm-next' }, { scope: 'project', projectPath: ROOT, installPath: '/project/cpm-next' }] } }),
    mtimeMs: 1,
  })
  w.files.set('/user/cpm-next/skills/do/SKILL.md', { text: '---\nname: do\nmodel: opus\n---\n', mtimeMs: 1 })
  w.files.set('/project/cpm-next/skills/do/SKILL.md', { text: '---\nname: do\nmodel: sonnet\n---\n', mtimeMs: 1 })
  w.state.toolResult = { result: '' }
  await call($, bash('ls'))

  const pending = JSON.parse(w.files.get(`${ROOT}/.claude/cpm-next-progress/01-build-order.pending.json`)?.text ?? '{}') as { batches: { doc_id: string; data: Record<string, unknown> }[][] }
  const row = pending.batches.flat().find(write => write.doc_id === '01-01-s1')
  expect(row?.data).toMatchObject({ model: 'sonnet', modelPlanned: true })
  expect(w.files.has(`${ROOT}/.claude/cpm-next-progress/02-build-order.pending.json`)).toBe(true)
  expect(w.reads.filter(path => path.endsWith('installed_plugins.json')).length).toBe(1)
})

test('a check writes the meta with every decision and the unmatched ones, an empty list when all match', async ($, on) => {
  const w = world(on)
  const order = JSON.parse(w.files.get(ORDER)?.text ?? '{}') as Record<string, unknown>
  const decisions = ['[01-01 S1, review] matched', 'no prefix', '[09-09 S1, input] no such row']
  w.files.set(ORDER, { text: JSON.stringify({ ...order, artifact: 'https://claude.ai/artifact/abc', decisions }), mtimeMs: 1000 })
  w.files.set(`${ROOT}/docs/specifications/02-build-order.json`, { text: JSON.stringify({ ...order, title: '02', artifact: 'https://claude.ai/artifact/def', decisions: ['[01-01 S1, review] matched'] }), mtimeMs: 1000 })
  w.state.toolResult = { result: '' }
  await call($, bash('ls'))

  const metaOf = (name: string) => (JSON.parse(w.files.get(`${ROOT}/.claude/cpm-next-progress/${name}.pending.json`)?.text ?? '{}') as { batches: { doc_id: string; collection: string; data: Record<string, unknown> }[][] })
    .batches.flat().find(write => write.collection === 'meta')?.data
  expect(metaOf('01-build-order')).toMatchObject({ decisions, unmatched: ['no prefix', '[09-09 S1, input] no such row'] })
  expect(metaOf('02-build-order')).toMatchObject({ decisions: ['[01-01 S1, review] matched'], unmatched: [] })
})

/** A project whose tracker is published and in step with the docs, the story In Progress with one unproven criterion. */
async function inStep($: Parameters<typeof call>[0] & Parameters<typeof step>[0], w: ReturnType<typeof world>) {
  const order = JSON.parse(w.files.get(ORDER)?.text ?? '{}') as Record<string, unknown>
  w.files.set(ORDER, { text: JSON.stringify({ ...order, artifact: 'https://claude.ai/artifact/abc' }), mtimeMs: 1000 })
  const epic = w.files.get(EPIC)?.text ?? ''
  w.files.set(EPIC, { text: epic.replace('**Status**: Pending\n**Blocked by**: —\n', '**Status**: In Progress\n**Blocked by**: —\n\n**Acceptance Criteria**:\n\n- it works `[unit]`\n'), mtimeMs: 1000 })
  w.state.toolResult = { result: 'ok' }
  await call($, bash('ls'))
  w.applyPending('01-build-order')
  // Settle the check's record of the tracker being behind, as the turn-end writes would.
  w.state.now = 1500
  w.files.set(ORDER, { text: w.files.get(ORDER)?.text ?? '', mtimeMs: 1500 })
  await call($, bash('ls'))
  w.toasts.length = 0
}

const addEvidence = (w: ReturnType<typeof world>, at: number) => {
  const file = w.files.get(EPIC)
  w.files.set(EPIC, { text: (file?.text ?? '').replace('- it works `[unit]`\n', '- it works `[unit]`\n  - Evidence: a test — red: x\n'), mtimeMs: at })
}

test('a change to a row\'s criteria alone puts no note on the tool result; the writes are asked for at the turn\'s end', async ($, on) => {
  const w = world(on)
  on('turn.complete', () => ({ text: '' }) as never)
  await inStep($, w)

  addEvidence(w, 2000)
  const result = await call($, edit('Edit', EPIC)) as { context?: string[] }
  expect(w.store('behind:/w/proj')).toBe(true)
  const pending = JSON.parse(w.files.get(`${ROOT}/.claude/cpm-next-progress/01-build-order.pending.json`)?.text ?? '{}') as { batches: { doc_id: string; data: Record<string, unknown> }[][] }
  expect(pending.batches.flat().map(write => write.doc_id)).toEqual(['01-01-s1'])
  expect(pending.batches.flat()[0]?.data.criteria).toEqual({ met: 1, total: 1 })
  expect(result.context ?? []).toEqual([])
  expect(w.toasts).toEqual([])

  await $.turn.complete({ answer: 'done', durationMs: 1, isAborted: false, turnId: 't', reason: 'answer' } as never)
  for (let i = 0; i < 50 && w.prompts.length === 0; i += 1) await new Promise(resolve => setTimeout(resolve, 5))
  // The prompt names the row and the file holding its write. Under `claude plugin test` the plugin's own
  // prompt.submit hook does not run for this prompt, so the context it attaches is not checked here.
  expect(w.prompts.length).toBe(1)
  expect(w.prompts[0]?.text).toMatch(/01-01-s1/)
  expect(w.prompts[0]?.text).toMatch(/\.claude\/cpm-next-progress\/01-build-order\.pending\.json/)
  expect(w.prompts[0]?.text).toContain('url https://claude.ai/artifact/abc')
  expect(w.prompts[0]?.text).not.toContain('given with this message')
})

test('control: the same story moving to Complete puts the note on the tool result and toasts', async ($, on) => {
  const w = world(on)
  await inStep($, w)

  w.setStatus(EPIC, 'Complete', 2000)
  const result = await call($, edit('Edit', EPIC)) as { context?: string[] }
  expect((result.context ?? []).join(' ')).toMatch(/Progress tracker out of date/)
  expect(w.toasts.length).toBe(1)
})

test('a drift with a criteria-only row change and another row change puts the note for all its writes on the result', async ($, on) => {
  const w = world(on)
  await inStep($, w)

  addEvidence(w, 2000)
  w.setStatus(OTHER, 'In Progress', 2000)
  const result = await call($, edit('Edit', EPIC)) as { context?: string[] }
  const note = (result.context ?? []).join(' ')
  expect(note).toMatch(/"doc_id":"01-01-s1"/)
  expect(note).toMatch(/"doc_id":"01-02-s1"/)
})

/** Every story of the tracker Complete, its artifact published and its rows written: a settled tracker. */
async function settled($: Parameters<typeof call>[0], w: ReturnType<typeof world>) {
  const order = JSON.parse(w.files.get(ORDER)?.text ?? '{}') as Record<string, unknown>
  w.files.set(ORDER, { text: JSON.stringify({ ...order, artifact: 'https://claude.ai/artifact/abc' }), mtimeMs: 1000 })
  w.setStatus(EPIC, 'Complete', 1000)
  w.setStatus(OTHER, 'Complete', 1000)
}

test('marks stored without the row-schema version make the next check read every tracker, a settled one included', async ($, on) => {
  const w = world(on)
  await settled($, w)
  const size = (w.files.get(ORDER)?.text ?? '').length
  w.seed(`index:${ROOT}/01-build-order.json`, { root: ROOT, name: '01-build-order.json', title: '01', state: 'tracked', done: 2, total: 2, active: [], waiting: 0, changed: '', checked: '' })
  w.seed(`settled:${ROOT}/01-build-order.json`, { mark: `1000:${size}`, line: '01-build-order.json: complete' })
  w.seed(`checked:${ROOT}`, `${ROOT}|${w.listings()}`)
  await call($, bash('ls'))
  expect(w.state.artifactReads).toBeGreaterThan(0)
})

test('control: marks stored with the current row-schema version leave the settled tracker unread', async ($, on) => {
  const w = world(on)
  await settled($, w)
  const size = (w.files.get(ORDER)?.text ?? '').length
  w.seed(`index:${ROOT}/01-build-order.json`, { root: ROOT, name: '01-build-order.json', title: '01', state: 'tracked', done: 2, total: 2, active: [], waiting: 0, changed: '', checked: '' })
  w.seed(`settled:${ROOT}/01-build-order.json`, { mark: settledMark({ mtimeMs: 1000, size }), line: '01-build-order.json: complete' })
  // A doc changed since the last check, so the check runs, and still leaves the settled tracker unread.
  w.seed(`checked:${ROOT}`, checkSignature(ROOT, 'an older listing'))
  await call($, bash('ls'))
  expect(w.state.artifactReads).toBe(0)
})

/** A published tracker in step with the docs, whose live rows and meta are then left as an older release wrote them. */
async function published($: Parameters<typeof call>[0], w: ReturnType<typeof world>) {
  const order = JSON.parse(w.files.get(ORDER)?.text ?? '{}') as Record<string, unknown>
  w.files.set(ORDER, { text: JSON.stringify({ ...order, artifact: 'https://claude.ai/artifact/abc' }), mtimeMs: 1000 })
  w.state.toolResult = { result: 'ok' }
  await call($, bash('ls'))
  w.applyPending('01-build-order')
}

const republish = ($: Parameters<typeof call>[0]) => call($, { tool: 'Artifact', file_path: `${ROOT}/.claude/cpm-next-progress/01-build-order.html`, url: 'https://claude.ai/artifact/abc' }) as Promise<{ context?: string[] }>

test('a republish over unchanged docs hands over the writes for rows that lack the new fields: inline for 6 rows', async ($, on) => {
  const w = world(on, 5)
  await published($, w)
  w.stripNewFields()
  expect((w.live.get('items') ?? []).length).toBe(6)
  w.state.toolResult = { result: '', text: 'Published https://claude.ai/artifact/abc' }
  const note = ((await republish($)).context ?? []).join(' ')
  expect(note).toMatch(/Writes: \[/)
  const writes = JSON.parse(/Writes: (\[.*\])/.exec(note)?.[1] ?? '[]') as { collection: string; if_version?: number }[]
  expect(writes.length).toBe(7)
  expect(writes.every(write => typeof write.if_version === 'number')).toBe(true)
})

test('a republish with 12 such rows hands the writes to a subagent through the pending file', async ($, on) => {
  const w = world(on, 11)
  await published($, w)
  w.stripNewFields()
  w.state.toolResult = { result: '', text: 'Published https://claude.ai/artifact/abc' }
  const note = ((await republish($)).context ?? []).join(' ')
  expect(note).toMatch(/Start a subagent/)
  const pending = JSON.parse(w.files.get(`${ROOT}/.claude/cpm-next-progress/01-build-order.pending.json`)?.text ?? '{}') as { batches: { if_version?: number }[][] }
  expect(pending.batches.flat().length).toBe(13)
})

test('control: a republish over rows and meta that already hold every new field gives no writes and no note', async ($, on) => {
  const w = world(on, 5)
  await published($, w)
  w.state.toolResult = { result: '', text: 'Published https://claude.ai/artifact/abc' }
  w.toasts.length = 0
  const result = await republish($)
  expect(result.context ?? []).toEqual([])
  expect(w.toasts).toEqual([])
})

test('preparing an existing tracker says its rows are brought up to date after the republish', async ($, on) => {
  const w = world(on)
  on('clock.after', () => ({ value: undefined }) as never)
  const order = JSON.parse(w.files.get(ORDER)?.text ?? '{}') as Record<string, unknown>
  w.files.set(ORDER, { text: JSON.stringify({ ...order, artifact: 'https://claude.ai/artifact/abc' }), mtimeMs: 1000 })
  w.files.set(`${ROOT}/.gitignore`, { text: '/.claude/cpm-next-progress\n', mtimeMs: 1 })
  w.state.toolResult = { result: 'ok' }
  const result = await $.command.run({ command: 'progress-tracker', args: '01' } as never) as { text?: string }
  expect(result.text).toMatch(/already has a tracker/)
  expect(result.text).toMatch(/rows are brought up to date once it is republished/)
  expect(result.text).not.toMatch(/untouched/)
})

