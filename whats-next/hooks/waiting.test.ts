import { expect, test } from 'claude-code/testing'

import { ARCHIVED, EPICS, EXPECTED } from './fixtures/waiting'
import { afterLabel, buildPlan, describePlan, hasWork, isWaitingOnUser, parseEpic, splitTag, summaryOf, waitingBand } from './plan'
import type { EpicFile } from './plan'

const files = (only?: string[]): EpicFile[] => EPICS
  .filter(e => only === undefined || only.includes(e.name))
  .map(e => ({ name: e.name, text: e.text, isArchived: ARCHIVED.includes(e.name) }))

const isComplete = (key: string) => {
  const [epic, story] = key.split('#') as [string, string]
  const file = EPICS.find(e => e.name.startsWith(`${epic}-`))

  return file !== undefined && parseEpic({ name: file.name, text: file.text, isArchived: false }).stories.find(s => s.number === Number(story))?.status === 'Complete'
}

const live = Object.entries(EXPECTED).filter(([key]) => !ARCHIVED.some(a => a.startsWith(key.split('#')[0] as string)))
const prefix = (epicId: string) => epicId.split('-epic-')[0] as string
const inWaiting = (plan: ReturnType<typeof buildPlan>, key: string) => plan.waiting.some(w => `${prefix(w.epicId)}#${w.number}` === key)
const inOrder = (plan: ReturnType<typeof buildPlan>, key: string) => plan.order.some(s => `${prefix(s.epicId)}#${s.number}` === key)

test('every live fixture story is listed as waiting exactly when the contract says it waits, and never in the order', () => {
  const plan = buildPlan('/r', files(), 'sig')
  expect(live.length).toBeGreaterThan(10)
  for (const [key, waits] of live) {
    expect([key, inWaiting(plan, key)]).toEqual([key, waits])
    // A story that waits is not work to build; one that does not is still left, unless it is Complete.
    if (waits) expect([key, inOrder(plan, key)]).toEqual([key, false])
    else expect([key, inOrder(plan, key)]).toEqual([key, !isComplete(key)])
  }
  expect(inOrder(plan, '21-01#1')).toBe(true)
  expect(inOrder(plan, '23-01#2')).toBe(false)
})

test('a waiting story lists the text of each criterion still unproven', () => {
  const plan = buildPlan('/r', files(), 'sig')
  const w = plan.waiting.find(s => prefix(s.epicId) === '20-01' && s.number === 1)
  expect(w?.checks).toEqual(['The user confirms the release'])
  expect(plan.waiting.find(s => prefix(s.epicId) === '26-01' && s.number === 2)?.checks).toEqual(['The page renders'])
})

test('a story that depends on a waiting story is not ready and is labelled as waiting on that check', () => {
  const plan = buildPlan('/r', files(), 'sig')
  const dependent = plan.order.find(s => prefix(s.epicId) === '28-01' && s.number === 2)
  expect(dependent?.isReady).toBe(false)
  expect(dependent?.waitsOnChecks).toEqual(['Story 1'])
  // The controls: a story blocked by a story or an epic that does not hold a check is not labelled so.
  expect(plan.order.find(s => prefix(s.epicId) === '21-01' && s.number === 2)?.waitsOnChecks).toEqual([])
  expect(plan.order.find(s => prefix(s.epicId) === '22-01' && s.number === 1)?.waitsOnChecks).toEqual([])
})

test('when only waiting stories are left there is still work to show', () => {
  const plan = buildPlan('/r', files(['20-01-epic-waiting.md']), 'sig')
  expect(plan.order).toEqual([])
  expect(plan.waiting).toHaveLength(2)
  expect(hasWork(plan)).toBe(true)
  const text = describePlan(plan)
  expect(text).toContain('no stories left to build')
  expect(text).toContain('Waiting on you (2)')
  expect(text).toContain('The user confirms the release')
})

test('with nothing waiting and nothing left, there is no work', () => {
  const plan = buildPlan('/r', files(['09-01-epic-old.md']), 'sig')
  expect(hasWork(plan)).toBe(false)
  expect(describePlan(plan)).toContain('no cpm-next stories left')
})

test('a blocker epic that is Complete only in the archive counts as Complete; without it the story is blocked', () => {
  expect(inWaiting(buildPlan('/r', files(), 'sig'), '23-01#1')).toBe(true)
  const without = buildPlan('/r', files(['23-01-epic-archived-blocker.md']), 'sig')
  expect(inWaiting(without, '23-01#1')).toBe(false)
  expect(inOrder(without, '23-01#1')).toBe(true)
})

test('the stories the user waits on are not counted among the stories left', () => {
  const plan = buildPlan('/r', files(['20-01-epic-waiting.md', '21-01-epic-blocker-story.md']), 'sig')
  expect(plan.waiting).toHaveLength(2)
  expect(plan.order).toHaveLength(2)
  expect(describePlan(plan)).toContain('2 stories left across 1 epics')
})

test('the tag is the last backticked word, split from the criterion text', () => {
  expect(splitTag('does `thing` `[Unit]`')).toEqual({ text: 'does `thing`', tag: 'unit' })
  expect(splitTag('mentions `[user]` then `code`')).toEqual({ text: 'mentions `[user]` then `code`', tag: '' })
})

test('a story with no criteria does not wait', () => {
  const epic = parseEpic({ name: '01-01-epic-x.md', text: '# X\n\n## S\n**Story**: 1\n**Status**: Pending\n', isArchived: false })
  expect(isWaitingOnUser(epic.stories[0] as never)).toBe(false)
})

/** An epic of three stories: 1 waits on the user, 3 is ordinary work, 2 depends on both. */
const MIXED = [{
  name: '30-01-epic-mixed.md',
  isArchived: false,
  text: [
    '# Mixed', '', '**Status**: Pending', '**Blocked by**: —', '',
    '## One', '**Story**: 1', '**Status**: Pending', '**Blocked by**: —', '', '**Acceptance Criteria**:', '', '- The user confirms `[user]`', '',
    '## Two', '**Story**: 2', '**Status**: Pending', '**Blocked by**: Story 1, Story 3', '', '**Acceptance Criteria**:', '', '- It works `[unit]`', '',
    '## Three', '**Story**: 3', '**Status**: Pending', '**Blocked by**: —', '', '**Acceptance Criteria**:', '', '- It builds `[unit]`', '',
  ].join('\n'),
}, {
  name: '31-01-epic-after-mixed.md',
  isArchived: false,
  text: ['# After', '', '**Status**: Pending', '**Blocked by**: Epic 30-01-epic-mixed', '', '## Four', '**Story**: 1', '**Status**: Pending', '**Blocked by**: —', '', '**Acceptance Criteria**:', '', '- It works `[unit]`', ''].join('\n'),
}]

test('a story with several dependencies shows all of them, marking only the user checks', () => {
  const plan = buildPlan('/r', MIXED, 'sig')
  const two = plan.order.find(s => s.number === 2 && prefix(s.epicId) === '30-01')
  expect(two?.waitsOn).toEqual(['Story 1', 'Story 3'])
  expect(two?.waitsOnChecks).toEqual(['Story 1'])
  expect(afterLabel(two?.waitsOn ?? [], two?.waitsOnChecks)).toBe('after S1 (your check), S3')
  expect(describePlan(plan)).toContain('waits on Story 1 (your check), Story 3')
})

test('an epic that still has work to build is not a check, even when it also holds a waiting story', () => {
  const plan = buildPlan('/r', MIXED, 'sig')
  const four = plan.order.find(s => prefix(s.epicId) === '31-01')
  expect(four?.waitsOn).toEqual(['Epic 30-01-epic-mixed'])
  expect(four?.waitsOnChecks).toEqual([])
})

test('an epic whose only stories left are checks is one', () => {
  const waitingOnly = [MIXED[0] as EpicFile, MIXED[1] as EpicFile].map(f => ({ ...f }))
  const text = (waitingOnly[0] as EpicFile).text.replace(/## Two[\s\S]*$/, '')
  const plan = buildPlan('/r', [{ ...(waitingOnly[0] as EpicFile), text }, waitingOnly[1] as EpicFile], 'sig')
  expect(plan.order.find(s => prefix(s.epicId) === '31-01')?.waitsOnChecks).toEqual(['Epic 30-01-epic-mixed'])
})

test('the band names the first waiting story only when nothing is left to build', () => {
  const only = buildPlan('/r', files(['20-01-epic-waiting.md']), 'sig')
  expect(waitingBand(only)).toEqual({ label: '20-01 S1', title: 'Story 1', count: 2 })
  expect(waitingBand(buildPlan('/r', files(), 'sig'))).toBeUndefined()
  expect(waitingBand(buildPlan('/r', files(['09-01-epic-old.md']), 'sig'))).toBeUndefined()
})

test('the pane summary counts stories to build, the epics they are in, and the stories waiting on the user', () => {
  const plan = buildPlan('/r', files(['20-01-epic-waiting.md', '21-01-epic-blocker-story.md']), 'sig')
  expect(summaryOf(plan)).toBe('2 stories · 1 epic left · 2 waiting on you')
  expect(summaryOf(buildPlan('/r', files(['20-01-epic-waiting.md']), 'sig'))).toBe('2 waiting on you')
})
