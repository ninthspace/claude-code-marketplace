import type { EngineInterface } from 'claude-code'

import type { IndexEntry } from './progress'
import { bar, overviewGroups, overviewNote } from './progress'

/** The pane `/progress-tracker all` opens. */
export const OVERVIEW = 'progress-overview'

const BAR = 12

/** Every indexed tracker, one row each under its project: number and title, a bar, done of total, and what is in flight. */
export function renderOverview($: EngineInterface, e: { surface: string; viewport?: { columns: number } }, entries: IndexEntry[]) {
  const { Box, Text } = $.ui.resolve(e as Parameters<EngineInterface['ui']['resolve']>[0])
  const columns = e.viewport?.columns ?? 80
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
