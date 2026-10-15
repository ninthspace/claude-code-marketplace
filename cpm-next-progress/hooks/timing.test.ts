import { expect, test } from 'claude-code/testing'

import { overviewNote } from './progress'
import type { Times } from './timing'
import { MIN_STORIES, activeNote, durations, estimate, estimateFor, observe, recordTimes, span, timesReport } from './timing'

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
  expect(seen('In Progress', T0)).toEqual([{ key: '04-01 S5', status: 'In Progress', effort: 'medium', at: T0 }])
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
