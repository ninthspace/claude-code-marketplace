import { expect, test } from 'claude-code/testing'

import { overviewNote, overviewRows, overviewWrites } from './progress'
import type { TrackerItem } from './progress'
import type { Times } from './timing'
import { MIN_STORIES, activeNote, indexEntry, range, typicalRanges, timingOf, durations, estimate, estimateFor, forgetLoop, modelOf, observe, recordStep, recordTimes, span, timesReport, writtenEpics } from './timing'

const MIN = 60_000
const T0 = Date.UTC(2026, 9, 15, 9)

const epic = (status: string, effort = '') => ({
  name: '04-01-epic-the-workspace-core.md',
  text: `# The workspace core

**Status**: In Progress

## Settings
**Story**: 5
**Status**: ${status}
${effort === '' ? '' : `**Effort**: ${effort}\n`}**Blocked by**: —
`,
})

const seen = (status: string, at: number, effort = '') => observe([{ ...epic(status, effort), mtimeMs: at }])

/** `count` finished stories of `effort` that took the given minutes in turn. */
function finished(minutes: number[], effort = 'medium'): Times {
  return Object.fromEntries(minutes.map((m, i) => [`01-01 S${i + 1}`, { status: 'Complete', effort, started: T0, finished: T0 + m * MIN }]))
}

test('stories are keyed as the tracker names them, with medium for no effort', () => {
  expect(seen('In Progress', T0)).toEqual([{ key: '04-01 S5', status: 'In Progress', effort: 'medium', at: T0, file: '04-01-epic-the-workspace-core.md' }])
  expect(seen('Pending', T0, 'High')[0]?.effort).toBe('high')
})

test('a story is timed from the check that sees it start to the one that sees it finish', () => {
  let times = recordTimes({}, seen('Pending', T0))
  times = recordTimes(times, seen('In Progress', T0 + 5 * MIN, 'high'))
  times = recordTimes(times, seen('Complete', T0 + 50 * MIN, 'high'))

  expect(times['04-01 S5']).toEqual({ status: 'Complete', effort: 'high', started: T0 + 5 * MIN, finished: T0 + 50 * MIN })
  expect(durations(times)).toEqual([45])
})

test('a story first seen part-way, or seen to jump from Pending to Complete, gets no time', () => {
  const partWay = recordTimes(recordTimes({}, seen('In Progress', T0)), seen('Complete', T0 + 30 * MIN))
  const jumped = recordTimes(recordTimes({}, seen('Pending', T0)), seen('Complete', T0 + 30 * MIN))

  expect(durations(partWay)).toEqual([])
  expect(durations(jumped)).toEqual([])
  expect(partWay['04-01 S5']?.started).toBeUndefined()
})

test('a later check that sees no change keeps the start', () => {
  let times = recordTimes(recordTimes({}, seen('Pending', T0)), seen('In Progress', T0 + MIN))
  times = recordTimes(times, seen('In Progress', T0 + 20 * MIN))

  expect(times['04-01 S5']?.started).toBe(T0 + MIN)
})

test('a reopened story drops its finish and goes on from its first start', () => {
  let times = recordTimes(recordTimes({}, seen('Pending', T0)), seen('In Progress', T0 + MIN))
  times = recordTimes(times, seen('Complete', T0 + 10 * MIN))
  times = recordTimes(times, seen('In Progress', T0 + 12 * MIN))

  expect(times['04-01 S5']).toEqual({ status: 'In Progress', effort: 'medium', started: T0 + MIN })
  times = recordTimes(times, seen('Complete', T0 + 40 * MIN))
  expect(durations(times)).toEqual([39])
})

test('no estimate below the minimum number of timed stories', () => {
  expect(estimate(Array.from({ length: MIN_STORIES - 1 }, () => 30))).toBeUndefined()
  expect(estimate(Array.from({ length: MIN_STORIES }, () => 30))?.count).toBe(MIN_STORIES)
})

test('an estimate is the middle half and median, steady only when the slow quartile is within three times the quick', () => {
  const steady = estimate([20, 25, 30, 30, 35, 40, 40, 45, 50, 60])
  expect(steady).toEqual({ count: 10, low: 30, mid: 37.5, high: 43.75, isSteady: true })
  expect(estimate([5, 5, 5, 6, 6, 60, 70, 80, 90, 100])?.isSteady).toBe(false)
})

test('a story is estimated from its own effort when there are enough of those, else from all', () => {
  const times = { ...finished([10, 10, 10, 10, 10, 10, 10, 10, 10, 10], 'low') }
  expect(estimateFor(times, 'low')?.basis).toBe('low stories')
  expect(estimateFor(times, 'high')?.basis).toBe('stories')
  expect(estimateFor(finished([10, 10]), 'medium')).toBeUndefined()
})

test('spans read as minutes, then hours', () => {
  expect(span(44.6)).toBe('45 min')
  expect(span(60)).toBe('1 h')
  expect(span(95)).toBe('1 h 35 min')
  expect(span(-3)).toBe('0 min')
})

test('the pane note gives the time in, and a range only when the timings are steady', () => {
  const running = { status: 'In Progress' as const, effort: 'medium', started: T0 }
  const steady: Times = { ...finished([30, 30, 35, 40, 40, 40, 45, 50, 50, 60]), '04-01 S5': running }
  const varied: Times = { ...finished([5, 5, 5, 6, 6, 60, 70, 80, 90, 100]), '04-01 S5': running }

  expect(activeNote(steady, '04-01 S5', T0 + 25 * MIN)).toBe('25 min in, typically 36–49 min')
  expect(activeNote(varied, '04-01 S5', T0 + 25 * MIN)).toBe('25 min in')
  expect(activeNote({}, '04-01 S5', T0)).toBe('')
  expect(activeNote({ '04-01 S5': { status: 'In Progress', effort: 'medium' } }, '04-01 S5', T0)).toBe('')
})

test('the overview note carries each story\'s timing', () => {
  const entry = { root: '/r', name: '04-build-order.json', title: '04', state: 'tracked' as const, done: 2, total: 19, active: ['04-01 S5', '04-01 S6'], waiting: 0, changed: '', checked: '' }
  expect(overviewNote(entry, story => (story === '04-01 S5' ? '25 min in' : ''))).toBe('in progress: 04-01 S5 (25 min in), 04-01 S6')
})

test('the report says what is timed and what is left, and why there is no estimate', () => {
  expect(timesReport('opus-opus', {}, T0)).toMatch(/no story has been timed yet/)

  const few: Times = { ...finished([20, 40]), '04-01 S5': { status: 'In Progress', effort: 'high', started: T0 } }
  const fewReport = timesReport('opus-opus', few, T0 + 10 * MIN)
  expect(fewReport).toMatch(/2 stories timed/)
  expect(fewReport).toMatch(/No estimate until 10 are timed; so far they took 20 min, 40 min\./)
  expect(fewReport).toMatch(/04-01 S5 \(high\): 10 min in\./)

  const many: Times = { ...finished([30, 30, 35, 40, 40, 40, 45, 50, 50, 60]), '04-01 S5': { status: 'In Progress', effort: 'medium', started: T0 } }
  const report = timesReport('opus-opus', many, T0 + 20 * MIN)
  expect(report).toMatch(/All: half took 36–49 min, median 40 min, of 10\./)
  expect(report).toMatch(/04-01 S5 \(medium\): 20 min in; medium stories typically take 36–49 min, so about 16–29 min left\./)
  expect(timesReport('opus-opus', many, T0 + 90 * MIN)).toMatch(/past the slower half of medium stories \(49 min\)/)
})

test('a page row carries the start of a timed story in progress, and its range only when steady', () => {
  const running = { status: 'In Progress' as const, effort: 'medium', started: T0 }
  expect(timingOf({ ...finished([30, 30, 35, 40, 40, 40, 45, 50, 50, 60]), '04-01 S5': running }, '04-01 S5')).toEqual({ started: T0, typical: '36–49 min' })
  expect(timingOf({ '04-01 S5': running }, '04-01 S5')).toEqual({ started: T0, typical: '' })
  expect(timingOf({ '04-01 S5': { status: 'In Progress', effort: 'medium' } }, '04-01 S5')).toBeUndefined()
  expect(timingOf({ '04-01 S5': { ...running, status: 'Complete' } }, '04-01 S5')).toBeUndefined()
})

test('timings pass from tracker rows to the index and the overview rows, without moving the changed date', () => {
  const row = (story: string, status: TrackerItem['status'], extra: Partial<TrackerItem> = {}): [string, TrackerItem] =>
    [`04-01-${story.toLowerCase()}`, { seq: 1, phase: 1, phaseLabel: 'p', epic: '04-01', story, title: 't', status, blockedBy: '', note: '', updated: '2026-10-15', ...extra }]
  const items = new Map([row('S4', 'Complete'), row('S5', 'In progress', { started: T0 }), row('S6', 'In progress')])
  const base = { root: '/w/opus-opus', name: '04-build-order.json', title: '04 Tools', state: 'tracked' as const }
  const times: Times = { ...finished([30, 30, 35, 40, 40, 40, 45, 50, 50, 60]), '04-01 S5': { status: 'In Progress', effort: 'medium', started: T0 } }
  const before = indexEntry(base, new Map([row('S4', 'Complete'), row('S5', 'In progress'), row('S6', 'In progress')]), '2026-10-14', undefined)
  const entry = indexEntry(base, items, '2026-10-15', before, times)

  expect(entry.timings).toEqual([{ story: '04-01 S5', started: T0, typical: '36–49 min' }])
  expect(entry.changed).toBe('2026-10-14')
  expect(overviewRows([entry]).get('opus-opus--04')?.timings).toEqual(entry.timings)
  expect(overviewRows([{ ...entry, state: 'gone' }]).get('opus-opus--04')?.timings).toBeUndefined()
  expect(indexEntry(base, new Map([row('S6', 'In progress')]), '2026-10-15', undefined).timings).toBeUndefined()
})

test('an overview row whose timings come back with their keys reordered needs no write', () => {
  const entry = { root: '/w/opus-opus', name: '04-build-order.json', title: '04', state: 'tracked' as const, done: 13, total: 19, active: ['04-04 S1'], waiting: 0, changed: '2026-10-15', checked: '', timings: [{ story: '04-04 S1', started: T0, typical: '' }] }
  const rows = overviewRows([entry])
  const stored = JSON.parse(JSON.stringify(rows.get('opus-opus--04'))) as Record<string, unknown>
  stored.timings = [{ started: T0, story: '04-04 S1', typical: '' }]

  expect(overviewWrites(rows, [{ id: 'opus-opus--04', version: 28, data: stored }])).toEqual([])
})

const FILE = '04-01-epic-the-workspace-core.md'

test('a start records the family of its epic doc\'s last writer, lowercase, and an unrecognised id whole', () => {
  const cases: [string, string][] = [
    ['claude-opus-5-5', 'opus'], ['claude-sonnet-5-5', 'sonnet'], ['claude-haiku-5-5', 'haiku'], ['claude-fable-5-2', 'fable'], ['gpt-x-1', 'gpt-x-1'],
  ]
  for (const [id, family] of cases) {
    const times = recordTimes(recordTimes({}, seen('Pending', T0)), seen('In Progress', T0 + MIN), { [FILE]: id })
    expect(times['04-01 S5']).toEqual({ status: 'In Progress', effort: 'medium', started: T0 + MIN, model: family })
  }
  expect(seen('Pending', T0)[0]?.file).toBe(FILE)
})

test('a start in a file with no writer of its own records no model', () => {
  const before = recordTimes({}, seen('Pending', T0))
  const onlyOther = recordTimes(before, seen('In Progress', T0 + MIN), { '04-02-epic-other.md': 'claude-opus-5-5' })
  const none = recordTimes(before, seen('In Progress', T0 + MIN))
  expect(onlyOther['04-01 S5']).toEqual({ status: 'In Progress', effort: 'medium', started: T0 + MIN })
  expect(none['04-01 S5']).toEqual({ status: 'In Progress', effort: 'medium', started: T0 + MIN })

  // Control: the same fixtures with a writer for this file record its model.
  const withOwn = recordTimes(before, seen('In Progress', T0 + MIN), { '04-02-epic-other.md': 'claude-opus-5-5', [FILE]: 'claude-haiku-5-5' })
  expect(withOwn['04-01 S5']?.model).toBe('haiku')
})

test('a reopened story keeps its first start and its first model', () => {
  let times = recordTimes(recordTimes({}, seen('Pending', T0)), seen('In Progress', T0 + MIN), { [FILE]: 'claude-opus-5-5' })
  times = recordTimes(times, seen('Complete', T0 + 10 * MIN), { [FILE]: 'claude-opus-5-5' })
  times = recordTimes(times, seen('In Progress', T0 + 12 * MIN), { [FILE]: 'claude-sonnet-5-5' })

  expect(times['04-01 S5']).toEqual({ status: 'In Progress', effort: 'medium', started: T0 + MIN, model: 'opus' })
})

test('a step records the model that answered it, keeps the loop\'s model on a null usage, and drops its own errors', () => {
  const asked = recordStep(new Map(), 'a1', { usage: { model: 'claude-haiku-5-5' } })
  expect(modelOf(asked, 'a1')).toBe('claude-haiku-5-5')
  expect(modelOf(asked, undefined)).toBeUndefined()
  expect(modelOf(recordStep(asked, 'a1', { usage: null }), 'a1')).toBe('claude-haiku-5-5')
  expect(modelOf(recordStep(asked, 'a1', { usage: { model: 'claude-opus-5-5' } }), 'a1')).toBe('claude-opus-5-5')
  expect(modelOf(recordStep(new Map(), undefined, { usage: { model: 'claude-opus-5-5' } }), undefined)).toBe('claude-opus-5-5')

  const throwing = { get usage(): { model: string } { throw new Error('no usage') } }
  expect(recordStep(asked, 'a1', throwing)).toBe(asked)
})

test('a subagent\'s loop is forgotten and the main loop\'s is kept', () => {
  const map = recordStep(recordStep(new Map(), undefined, { usage: { model: 'claude-opus-5-5' } }), 'a1', { usage: { model: 'claude-haiku-5-5' } })
  const after = forgetLoop(map, 'a1')
  expect(modelOf(after, 'a1')).toBeUndefined()
  expect(modelOf(after, undefined)).toBe('claude-opus-5-5')
  expect(forgetLoop(after, undefined)).toBe(after)
})

test('the epic docs a tool call writes, by file name', () => {
  expect(writtenEpics('Edit', { file_path: '/w/docs/epics/01-01-epic-first.md' })).toEqual(['01-01-epic-first.md'])
  expect(writtenEpics('Write', { file_path: '/w/docs/epics/01-01-epic-first.md' })).toEqual(['01-01-epic-first.md'])
  expect(writtenEpics('MultiEdit', { file_path: '/w/docs/epics/01-01-epic-first.md' })).toEqual(['01-01-epic-first.md'])
  expect(writtenEpics('Bash', { command: "sed -i '' s/a/b/ docs/epics/01-01-epic-first.md docs/epics/01-02-epic-second.md" })).toEqual(['01-01-epic-first.md', '01-02-epic-second.md'])
  expect(writtenEpics('Edit', { file_path: '/w/src/app.ts' })).toEqual([])
  expect(writtenEpics('Bash', { command: 'git status' })).toEqual([])
  expect(writtenEpics('Read', { file_path: '/w/docs/epics/01-01-epic-first.md' })).toEqual([])
  expect(writtenEpics('NotebookEdit', { file_path: '/w/docs/epics/01-01-epic-first.md' })).toEqual([])
})

test('the meta carries how many stories are timed, and each steady effort\'s range and unrounded bounds', () => {
  const steady = finished([30, 30, 35, 40, 40, 40, 45, 50, 50, 61])
  const running: Times = { '04-01 S5': { status: 'In Progress', effort: 'medium', started: T0 }, '04-01 S6': { status: 'In Progress', effort: 'high', started: T0 } }
  const { timed, typical } = typicalRanges({ ...steady, ...running })
  const medium = estimate(durations(steady, 'medium'))
  const all = estimate(durations(steady))
  expect(timed).toBe(10)
  expect(medium !== undefined && all !== undefined).toBe(true)
  expect(typical.medium).toEqual({ range: range(medium!), low: medium!.low, high: medium!.high })
  expect(Number.isInteger(typical.medium?.high)).toBe(false)
  for (const effort of ['low', 'high', 'xhigh']) expect(typical[effort]).toEqual({ range: range(all!), low: all!.low, high: all!.high })

  expect(typicalRanges(finished([30, 30, 35, 40, 40, 40, 45, 50, 50]))).toEqual({ timed: 9, typical: {} })
  const spread = typicalRanges(finished([5, 5, 5, 6, 6, 60, 70, 80, 90, 100]))
  expect(spread.timed).toBe(10)
  expect('medium' in spread.typical).toBe(false)
})

test('an index entry takes each in-progress story\'s range from the times, for In progress rows only', () => {
  const row = (story: string, status: TrackerItem['status'], extra: Partial<TrackerItem> = {}): [string, TrackerItem] =>
    [`04-01-${story.toLowerCase()}`, { seq: 1, phase: 1, phaseLabel: 'p', epic: '04-01', story, title: 't', status, blockedBy: '', note: '', updated: '2026-10-15', ...extra }]
  const times: Times = { ...finished([30, 30, 35, 40, 40, 40, 45, 50, 50, 60]), '04-01 S5': { status: 'In Progress', effort: 'medium', started: T0 }, '04-01 S7': { status: 'In Progress', effort: 'medium', started: T0 } }
  const base = { root: '/w/opus-opus', name: '04-build-order.json', title: '04 Tools', state: 'tracked' as const }
  const entry = indexEntry(base, new Map([row('S5', 'In progress', { started: T0 }), row('S7', 'Waiting on input', { started: T0 })]), '2026-10-15', undefined, times)
  expect(entry.timings).toEqual([{ story: '04-01 S5', started: T0, typical: '36–49 min' }])
  expect(overviewRows([entry]).get('opus-opus--04')?.timings).toEqual([{ story: '04-01 S5', started: T0, typical: '36–49 min' }])
})

test('the report names the model of a timed story in progress, and leaves it out when none was recorded', () => {
  const times: Times = {
    ...finished([30, 30, 35, 40, 40, 40, 45, 50, 50, 60]),
    '04-01 S5': { status: 'In Progress', effort: 'medium', started: T0, model: 'sonnet' },
    '04-01 S6': { status: 'In Progress', effort: 'high', started: T0 },
  }
  const report = timesReport('opus-opus', times, T0 + 20 * MIN)
  expect(report).toMatch(/04-01 S5 \(medium, sonnet\): 20 min in/)
  expect(report).toMatch(/04-01 S6 \(high\): 20 min in;/)
})
