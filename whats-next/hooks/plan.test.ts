import { describe, expect, test } from 'claude-code/testing'

import { buildPlan, describePlan, normaliseStatus, parseBlockers } from './plan'

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
