import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { NextNote, NextPlan, NextStory } from '../types'
import { buildPlan, describePlan, hasWork, storyText } from './plan'
import type { EpicFile, SpecFile } from './plan'

const PANE = 'whats-next'
const POLL_MS = 3000
const NOTE_MODEL = 'sonnet'

const plan = atom({ plugin: 'whats-next', key: 'plan' } as const, null)
const note = atom({ plugin: 'whats-next', key: 'note' } as const, null)
const isNoteBusy = atom({ plugin: 'whats-next', key: 'isNoteBusy' } as const, false)
const noteError = atom({ plugin: 'whats-next', key: 'noteError' } as const, null)

const EPIC_FILE = /-epic-.*\.md$/
const SPEC_FILE = /^\d+-spec-.*\.md$/
const WRITING_TOOLS = new Set(['Edit', 'Write', 'MultiEdit', 'NotebookEdit', 'Bash'])

type Listing = { name: string; mtimeMs: number; size: number }

const plural = (n: number, one: string, many: string) => `${n} ${n === 1 ? one : many}`

async function findRoot($: EngineInterface): Promise<string | null> {
  let dir = await $.session.cwd()
  for (;;) {
    if ((await $.fs.exists(`${dir}/docs/epics`)) || (await $.fs.exists(`${dir}/docs/specifications`))) return dir
    const cut = dir.lastIndexOf('/')
    if (cut <= 0) return null
    dir = dir.slice(0, cut)
  }
}

async function listDocs($: EngineInterface, dir: string, pattern: RegExp): Promise<Listing[]> {
  if (!(await $.fs.exists(dir))) return []
  const entries = await $.fs.list(dir)

  return entries.filter(e => e.kind === 'file' && pattern.test(e.name)).sort((a, b) => a.name.localeCompare(b.name))
}

// Active and archived epics, and active specs; the signature covers all three folders.
async function listAll($: EngineInterface, root: string) {
  const active = await listDocs($, `${root}/docs/epics`, EPIC_FILE)
  const archived = await listDocs($, `${root}/docs/archive/epics`, EPIC_FILE)
  const specs = await listDocs($, `${root}/docs/specifications`, SPEC_FILE)

  return { active, archived, specs, signature: signatureOf(root, active, archived, specs) }
}

async function readDocs($: EngineInterface, root: string): Promise<{ files: EpicFile[]; specs: SpecFile[]; signature: string }> {
  const listed = await listAll($, root)
  const files: EpicFile[] = []
  for (const e of listed.active) files.push({ name: e.name, text: await $.fs.read(`${root}/docs/epics/${e.name}`), isArchived: false })
  for (const e of listed.archived) files.push({ name: e.name, text: await $.fs.read(`${root}/docs/archive/epics/${e.name}`), isArchived: true })
  const specs: SpecFile[] = []
  for (const s of listed.specs) specs.push({ name: s.name, text: await $.fs.read(`${root}/docs/specifications/${s.name}`) })

  return { files, specs, signature: listed.signature }
}

function signatureOf(root: string, ...lists: Listing[][]): string {
  return [root, ...lists.map(list => list.map(e => `${e.name}:${e.mtimeMs}:${e.size}`).join(','))].join('|')
}

let isRefreshing = false
let openedFor: string | null = null

// Re-reads the docs only when an epic or spec file was added, removed or changed.
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
    if (current !== null && current.signature === (await listAll($, root)).signature) return current

    const { files, specs, signature } = await readDocs($, root)
    const next = buildPlan(root, files, signature, specs)
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
  if (!hasWork(next) || openedFor === next.root) return
  openedFor = next.root
  await $.ui.open({ id: PANE, title: "What's next" })
}

async function askForNote($: EngineInterface) {
  if (await read($, isNoteBusy)) return
  const current = await refresh($)
  if (current === null || !hasWork(current)) return
  await update($, isNoteBusy, () => true)
  await update($, noteError, () => null)
  try {
    const { files } = await readDocs($, current.root)
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
      prompt: focus.length > 0
        ? `${describePlan(current, 20)}\n\nThe first stories in full:\n\n${focus.join('\n\n')}`
        : `${describePlan(current, 20)}\n\nNo stories are left; say which spec to plan into epics first and why.`,
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
    await $.command.register({ name: 'next', description: "Show what's left to do in this repo's cpm-next epics, in order, and specs with no epics yet" })
    await refresh($)
    $.clock.every(POLL_MS, () => void refresh($))

    return next(e)
  })

  on('command.run', { command: 'next' }, async $ => {
    const current = await refresh($)
    if (current === null) return { text: 'No docs/epics or docs/specifications folder in this directory or above it.' }
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
    const spec = current?.specs[0]
    if (e.props.hasSurvey || current === null || (first === undefined && spec === undefined)) return next(e)
    const { Box, Text } = $.ui.resolve(e)

    if (first === undefined && spec !== undefined) {
      return (
        <Box>
          <Text wrap="truncate-end">
            <Text color="cyan">Plan next </Text>
            <Text bold>spec {spec.id.split('-spec-')[0]}</Text>
            <Text> {spec.title}</Text>
            <Text dimColor>  ({current.specs.length} {current.specs.length === 1 ? 'spec' : 'specs'} without epics · /next)</Text>
          </Text>
        </Box>
      )
    }
    if (first === undefined) return next(e)
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

    if (current === null) return <Text dimColor>No docs/epics or docs/specifications folder in this directory or above it.</Text>
    if (!hasWork(current)) return <Text dimColor>{current.repo}: no stories left and every spec has epics.</Text>

    const label = (s: NextStory) => `${s.epicId.split('-epic-')[0]} S${s.number}`
    // "Epic 34-01-epic-coupons-overview" reads as "34-01" and "Story 2" as "S2", matching the row labels;
    // an epic named by both the epic and the story appears once.
    const after = (tokens: string[]) => {
      const short = tokens.map(t => t.replace(/^story\s+(\d+)$/i, 'S$1').replace(/^epic\s+/i, '').replace(/-epic-.*$/, ''))

      return `after ${[...new Set(short)].join(', ')}`
    }
    const stateOf = (s: NextStory) => (s.status === 'In Progress' ? 'doing' : s.isReady ? 'ready' : after(s.waitsOn))
    const colourOf = (s: NextStory) => (s.status === 'In Progress' ? 'yellow' : s.isReady ? 'green' : 'red')
    const first = current.order[0]
    const isStale = saved !== null && saved.signature !== current.signature
    const specCount = `${current.specs.length} ${current.specs.length === 1 ? 'spec' : 'specs'} without epics`
    const summary = [
      current.order.length > 0 ? `${plural(current.order.length, 'story', 'stories')} · ${plural(current.epics.length, 'epic', 'epics')} left` : '',
      current.specs.length > 0 ? specCount : '',
    ].filter(Boolean).join(' · ')

    return (
      <Box flexDirection="column">
        <Text bold>{current.repo}<Text dimColor>  {summary}</Text></Text>
        <Text> </Text>
        {first !== undefined && (
          <Box flexDirection="column">
            <Text color="cyan" bold>Now</Text>
            <Text wrap="truncate-end">{label(first)} {first.title}</Text>
            {first.nextTask !== null && (
              <Text wrap="truncate-end" dimColor>  task {first.nextTask.id} {first.nextTask.title} ({first.tasksDone}/{first.tasksTotal} done)</Text>
            )}
            <Text> </Text>
            <Text color="cyan" bold>Order</Text>
            {current.order.slice(0, 30).map((s, i) => (
              <Text wrap="truncate-end">
                <Text dimColor={!s.isReady && s.status !== 'In Progress'}>{String(i + 1).padStart(2)} {label(s)} {s.title}  </Text>
                <Text color={colourOf(s)}>{stateOf(s)}</Text>
              </Text>
            ))}
            {current.order.length > 30 && <Text dimColor>   … {current.order.length - 30} more</Text>}
            <Text> </Text>
            <Text color="cyan" bold>Epics</Text>
            {current.epics.map(epic => (
              <Text wrap="truncate-end">
                {epic.id.split('-epic-')[0]} {epic.title}  <Text dimColor>{epic.storiesDone}/{epic.storiesTotal} stories</Text>
                {epic.waitsOn.length > 0 && <Text color="red">  {after(epic.waitsOn)}</Text>}
              </Text>
            ))}
            <Text> </Text>
          </Box>
        )}
        {current.specs.length > 0 && (
          <Box flexDirection="column">
            <Text color="cyan" bold>Specs without epics</Text>
            {current.specs.map(spec => (
              <Text wrap="truncate-end">
                {spec.id.split('-spec-')[0]} {spec.title}  <Text color="magenta">plan</Text>
              </Text>
            ))}
            <Text dimColor wrap="truncate-end">  {'/cpm-next:plan docs/specifications/<file>'}</Text>
            <Text> </Text>
          </Box>
        )}
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
        {saved !== null && isStale && <Text dimColor>The epics or specs changed since this note was written.</Text>}
        {saved !== null && <Markdown text={saved.text} dimColor={isStale} />}
      </Box>
    )
  })
}
