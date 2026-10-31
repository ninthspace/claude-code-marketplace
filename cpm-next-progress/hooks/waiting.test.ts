import { expect, test } from 'claude-code/testing'

import { ARCHIVED, EPICS, EXPECTED } from './fixtures/waiting'
import type { BuildOrder, EpicFile } from './progress'
import { buildItems, criterionTag, indexEntry, isWaitingOnUser, parseEpic } from './progress'

const TODAY = '2026-10-31'
const short = (name: string) => name.split('-epic-')[0] as string
const files = (): EpicFile[] => EPICS.map(e => ({ name: e.name, text: e.text, ...(ARCHIVED.includes(e.name) ? { archived: true } : {}) }))
const live = () => files().filter(f => f.archived !== true)

/** A build order listing every story of every live fixture epic, so each gets a row. */
const everyStory = (): BuildOrder => ({
  title: 'fixtures',
  phases: [{ label: 'all', items: live().flatMap(f => parseEpic(f).stories.map(s => ({ epic: short(f.name), story: s.number }))) }],
})

const statusOf = (items: ReturnType<typeof buildItems>['items'], key: string) => items.get(`${key.replace('#', '-s')}`)?.status

test('every fixture story is Waiting on input exactly when the contract says it waits', () => {
  const { items, missing } = buildItems(everyStory(), files(), TODAY)
  expect(missing).toEqual([])
  const live = Object.entries(EXPECTED).filter(([key]) => !ARCHIVED.some(a => a.startsWith(key.split('#')[0] as string)))
  expect(live.length).toBeGreaterThan(10)
  for (const [key, waits] of live) {
    expect([key, statusOf(items, key) === 'Waiting on input']).toEqual([key, waits])
  }
})

test('a waiting story shows as Waiting on input whether it is Pending or In Progress', () => {
  const { items } = buildItems(everyStory(), files(), TODAY)
  expect(statusOf(items, '20-01#1')).toBe('Waiting on input')
  expect(statusOf(items, '20-01#2')).toBe('Waiting on input')
})

test('a story that is not waiting keeps its own status', () => {
  const { items } = buildItems(everyStory(), files(), TODAY)
  expect(statusOf(items, '21-01#1')).toBe('Pending')
  expect(statusOf(items, '23-01#2')).toBe('Complete')
})

test('a blocker epic that is Complete only in the archive counts as Complete; without it the story is blocked', () => {
  const withArchive = buildItems(everyStory(), files(), TODAY).items
  expect(statusOf(withArchive, '23-01#1')).toBe('Waiting on input')
  expect(withArchive.get('23-01-s1')?.blockedBy).toBe('')

  const without = buildItems(everyStory(), files().filter(f => !ARCHIVED.includes(f.name)), TODAY).items
  expect(statusOf(without, '23-01#1')).toBe('Pending')
  expect(without.get('23-01-s1')?.blockedBy).toBe('Epic 09-01-epic-old')
})

test('the overview counts the stories waiting on the user', () => {
  const { items } = buildItems(everyStory(), files(), TODAY)
  const entry = indexEntry({ root: '/r', name: '20-build-order.json', title: 't', state: 'live' } as never, items, TODAY, undefined)
  const waits = Object.entries(EXPECTED).filter(([key, w]) => w && !ARCHIVED.some(a => a.startsWith(key.split('#')[0] as string))).length
  expect(entry.waiting).toBe(waits)
})

test('criteria are read as the contract describes: tag, evidence, not met, waiting line, continuation lines', () => {
  const epic = parseEpic({
    name: '01-01-epic-x.md',
    text: [
      '# X', '', '**Status**: Pending', '',
      '## S', '**Story**: 1', '**Status**: Pending — blocked: the tests fail', '**Blocked by**: —', '',
      '**Acceptance Criteria**:', '',
      '- first `code` text',
      '  continued on a second line `[user]`',
      '  - Evidence: shown',
      '- second `[browser]`',
      '  - Not met: tried',
      '  - Waiting on user: start the app',
      '',
      '### Task', '**Task**: 1.1', '**Status**: Complete',
    ].join('\n'),
  })
  const story = epic.stories[0]
  expect(story?.isBlockedNote).toBe(true)
  expect(story?.criteria).toEqual([
    { tag: 'user', hasEvidence: true, hasNotMet: false, hasWaitingLine: false },
    { tag: 'browser', hasEvidence: false, hasNotMet: true, hasWaitingLine: true },
  ])
  expect(story?.tasks).toEqual([{ id: '1.1', title: 'Task', status: 'Complete' }])
})

test('the tag is the last backticked word, and only a bracketed one', () => {
  expect(criterionTag('does `thing` `[Unit]`')).toBe('unit')
  expect(criterionTag('mentions `[user]` then `code`')).toBe('')
  expect(criterionTag('no tag')).toBe('')
})

test('a story with no criteria does not wait', () => {
  const epic = parseEpic({ name: '01-01-epic-x.md', text: '# X\n\n## S\n**Story**: 1\n**Status**: Pending\n' })
  expect(isWaitingOnUser(epic.stories[0] as never)).toBe(false)
})
