// The epic docs, build order, timings and planned model that fixtures/tracker-data.ts is built from.
// progress.test.ts checks that the rows and meta the mod builds from these equal that file, which the
// page harness renders; change both together.

import type { BuildOrder, EpicFile, TimeRecord } from '../progress'

const MIN = 60_000
const T0 = Date.UTC(2026, 10, 11, 9)

export const TODAY = '2026-11-11'
export const PLANNED = 'opus'

export const EPICS: EpicFile[] = [
  {
    name: '55-01-epic-rows-and-meta.md',
    text: `# Rows and meta

**Status**: In Progress
**Blocked by**: —

## The model each story was built on
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Effort**: high

**Acceptance Criteria**:

- the model is recorded \`[unit]\`
  - Evidence: a test — red: x

## Rows carry model, effort and needs
**Story**: 2
**Status**: In Progress
**Blocked by**: Story 1
**Model**: sonnet

**Acceptance Criteria**:

- the row has a model \`[unit]\`
  - Evidence: a test — red: x
- the row has an effort \`[unit]\`

## Decisions matched to rows
**Story**: 3
**Status**: Pending
**Blocked by**: Story 2

## Waiting on a review
**Story**: 4
**Status**: Pending
**Blocked by**: —
**Effort**: low

**Acceptance Criteria**:

- the user looks at it \`[user]\`

### Write the strip
**Task**: 4.1
**Status**: Pending
`,
  },
]

export const ORDER: BuildOrder = {
  title: '55 The tracker in split view: build order',
  spec: 'docs/specifications/55-spec-tracker-split-view.md',
  decisions: ['[55-01 S4, review] Walk through the detail at 390 px', 'Pick a release date'],
  phases: [
    { label: '55-01 Rows and meta', note: 'Data first', items: [{ epic: '55-01', story: 1 }, { epic: '55-01', story: 2 }, { epic: '55-01', story: 3 }, { epic: '55-01', story: 4 }, { epic: '55-01', task: '4.1', note: 'Shown in the strip' }] },
  ],
}

/** Ten finished medium stories elsewhere give a steady medium range; 55-01 S1 took 38 minutes and S2 is running. */
export const TIMES: Record<string, TimeRecord> = {
  ...Object.fromEntries(Array.from({ length: 10 }, (_, i) => [`54-01 S${i + 1}`, { status: 'Complete' as const, effort: 'medium', started: T0, finished: T0 + (20 + 3 * i) * MIN }])),
  '55-01 S1': { status: 'Complete', effort: 'high', started: T0, finished: T0 + 38 * MIN, model: 'opus' },
  '55-01 S2': { status: 'In Progress', effort: 'medium', started: T0 + 40 * MIN, model: 'sonnet' },
}
