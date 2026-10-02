import { describe, expect, test } from 'claude-code/testing'

import { buildPlan, describePlan, hasWork, normaliseStatus, parseBlockers, unplannedSpecs } from './plan'

const MEMBER_RULES = `# Member Rules and Organisation Logo

**Source spec**: docs/specifications/01-spec-x.md
**Status**: Pending
**Blocked by**: —

## Safeguarding Officer must have an email address
**Story**: 1
**Status**: Pending
**Blocked by**: —

### Conditional required email
**Task**: 1.1
**Status**: Complete

### Approval rule
**Task**: 1.2
**Status**: Pending

---

## At least two different people hold the mandatory roles
**Story**: 2
**Status**: Pending
**Blocked by**: Story 1

### Person key
**Task**: 2.1
**Status**: Pending

## Optional organisation logo
**Story**: 3
**Status**: Pending
**Blocked by**: —
`

const EMAILS = `# Staff Decision Emails

**Status**: Pending
**Blocked by**: Epic 01-01-epic-member-rules

## Send the decision email
**Story**: 1
**Status**: Pending
**Blocked by**: —
`

const DONE = `# Setup

**Status**: complete — shipped
**Blocked by**: —

## Scaffold
**Story**: 1
**Status**: Done
**Blocked by**: —
`

const files = [
  { name: '01-02-epic-staff-emails.md', text: EMAILS, isArchived: false },
  { name: '01-01-epic-member-rules.md', text: MEMBER_RULES, isArchived: false },
  { name: '00-01-epic-setup.md', text: DONE, isArchived: false },
]

describe('reading fields', () => {
  test('status is read tolerantly', () => {
    expect(normaliseStatus('complete — Ships on its own')).toBe('Complete')
    expect(normaliseStatus('Done')).toBe('Complete')
    expect(normaliseStatus('In Progress')).toBe('In Progress')
    expect(normaliseStatus('Superseded')).toBe('Superseded')
    expect(normaliseStatus('')).toBe('Pending')
  })

  test('blockers split, dashes mean none', () => {
    expect(parseBlockers('—')).toEqual([])
    expect(parseBlockers('Story 1, Epic 02-epic-ui')).toEqual(['Story 1', 'Epic 02-epic-ui'])
  })
})

describe('ordering', () => {
  const plan = buildPlan('/repos/hlh-approved-groups', files, 'sig')

  test('complete epics drop out and the repo is named', () => {
    expect(plan.repo).toBe('hlh-approved-groups')
    expect(plan.epics.map(e => e.id)).toEqual(['01-01-epic-member-rules', '01-02-epic-staff-emails'])
  })

  test('started story first, dependants follow, cross-epic work last', () => {
    expect(plan.order.map(s => `${s.epicId.slice(0, 5)} ${s.number}`)).toEqual(['01-01 1', '01-01 2', '01-01 3', '01-02 1'])
    const [first, second, , emails] = plan.order
    expect(first?.status).toBe('In Progress')
    expect(first?.nextTask?.id).toBe('1.2')
    expect(first?.tasksDone).toBe(1)
    expect(second?.isReady).toBe(false)
    expect(second?.waitsOn).toEqual(['Story 1'])
    expect(emails?.waitsOn).toEqual(['Epic 01-01-epic-member-rules'])
  })

  test('an unknown dependency leaves the story at the end, still listed', () => {
    const stuck = buildPlan('/r', [{ name: '03-01-epic-x.md', isArchived: false, text: EMAILS.replace('Epic 01-01-epic-member-rules', 'Epic 99-01-epic-gone') }], 's')
    expect(stuck.order).toHaveLength(1)
    expect(stuck.order[0]?.isReady).toBe(false)
  })

  test('an archived complete epic satisfies a dependency', () => {
    const archived = buildPlan('/r', [
      { name: '01-02-epic-staff-emails.md', text: EMAILS, isArchived: false },
      { name: '01-01-epic-member-rules.md', text: DONE, isArchived: true },
    ], 's')
    expect(archived.order[0]?.isReady).toBe(true)
  })

  test('a dependency named by both the epic and the story is listed once', () => {
    const repeated = EMAILS.replace('**Blocked by**: —\n', '**Blocked by**: Epic 01-01-epic-member-rules\n')
    const both = buildPlan('/r', [{ name: '01-02-epic-staff-emails.md', text: repeated, isArchived: false }], 's')
    expect(both.order[0]?.waitsOn).toEqual(['Epic 01-01-epic-member-rules'])
  })

  test('the text summary lists the order', () => {
    expect(describePlan(plan)).toContain('1. 01-01-epic-member-rules Story 1')
  })
})

describe('specs without epics', () => {
  const spec = (name: string, extra = '') => ({ name, text: `# Spec: Title of ${name}\n\n**Date**: 2026-10-01\n${extra}` })
  const epic = (name: string, source = '') => ({ name, text: `# Epic\n\n**Source spec**: ${source}\n**Status**: Pending\n`, isArchived: false })

  test('a spec is planned when an epic is numbered after it', () => {
    expect(unplannedSpecs([spec('03-spec-a.md')], [epic('03-01-epic-x.md')])).toEqual([])
  })

  test('a spec is planned when a legacy epic names it as its source', () => {
    expect(unplannedSpecs([spec('01-spec-a.md')], [epic('02-epic-x.md', 'docs/specifications/01-spec-a.md')])).toEqual([])
  })

  test('a legacy flat epic number is not a spec number', () => {
    expect(unplannedSpecs([spec('01-spec-a.md')], [epic('01-epic-x.md', 'docs/specifications/09-spec-z.md')]).map(s => s.id)).toEqual(['01-spec-a'])
  })

  test('unplanned specs are listed in number order with their titles', () => {
    expect(unplannedSpecs([spec('10-spec-b.md'), spec('04-spec-a.md'), spec('05-spec-c.md')], [epic('05-01-epic-x.md')])).toEqual([
      { id: '04-spec-a', title: 'Title of 04-spec-a.md', path: 'docs/specifications/04-spec-a.md' },
      { id: '10-spec-b', title: 'Title of 10-spec-b.md', path: 'docs/specifications/10-spec-b.md' },
    ])
  })

  test('a spec whose own status is complete is left out', () => {
    expect(unplannedSpecs([spec('01-spec-a.md', '**Status**: complete — Stage 0\n')], [])).toEqual([])
  })

  test('specs alone count as work and appear in the summary', () => {
    const only = buildPlan('/r', [], 's', [spec('02-spec-a.md')])
    expect(hasWork(only)).toBe(true)
    expect(describePlan(only)).toContain('- docs/specifications/02-spec-a.md: Title of 02-spec-a.md')
  })
})

describe('withdrawal notices and titles', () => {
  test('a spec with a Withdrawn or Superseded by field, or WITHDRAWN in its title, is left out', () => {
    const notices = [
      { name: '16-spec-a.md', text: '# Spec 16: A — WITHDRAWN\n\n**Withdrawn**: 2026-08-23\n' },
      { name: '17-spec-b.md', text: '# Spec: B\n\n**Superseded by**: 18-spec-c.md\n' },
      { name: '19-spec-d.md', text: '# Spec: D — SUPERSEDED\n' },
    ]
    expect(unplannedSpecs(notices, [])).toEqual([])
  })

  test('the "Spec 16:" prefix is dropped from the title', () => {
    expect(unplannedSpecs([{ name: '16-spec-a.md', text: '# Spec 16: Voucher Sales in Analytics\n' }], [])[0]?.title).toBe('Voucher Sales in Analytics')
  })
})

describe('started epics', () => {
  test('stories of an epic marked In Progress come before a lower-numbered untouched epic', () => {
    const untouched = '# Deferred\n\n**Status**: Pending\n**Blocked by**: —\n\n## A\n**Story**: 1\n**Status**: Pending\n**Blocked by**: —\n'
    const started = '# Current\n\n**Status**: In Progress\n**Blocked by**: —\n\n## B\n**Story**: 4\n**Status**: Pending\n**Blocked by**: —\n'
    const plan = buildPlan('/r', [
      { name: '13-04-epic-deferred.md', text: untouched, isArchived: false },
      { name: '35-01-epic-current.md', text: started, isArchived: false },
    ], 's')
    expect(plan.order.map(s => `${s.epicId.slice(0, 5)} ${s.number}`)).toEqual(['35-01 4', '13-04 1'])
  })
})

test('an epic with only completed stories done is not treated as under way', () => {
  const paused = '# Paused\n\n**Status**: Pending\n**Blocked by**: —\n\n## Done\n**Story**: 1\n**Status**: Complete\n**Blocked by**: —\n\n## Next\n**Story**: 2\n**Status**: Pending\n**Blocked by**: —\n'
  const current = '# Current\n\n**Status**: In Progress\n**Blocked by**: —\n\n## B\n**Story**: 4\n**Status**: Pending\n**Blocked by**: —\n'
  const plan = buildPlan('/r', [
    { name: '13-04-epic-paused.md', text: paused, isArchived: false },
    { name: '35-01-epic-current.md', text: current, isArchived: false },
  ], 's')
  expect(plan.order.map(s => `${s.epicId.slice(0, 5)} ${s.number}`)).toEqual(['35-01 4', '13-04 2'])
})
