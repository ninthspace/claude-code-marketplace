// Epic docs and the verdict each mod's parser must give every story: waiting on the user (true) or not (false).
// whats-next and cpm-next-progress keep identical copies of this file; `cmp` them when either changes.
// Every epic has two stories, so a rule that reads the wrong story shows as a wrong verdict.

export type FixtureEpic = { name: string; text: string }

type Criterion = { text: string; tag?: string; evidence?: boolean; notMet?: boolean; waiting?: string }

const lines = (c: Criterion): string[] => [
  `- ${c.text}${c.tag === undefined ? '' : ` \`[${c.tag}]\``}`,
  ...(c.evidence === true ? ['  - Evidence: shown — red: n/a — manual'] : []),
  ...(c.notMet === true ? ['  - Not met: tried it'] : []),
  ...(c.waiting === undefined ? [] : [`  - Waiting on user: ${c.waiting}`]),
]

const story = (n: number, status: string, blockedBy: string, criteria: Criterion[], legacyEvidence = false): string => [
  `## Story ${n}`,
  `**Story**: ${n}  `,
  `**Status**: ${status}  `,
  `**Blocked by**: ${blockedBy}  `,
  ...(legacyEvidence ? ['**Evidence**: the user ran it on 2026-10-01  '] : []),
  '',
  '**Acceptance Criteria**:',
  '',
  ...criteria.flatMap(lines),
  '',
  `### Task ${n}`,
  `**Task**: ${n}.1  `,
  '**Description**: Do the work.  ',
  '**Status**: Pending',
  '',
  '---',
  '',
].join('\n')

const epic = (name: string, status: string, blockedBy: string, stories: string[]): FixtureEpic => ({
  name,
  text: [`# ${name.replace(/^\d+-\d+-epic-/, '').replace(/\.md$/, '')}`, '', `**Status**: ${status}  `, `**Blocked by**: ${blockedBy}`, '', ...stories].join('\n'),
})

const checkUser: Criterion = { text: 'The user confirms the release', tag: 'user' }
const unitDone: Criterion = { text: 'The parser reads the field', tag: 'unit', evidence: true }
const unitOpen: Criterion = { text: 'The parser reads the field', tag: 'unit' }

export const EPICS: FixtureEpic[] = [
  epic('09-01-epic-old.md', 'Complete', '—', [
    story(1, 'Complete', '—', [unitDone]),
    story(2, 'Complete', '—', [unitDone]),
  ]),
  // Waiting, in both statuses a story can carry before it closes.
  epic('20-01-epic-waiting.md', 'In Progress', '—', [
    story(1, 'Pending', '—', [unitDone, checkUser]),
    story(2, 'In Progress', '—', [unitDone, checkUser]),
  ]),
  // A story blocker that is not Complete leaves the dependent story not waiting.
  epic('21-01-epic-blocker-story.md', 'Pending', '—', [
    story(1, 'Pending', '—', [unitOpen]),
    story(2, 'Pending', 'Story 1', [checkUser]),
  ]),
  // An epic blocker that is not Complete leaves every story of the epic not waiting.
  epic('22-01-epic-blocker-epic.md', 'Pending', 'Epic 21-01-epic-blocker-story', [
    story(1, 'Pending', '—', [checkUser]),
    story(2, 'Pending', '—', [checkUser]),
  ]),
  // A blocker epic that is Complete only in the archive counts as Complete.
  epic('23-01-epic-archived-blocker.md', 'Pending', 'Epic 09-01-epic-old', [
    story(1, 'Pending', '—', [checkUser]),
    story(2, 'Complete', '—', [unitDone]),
  ]),
  // A blocked note, and a Not met line, take a story out of waiting; the sibling story still waits.
  epic('24-01-epic-blocked-note.md', 'Pending', '—', [
    story(1, 'Pending — blocked: the tests fail', '—', [checkUser]),
    story(2, 'Pending', '—', [checkUser]),
  ]),
  epic('25-01-epic-not-met.md', 'Pending', '—', [
    story(1, 'Pending', '—', [{ ...checkUser, notMet: true }]),
    story(2, 'Pending', '—', [checkUser]),
  ]),
  // An untagged criterion without Evidence keeps the story from waiting; a `Waiting on user` line stands in for the tag.
  epic('26-01-epic-untagged.md', 'Pending', '—', [
    story(1, 'Pending', '—', [checkUser, { text: 'The settings page lists the option' }]),
    story(2, 'Pending', '—', [unitDone, { text: 'The page renders', tag: 'browser', waiting: 'start the app and open /settings' }]),
  ]),
  // Every criterion evidenced, or the legacy story-level field present: nothing waits.
  epic('27-01-epic-evidenced.md', 'Pending', '—', [
    story(1, 'Pending', '—', [unitDone, { ...checkUser, evidence: true }]),
    story(2, 'Pending', '—', [checkUser], true),
  ]),
  // A story that depends on a waiting story is not waiting itself, and is not ready.
  epic('28-01-epic-dependent.md', 'Pending', '—', [
    story(1, 'Pending', '—', [checkUser]),
    story(2, 'Pending', 'Story 1', [unitOpen]),
  ]),
]

/** The epic that is Complete only in `docs/archive/epics`. */
export const ARCHIVED = ['09-01-epic-old.md']

/** `{epic prefix}#{story}` → whether the story is waiting on the user. */
export const EXPECTED: Record<string, boolean> = {
  '09-01#1': false,
  '09-01#2': false,
  '20-01#1': true,
  '20-01#2': true,
  '21-01#1': false,
  '21-01#2': false,
  '22-01#1': false,
  '22-01#2': false,
  '23-01#1': true,
  '23-01#2': false,
  '24-01#1': false,
  '24-01#2': true,
  '25-01#1': false,
  '25-01#2': true,
  '26-01#1': false,
  '26-01#2': true,
  '27-01#1': false,
  '27-01#2': false,
  '28-01#1': true,
  '28-01#2': false,
}
