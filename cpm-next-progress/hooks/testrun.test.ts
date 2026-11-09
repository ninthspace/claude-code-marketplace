import { expect, test } from 'claude-code/testing'

import { parseEpic } from './progress'

const story = (header: string) => `# Epic

**Source spec**: docs/specifications/01-spec-x.md  
**Date**: 2026-11-09  
**Status**: In Progress  
**Blocked by**: —  

## First
**Story**: 1  
**Status**: In Progress  
**Blocked by**: —  
**Satisfies**: FR1  
${header}
**Acceptance Criteria**:

- the first criterion \`[manual]\`
  - Evidence: read it — red: n/a — manual
- the second criterion \`[user]\`

### A task
**Task**: 1.1  
**Description**: d  
**Status**: Pending

---
`

const LINE = '**Test run**: 2 (1 full, 1 targeted) — targeted — npm test: 12 passed, 0 failed — tree abc123 — src/a.ts → tests/a.test.ts  \n'

test('a **Test run** header line changes nothing the tracker reads', () => {
  const without = parseEpic({ name: '01-01-epic-x.md', text: story('') })
  const withLine = parseEpic({ name: '01-01-epic-x.md', text: story(LINE) })
  expect(without.stories.length).toBe(1)
  expect(without.stories[0]?.criteria.length).toBe(2)
  expect(withLine).toEqual(without)
})

test('the same line as a `- ` bullet under the criteria heading would be a criterion, which is why it sits in the header block', () => {
  const misplaced = story('').replace('**Acceptance Criteria**:\n', `**Acceptance Criteria**:\n\n- ${LINE.trim()} \`[manual]\`\n`)
  const parsed = parseEpic({ name: '01-01-epic-x.md', text: misplaced })
  expect(parsed.stories[0]?.criteria.length).toBe(3)
})
