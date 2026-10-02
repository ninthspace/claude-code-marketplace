import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { NextNote, NextPlan, NextStory } from '../types'
import { buildPlan, describePlan, storyText } from './plan'
import type { EpicFile } from './plan'

const PANE = 'whats-next'
const POLL_MS = 3000
const NOTE_MODEL = 'sonnet'

const plan = atom({ plugin: 'whats-next', key: 'plan' } as const, null)
const note = atom({ plugin: 'whats-next', key: 'note' } as const, null)
const isNoteBusy = atom({ plugin: 'whats-next', key: 'isNoteBusy' } as const, false)
const noteError = atom({ plugin: 'whats-next', key: 'noteError' } as const, null)

const EPIC_FILE = /-epic-.*\.md$/
const WRITING_TOOLS = new Set(['Edit', 'Write', 'MultiEdit', 'NotebookEdit', 'Bash'])

async function findRoot($: EngineInterface): Promise<string | null> {
  let dir = await $.session.cwd()
  for (;;) {
    if (await $.fs.exists(`${dir}/docs/epics`)) return dir
    const cut = dir.lastIndexOf('/')
    if (cut <= 0) return null
    dir = dir.slice(0, cut)
  }
}

async function listEpics($: EngineInterface, dir: string) {
  if (!(await $.fs.exists(dir))) return []
  const entries = await $.fs.list(dir)

  return entries.filter(e => e.kind === 'file' && EPIC_FILE.test(e.name)).sort((a, b) => a.name.localeCompare(b.name))
}

async function readEpics($: EngineInterface, root: string): Promise<{ files: EpicFile[]; signature: string }> {
  const active = await listEpics($, `${root}/docs/epics`)
  const archived = await listEpics($, `${root}/docs/archive/epics`)
  const files: EpicFile[] = []
  for (const e of active) files.push({ name: e.name, text: await $.fs.read(`${root}/docs/epics/${e.name}`), isArchived: false })
  for (const e of archived) files.push({ name: e.name, text: await $.fs.read(`${root}/docs/archive/epics/${e.name}`), isArchived: true })

  return { files, signature: signatureOf(root, active, archived) }
}

function signatureOf(root: string, ...lists: { name: string; mtimeMs: number; size: number }[][]): string {
  return [root, ...lists.flat().map(e => `${e.name}:${e.mtimeMs}:${e.size}`)].join('|')
}

let isRefreshing = false
let openedFor: string | null = null

// Re-reads docs/epics only when a file there was added, removed or changed.
async function refresh($: EngineInterface): Promise<NextPlan | null> {
  if (isRefreshing) return read($, plan)
  isRefreshing = true
  try {
    const root = await findRoot($)
    const current = await read($, plan)
    if (root === null) {
      if (current !== null) await update($, plan, () => null)
      return null
    }
    const active = await listEpics($, `${root}/docs/epics`)
    const archived = await listEpics($, `${root}/docs/archive/epics`)
    if (current !== null && current.signature === signatureOf(root, active, archived)) return current

    const { files, signature } = await readEpics($, root)
    const next = buildPlan(root, files, signature)
    await update($, plan, () => next)
    if (current?.root !== root) {
      const saved = (await $.store.get(`note:${root}`)) as NextNote | undefined
      await update($, note, () => saved ?? null)
      await update($, noteError, () => null)
    }
    await maybeOpen($, next)

    return next
  } finally {
    isRefreshing = false
  }
}

// Opens the pane unasked once per repo, when that repo has work left.
async function maybeOpen($: EngineInterface, next: NextPlan) {
  if (next.order.length === 0 || openedFor === next.root) return
  openedFor = next.root
  await $.ui.open({ id: PANE, title: "What's next" })
}

async function askForNote($: EngineInterface) {
  if (await read($, isNoteBusy)) return
  const current = await refresh($)
  if (current === null || current.order.length === 0) return
  await update($, isNoteBusy, () => true)
  await update($, noteError, () => null)
  try {
    const { files } = await readEpics($, current.root)
    const focus = current.order.slice(0, 2).map(s => {
      const file = files.find(f => f.name.replace(/\.md$/, '') === s.epicId)
      return file === undefined ? '' : `### ${s.epicId} (${s.epicTitle})\n${storyText(file, s.number)}`
    })
    const result = await $.model.complete({
      model: NOTE_MODEL,
      effort: 'medium',
      maxTokens: 900,
      system:
        'You read cpm-next planning docs (epics with stories, tasks and acceptance criteria) and tell a developer what to do next. ' +
        'Answer in at most 8 short markdown bullets. Name the story and task, the concrete next steps, and any risk or ' +
        'dependency to watch. Write literally: no preamble, no metaphor, no closing line.',
      prompt: `${describePlan(current, 20)}\n\nThe first stories in full:\n\n${focus.join('\n\n')}`,
    })
    if (result.isAnswered) {
      const saved: NextNote = { root: current.root, signature: current.signature, text: result.text.trim(), at: await $.clock.now() }
      await update($, note, () => saved)
      await $.store.set(`note:${current.root}`, saved)
    } else {
      await update($, noteError, () => `The note failed: ${result.reason}`)
    }
  } finally {
    await update($, isNoteBusy, () => false)
  }
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({ name: 'next', description: "Show what's left to do in this repo's cpm-next epics, in order" })
    await refresh($)
    $.clock.every(POLL_MS, () => void refresh($))

    return next(e)
  })

  on('command.run', { command: 'next' }, async $ => {
    const current = await refresh($)
    if (current === null) return { text: 'No docs/epics folder in this directory or above it.' }
    await $.ui.open({ id: PANE, title: "What's next" })

    return { text: describePlan(current) }
  })

  // Edits made by tools show up at once rather than at the next poll.
  on('tool.call', async ($, e, next) => {
    const result = await next(e)
    if (WRITING_TOOLS.has(String(e.tool))) await refresh($).catch(() => undefined)

    return result
  })

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    const current = await read($, plan)
    const first = current?.order[0]
    if (e.props.hasSurvey || current === null || first === undefined) return next(e)
    const { Box, Text } = $.ui.resolve(e)
    const task = first.nextTask === null ? '' : ` → ${first.nextTask.id} ${first.nextTask.title}`

    return (
      <Box>
        <Text wrap="truncate-end">
          <Text color="cyan">Next </Text>
          <Text bold>{first.epicId.split('-epic-')[0]} S{first.number}</Text>
          <Text> {first.title}{task}</Text>
          <Text dimColor>  ({current.order.length} stories left · /next)</Text>
        </Text>
      </Box>
    )
  })

  on('ui.render', { component: 'Pane', requestId: PANE }, async ($, e) => {
    const { Box, Text, Button, Markdown } = $.ui.resolve(e)
    const current = await read($, plan)
    const saved = await read($, note)
    const isBusy = await read($, isNoteBusy)
    const error = await read($, noteError)

    if (current === null) return <Text dimColor>No docs/epics folder in this directory or above it.</Text>
    if (current.order.length === 0) return <Text dimColor>{current.repo}: nothing left in docs/epics.</Text>

    const label = (s: NextStory) => `${s.epicId.split('-epic-')[0]} S${s.number}`
    const stateOf = (s: NextStory) =>
      s.status === 'In Progress' ? 'doing' : s.isReady ? 'ready' : `after ${s.waitsOn.join(', ')}`
    const first = current.order[0] as NextStory
    const isStale = saved !== null && saved.signature !== current.signature

    return (
      <Box flexDirection="column">
        <Text bold>{current.repo}<Text dimColor>  {current.order.length} stories · {current.epics.length} epics left</Text></Text>
        <Text> </Text>
        <Text color="cyan" bold>Now</Text>
        <Text wrap="truncate-end">{label(first)} {first.title}</Text>
        {first.nextTask !== null && (
          <Text wrap="truncate-end" dimColor>  task {first.nextTask.id} {first.nextTask.title} ({first.tasksDone}/{first.tasksTotal} done)</Text>
        )}
        <Text> </Text>
        <Text color="cyan" bold>Order</Text>
        {current.order.slice(0, 30).map((s, i) => (
          <Text wrap="truncate-end" dimColor={!s.isReady && s.status !== 'In Progress'}>
            {String(i + 1).padStart(2)} {label(s)} {s.title}  <Text color={s.status === 'In Progress' ? 'yellow' : s.isReady ? 'green' : undefined}>{stateOf(s)}</Text>
          </Text>
        ))}
        {current.order.length > 30 && <Text dimColor>   … {current.order.length - 30} more</Text>}
        <Text> </Text>
        <Text color="cyan" bold>Epics</Text>
        {current.epics.map(epic => (
          <Text wrap="truncate-end">
            {epic.id.split('-epic-')[0]} {epic.title}  <Text dimColor>{epic.storiesDone}/{epic.storiesTotal} stories{epic.waitsOn.length > 0 ? ` · after ${epic.waitsOn.join(', ')}` : ''}</Text>
          </Text>
        ))}
        <Text> </Text>
        <Box>
          <Text color="cyan" bold>Next steps </Text>
          <Button
            key="ask"
            hotkey="a"
            label={isBusy ? 'asking…' : saved === null ? 'Ask Claude' : 'Refresh'}
            onPress={() => void askForNote($)}
          />
        </Box>
        {error !== null && <Text color="red">{error}</Text>}
        {saved !== null && isStale && <Text dimColor>The epics changed since this note was written.</Text>}
        {saved !== null && <Markdown text={saved.text} dimColor={isStale} />}
      </Box>
    )
  })
}
