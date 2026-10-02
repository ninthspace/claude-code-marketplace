import type { NextEpic, NextPlan, NextStory, NextTask, WorkStatus } from '../types'

// Reads cpm-next epic docs (shared/artifacts.md in the plugin) tolerantly:
// field case, trailing hard-break spaces and "Done" for "Complete" all pass.

export type EpicFile = { name: string; text: string; isArchived: boolean }

type ParsedStory = {
  number: number
  title: string
  status: WorkStatus
  blockedBy: string[]
  tasks: NextTask[]
  text: string
}

type ParsedEpic = {
  id: string
  title: string
  status: WorkStatus
  blockedBy: string[]
  stories: ParsedStory[]
  sortKey: number[]
  isArchived: boolean
}

const FIELD = /^\*\*([A-Za-z ]+)\*\*:\s*(.*?)\s*$/

export function normaliseStatus(raw: string | undefined): WorkStatus {
  const value = (raw ?? '').trim().toLowerCase()
  if (value.startsWith('complete') || value.startsWith('done')) return 'Complete'
  if (value.startsWith('in progress')) return 'In Progress'
  if (value.startsWith('superseded')) return 'Superseded'
  if (value.startsWith('withdrawn')) return 'Withdrawn'
  return 'Pending'
}

export function parseBlockers(raw: string | undefined): string[] {
  const value = (raw ?? '').trim()
  if (value === '' || /^[—–-]+$/.test(value) || /^none$/i.test(value)) return []

  return value.split(/[,;]/).map(item => item.trim()).filter(item => item !== '')
}

function sortKeyOf(id: string): number[] {
  const prefix = id.split('-epic-')[0] ?? id

  return prefix.split('-').map(Number).filter(n => !Number.isNaN(n))
}

function compareKeys(a: number[], b: number[]): number {
  for (let i = 0; i < Math.max(a.length, b.length); i++) {
    const diff = (a[i] ?? -1) - (b[i] ?? -1)
    if (diff !== 0) return diff
  }

  return 0
}

export function parseEpic(file: EpicFile): ParsedEpic {
  const id = file.name.replace(/\.md$/, '')
  const epic: ParsedEpic = {
    id,
    title: id,
    status: 'Pending',
    blockedBy: [],
    stories: [],
    sortKey: sortKeyOf(id),
    isArchived: file.isArchived,
  }
  let story: (ParsedStory & { hasNumber: boolean }) | null = null
  let task: (NextTask & { hasId: boolean }) | null = null
  const stories: (ParsedStory & { hasNumber: boolean })[] = []

  for (const line of file.text.split(/\r?\n/)) {
    if (line.startsWith('# ') && epic.title === id) {
      epic.title = line.slice(2).trim()
      continue
    }
    if (line.startsWith('## ')) {
      task = null
      story = { number: 0, title: line.slice(3).trim(), status: 'Pending', blockedBy: [], tasks: [], text: '', hasNumber: false }
      stories.push(story)
    }
    if (story !== null) story.text += `${line}\n`
    if (line.startsWith('### ') && story !== null) {
      task = { id: '', title: line.slice(4).trim(), status: 'Pending', hasId: false }
      story.tasks.push(task)
      continue
    }

    const field = FIELD.exec(line)
    if (field === null) continue
    const name = (field[1] ?? '').trim().toLowerCase()
    const value = field[2] ?? ''

    if (task !== null) {
      if (name === 'task') { task.id = value; task.hasId = true }
      if (name === 'status') task.status = normaliseStatus(value)
    } else if (story !== null) {
      if (name === 'story') { story.number = Number.parseInt(value, 10); story.hasNumber = true }
      if (name === 'status') story.status = normaliseStatus(value)
      if (name === 'blocked by') story.blockedBy = parseBlockers(value)
    } else {
      if (name === 'status') epic.status = normaliseStatus(value)
      if (name === 'blocked by') epic.blockedBy = parseBlockers(value)
    }
  }

  // A "## " section without a **Story** field is prose (notes, context), not a story.
  epic.stories = stories
    .filter(s => s.hasNumber && !Number.isNaN(s.number))
    .map(({ hasNumber: _, ...s }) => ({
      ...s,
      tasks: s.tasks.filter(t => (t as NextTask & { hasId: boolean }).hasId)
        .map(({ id, title, status }) => ({ id, title, status })),
    }))

  return epic
}

function effectiveStatus(story: ParsedStory): WorkStatus {
  if (story.status === 'Complete') return 'Complete'
  const isStarted = story.tasks.some(t => t.status !== 'Pending')

  return story.status === 'In Progress' || isStarted ? 'In Progress' : 'Pending'
}

const storyKey = (epicId: string, n: number) => `${epicId}#${n}`

export function buildPlan(root: string, files: EpicFile[], signature: string): NextPlan {
  const epics = files.map(parseEpic).sort((a, b) => compareKeys(a.sortKey, b.sortKey))
  const isTerminal = (e: ParsedEpic) => e.status === 'Superseded' || e.status === 'Withdrawn'

  const findEpic = (token: string): ParsedEpic | undefined => {
    const ref = token.replace(/^epic\s+/i, '').trim()

    return epics.find(e => e.id === ref || e.id.startsWith(`${ref}-`))
  }

  const done = new Set<string>()
  for (const epic of epics) {
    for (const story of epic.stories) {
      if (epic.status === 'Complete' || story.status === 'Complete') done.add(storyKey(epic.id, story.number))
    }
  }

  const isEpicDone = (epic: ParsedEpic, finished: Set<string>) =>
    !isTerminal(epic) &&
    (epic.status === 'Complete' ||
      (epic.stories.length > 0 && epic.stories.every(s => finished.has(storyKey(epic.id, s.number)))))

  const outstanding = (epic: ParsedEpic, tokens: string[], finished: Set<string>): string[] =>
    tokens.filter(token => {
      const story = /^story\s+(\d+)$/i.exec(token)
      if (story !== null) return !finished.has(storyKey(epic.id, Number(story[1])))
      const target = findEpic(token)

      return target === undefined || !isEpicDone(target, finished)
    })

  type Candidate = { epic: ParsedEpic; story: ParsedStory; status: WorkStatus }
  const open = epics.filter(e => !e.isArchived && !isTerminal(e) && e.status !== 'Complete')
  let remaining: Candidate[] = open.flatMap(epic =>
    epic.stories
      .filter(story => !done.has(storyKey(epic.id, story.number)))
      .map(story => ({ epic, story, status: effectiveStatus(story) })),
  )

  // A story often repeats its epic's dependency; list each one once.
  const waitsOnNow = (c: Candidate, finished: Set<string>) => [
    ...new Set([...outstanding(c.epic, c.epic.blockedBy, finished), ...outstanding(c.epic, c.story.blockedBy, finished)]),
  ]

  const toStory = (c: Candidate): NextStory => {
    const waitsOn = waitsOnNow(c, done)
    const nextTask = c.story.tasks.find(t => t.status !== 'Complete') ?? null

    return {
      epicId: c.epic.id,
      epicTitle: c.epic.title,
      number: c.story.number,
      title: c.story.title,
      status: c.status,
      isReady: waitsOn.length === 0,
      waitsOn,
      tasksDone: c.story.tasks.filter(t => t.status === 'Complete').length,
      tasksTotal: c.story.tasks.length,
      nextTask,
    }
  }

  // Walk the work forward: take the best ready story, treat it as done, repeat.
  // In Progress first, then epic number, then story number.
  const rank = (a: Candidate, b: Candidate) =>
    (a.status === 'In Progress' ? 0 : 1) - (b.status === 'In Progress' ? 0 : 1) ||
    compareKeys(a.epic.sortKey, b.epic.sortKey) ||
    a.story.number - b.story.number

  const simulated = new Set(done)
  const order: NextStory[] = []
  while (remaining.length > 0) {
    const ready = remaining.filter(c => waitsOnNow(c, simulated).length === 0).sort(rank)
    const pick = ready[0]
    if (pick === undefined) break
    order.push(toStory(pick))
    simulated.add(storyKey(pick.epic.id, pick.story.number))
    remaining = remaining.filter(c => c !== pick)
  }
  // Whatever is left can never become ready from the docs alone (a cycle or an unknown dependency).
  order.push(...remaining.sort(rank).map(toStory))

  const nextEpics: NextEpic[] = open.map(epic => ({
    id: epic.id,
    title: epic.title,
    status: epic.stories.some(s => effectiveStatus(s) !== 'Pending') ? 'In Progress' : epic.status,
    storiesDone: epic.stories.filter(s => done.has(storyKey(epic.id, s.number))).length,
    storiesTotal: epic.stories.length,
    waitsOn: outstanding(epic, epic.blockedBy, done),
  }))

  return {
    root,
    repo: root.split('/').filter(Boolean).at(-1) ?? root,
    epics: nextEpics,
    order,
    signature,
  }
}

/** The plan as plain text: what /next prints and what the AI note is asked about. */
export function describePlan(plan: NextPlan, limit = 12): string {
  if (plan.order.length === 0) return `${plan.repo}: no cpm-next work left in docs/epics.`
  const lines = [`${plan.repo}: ${plan.order.length} stories left across ${plan.epics.length} epics, in recommended order:`]
  plan.order.slice(0, limit).forEach((s, i) => {
    const state = s.status === 'In Progress' ? 'in progress' : s.isReady ? 'ready' : `waits on ${s.waitsOn.join(', ')}`
    const next = s.nextTask === null ? '' : ` — next task ${s.nextTask.id} ${s.nextTask.title}`
    lines.push(`${i + 1}. ${s.epicId} Story ${s.number}: ${s.title} (${state}; ${s.tasksDone}/${s.tasksTotal} tasks)${next}`)
  })
  if (plan.order.length > limit) lines.push(`… and ${plan.order.length - limit} more.`)

  return lines.join('\n')
}

/** The markdown of one story, for the AI note's context. */
export function storyText(file: EpicFile, number: number): string {
  return parseEpic(file).stories.find(s => s.number === number)?.text ?? ''
}
