import type { EngineInterface } from 'claude-code'

import type { IndexEntry } from './progress'
import { bar, overviewGroups, overviewNote } from './progress'

/** The pane `/progress-tracker all` opens. */
export const OVERVIEW = 'progress-overview'

const BAR = 12

/**
 * Every indexed tracker, one row each under its project: number and title, a bar, done of total, and
 * what is in flight. Takes the surface's elements rather than `$`, which may not cross an import.
 */
export function renderOverview({ Box, Text }: Pick<ReturnType<EngineInterface['ui']['resolve']>, 'Box' | 'Text'>, columns: number, entries: IndexEntry[]) {
  const titleWidth = Math.max(12, Math.min(40, columns - BAR - 30))
  const groups = overviewGroups(entries)

  return (
    <Box flexDirection="column">
      {groups.length === 0 && <Text dimColor>No trackers indexed yet. Run /progress-tracker in a project to add its trackers.</Text>}
      {groups.map(group => (
        <Box flexDirection="column" marginBottom={1}>
          <Text bold>{group.repo}</Text>
          {group.entries.map(entry => {
            const isDone = entry.state === 'gone' || (entry.total > 0 && entry.done === entry.total)
            const title = entry.title.length > titleWidth ? `${entry.title.slice(0, titleWidth - 1)}…` : entry.title.padEnd(titleWidth)

            return (
              <Text dimColor={isDone} wrap="truncate-end">
                {`  ${title}  ${bar(entry.done, entry.total, BAR)} ${`${entry.done}/${entry.total}`.padStart(7)}  ${overviewNote(entry)}`}
              </Text>
            )
          })}
        </Box>
      ))}
    </Box>
  )
}
