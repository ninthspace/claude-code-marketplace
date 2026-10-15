import type { EngineInterface } from 'claude-code'

import type { IndexEntry } from './progress'
import { bar, overviewGroups, overviewNote } from './progress'

/** The pane `/progress-tracker all` opens. */
export const OVERVIEW = 'progress-overview'

const BAR = 12
/** Below this many columns a row splits: the title on a line of its own, the bar and note under it. */
const SPLIT_BELOW = 90

/**
 * Every indexed tracker under its project: title, a bar, done of total, and what is in flight. In a
 * wide pane each tracker is one line; in a narrow one (a split) the title gets the whole width and
 * the bar and note go on the line beneath. Takes the surface's elements rather than `$`, which may not
 * cross an import.
 */
export function renderOverview({ Box, Text }: Pick<ReturnType<EngineInterface['ui']['resolve']>, 'Box' | 'Text'>, columns: number, entries: IndexEntry[]) {
  const groups = overviewGroups(entries)
  const isSplit = columns < SPLIT_BELOW
  const longest = Math.max(0, ...entries.map(entry => entry.title.length))
  // Wide: the title column fits the longest title, leaving the note at least 30 columns.
  const titleWidth = Math.max(16, Math.min(longest, columns - BAR - 2 - 8 - 2 - 30 - 2))
  const fit = (text: string, width: number) => (text.length > width ? `${text.slice(0, width - 1)}…` : text.padEnd(width))
  const figures = (entry: IndexEntry) => `${bar(entry.done, entry.total, BAR)} ${`${entry.done}/${entry.total}`.padStart(7)}  ${overviewNote(entry)}`

  return (
    <Box flexDirection="column">
      {groups.length === 0 && <Text dimColor>No trackers indexed yet. Run /progress-tracker in a project to add its trackers.</Text>}
      {groups.map(group => (
        <Box flexDirection="column" marginBottom={1}>
          <Text bold>{group.repo}</Text>
          {group.entries.map(entry => {
            const isDone = entry.state === 'gone' || (entry.total > 0 && entry.done === entry.total)

            return isSplit
              ? (
                <Box flexDirection="column">
                  <Text dimColor={isDone} wrap="truncate-end">{`  ${entry.title}`}</Text>
                  <Text dimColor={isDone} wrap="truncate-end">{`    ${figures(entry)}`}</Text>
                </Box>
              )
              : <Text dimColor={isDone} wrap="truncate-end">{`  ${fit(entry.title, titleWidth)}  ${figures(entry)}`}</Text>
          })}
        </Box>
      ))}
    </Box>
  )
}
