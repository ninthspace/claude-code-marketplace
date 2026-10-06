// Pure logic for the progress tracker: reads cpm-next epic docs (cpm-next/shared/artifacts.md)
// tolerantly, joins them to a build-order file, and diffs the result against the artifact's db.

export type WorkStatus = 'Pending' | 'In Progress' | 'Complete' | 'Superseded' | 'Withdrawn'

/** One entry of a build-order file: a story (`story`) or a single task (`task`, e.g. "3.1") of an epic. */
export type BuildOrderItem = {
  epic: string
  story?: number
  task?: string
  note?: string
  /** Outside input the item waits for; shown as "Waiting on input" until removed from the file. */
  waitingOn?: string
}

export type BuildOrderPhase = { label: string; note?: string; items: BuildOrderItem[] }

/** `docs/specifications/NN-build-order.json`. */
export type BuildOrder = {
  title: string
  spec?: string
  /** The tracker's claude.ai URL, written by `/progress-tracker init`. */
  artifact?: string
  decisions?: string[]
  phases: BuildOrderPhase[]
}

export type TrackerStatus = 'Pending' | 'In progress' | 'Complete' | 'Waiting on input'

/** One row of the `items` collection the page renders. */
export type TrackerItem = {
  seq: number
  phase: number
  phaseLabel: string
  phaseNote?: string
  epic: string
  story: string
  title: string
  status: TrackerStatus
  blockedBy: string
  note: string
  updated: string
}

/** The `meta/tracker` document. */
export type TrackerMeta = { title: string; spec: string; updated: string; decisions: string[] }

export type EpicFile = { name: string; text: string }

type ParsedTask = { id: string; title: string; status: WorkStatus }
type ParsedStory = { number: number; title: string; status: WorkStatus; blockedBy: string[]; tasks: ParsedTask[] }
export type ParsedEpic = { id: string; short: string; status: WorkStatus; blockedBy: string[]; stories: ParsedStory[] }

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

/** "01-05-epic-naming-privacy-and-help" → "01-05". */
export const shortId = (id: string) => id.split('-epic-')[0] ?? id

export function parseEpic(file: EpicFile): ParsedEpic {
  const id = file.name.replace(/\.md$/, '')
  const epic: ParsedEpic = { id, short: shortId(id), status: 'Pending', blockedBy: [], stories: [] }
  const stories: (ParsedStory & { hasNumber: boolean })[] = []
  let story: (ParsedStory & { hasNumber: boolean }) | null = null
  let task: (ParsedTask & { hasId: boolean }) | null = null
  const tasks = new Map<ParsedStory, (ParsedTask & { hasId: boolean })[]>()

  for (const line of file.text.split(/\r?\n/)) {
    if (line.startsWith('## ')) {
      task = null
      story = { number: 0, title: line.slice(3).trim(), status: 'Pending', blockedBy: [], tasks: [], hasNumber: false }
      stories.push(story)
      tasks.set(story, [])
      continue
    }
    if (line.startsWith('### ') && story !== null) {
      task = { id: '', title: line.slice(4).trim(), status: 'Pending', hasId: false }
      tasks.get(story)?.push(task)
      continue
    }
    const field = FIELD.exec(line)
    if (field === null) continue
    const name = (field[1] ?? '').trim().toLowerCase()
    const value = field[2] ?? ''

    if (task !== null) {
      if (name === 'task') { task.id = value.trim(); task.hasId = true }
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

  // A "## " section without a **Story** field is prose, not a story.
  epic.stories = stories
    .filter(s => s.hasNumber && !Number.isNaN(s.number))
    .map(s => ({
      number: s.number,
      title: s.title,
      status: s.status,
      blockedBy: s.blockedBy,
      tasks: (tasks.get(s) ?? []).filter(t => t.hasId).map(({ id, title, status }) => ({ id, title, status })),
    }))

  return epic
}

function storyStatus(story: ParsedStory, epic: ParsedEpic): WorkStatus {
  if (epic.status === 'Complete' || story.status === 'Complete') return 'Complete'
  const isStarted = story.tasks.some(t => t.status !== 'Pending')

  return story.status === 'In Progress' || isStarted ? 'In Progress' : 'Pending'
}

function findEpic(epics: ParsedEpic[], ref: string): ParsedEpic | undefined {
  const token = ref.replace(/^epic\s+/i, '').trim()

  return epics.find(e => e.id === token || e.short === token || e.id.startsWith(`${token}-`))
}

const isEpicDone = (epic: ParsedEpic) =>
  epic.status === 'Complete' || (epic.stories.length > 0 && epic.stories.every(s => storyStatus(s, epic) === 'Complete'))

/** Blockers named in the epic doc that are not yet Complete, written the way the tracker shows items. */
function outstanding(epics: ParsedEpic[], epic: ParsedEpic, tokens: string[]): string[] {
  const left: string[] = []
  for (const token of tokens) {
    const story = /^story\s+(\d+)$/i.exec(token)
    if (story !== null) {
      const target = epic.stories.find(s => s.number === Number(story[1]))
      if (target === undefined || storyStatus(target, epic) !== 'Complete') left.push(`${epic.short} S${story[1]}`)
      continue
    }
    const target = findEpic(epics, token)
    if (target === undefined) left.push(token)
    else if (!isEpicDone(target)) left.push(`Epic ${target.short}`)
  }

  return left
}

/** The tracker rows for a build order, in build order. Items naming an epic, story or task that does not exist are skipped and reported. */
export function buildItems(order: BuildOrder, files: EpicFile[], today: string): { items: Map<string, TrackerItem>; missing: string[] } {
  const epics = files.map(parseEpic)
  const items = new Map<string, TrackerItem>()
  const missing: string[] = []
  let seq = 0

  order.phases.forEach((phase, index) => {
    for (const entry of phase.items) {
      const epic = findEpic(epics, entry.epic)
      const story = epic?.stories.find(s =>
        entry.task !== undefined ? s.tasks.some(t => t.id === entry.task) : s.number === entry.story)
      const task = entry.task === undefined ? undefined : story?.tasks.find(t => t.id === entry.task)
      if (epic === undefined || story === undefined || (entry.task !== undefined && task === undefined)) {
        missing.push(`${entry.epic} ${entry.task === undefined ? `story ${entry.story}` : `task ${entry.task}`}`)
        continue
      }

      const blockers = [...new Set([...outstanding(epics, epic, epic.blockedBy), ...outstanding(epics, epic, story.blockedBy)])]
      let status: WorkStatus
      if (task !== undefined) {
        status = storyStatus(story, epic) === 'Complete' ? 'Complete' : task.status
        // Earlier tasks of the same story come first.
        for (const earlier of story.tasks.slice(0, story.tasks.indexOf(task))) {
          if (earlier.status !== 'Complete' && status !== 'Complete') blockers.push(`${epic.short} T${earlier.id}`)
        }
      } else {
        status = storyStatus(story, epic)
      }
      if (entry.waitingOn !== undefined && status !== 'Complete') blockers.push(entry.waitingOn)

      seq += 1
      const id = task === undefined ? `${epic.short}-s${story.number}` : `${epic.short}-t${task.id}`
      items.set(id, {
        seq,
        phase: index + 1,
        phaseLabel: phase.label,
        ...(phase.note === undefined ? {} : { phaseNote: phase.note }),
        epic: epic.short,
        story: task === undefined ? `S${story.number}` : `T${task.id}`,
        title: task === undefined ? story.title : task.title,
        status: trackerStatus(status, entry.waitingOn),
        blockedBy: status === 'Complete' ? '' : blockers.join('; '),
        note: entry.note ?? '',
        updated: today,
      })
    }
  })

  return { items, missing }
}

function trackerStatus(status: WorkStatus, waitingOn: string | undefined): TrackerStatus {
  if (status === 'Complete') return 'Complete'
  if (status === 'In Progress') return 'In progress'
  if (waitingOn !== undefined) return 'Waiting on input'
  return 'Pending'
}

export type LiveDoc = { id: string; version: number; data: Record<string, unknown> }

export type Write =
  | { op: 'set'; collection: string; doc_id: string; data: Record<string, unknown>; if_version?: number }
  | { op: 'delete'; collection: string; doc_id: string; if_version: number }

const sameFields = (a: Record<string, unknown>, b: Record<string, unknown>, skip: string) => {
  const keys = new Set([...Object.keys(a), ...Object.keys(b)])
  keys.delete(skip)

  return [...keys].every(k => JSON.stringify(a[k]) === JSON.stringify(b[k]))
}

/**
 * The writes that bring the db in line with the docs. Unchanged rows are left alone. A row's
 * `updated` date moves only when its status changes; the meta date is the latest row date.
 */
export function diff(desired: Map<string, TrackerItem>, meta: Omit<TrackerMeta, 'updated'>, live: LiveDoc[], liveMeta: LiveDoc | undefined): Write[] {
  const writes: Write[] = []
  const byId = new Map(live.map(d => [d.id, d]))
  let latest = ''

  for (const [id, item] of desired) {
    const current = byId.get(id)
    const row: TrackerItem = { ...item }
    if (current !== undefined && current.data.status === item.status && typeof current.data.updated === 'string') {
      row.updated = current.data.updated
    }
    if (row.updated > latest) latest = row.updated
    if (current !== undefined && sameFields(current.data, row as unknown as Record<string, unknown>, '')) continue
    writes.push({ op: 'set', collection: 'items', doc_id: id, data: row as unknown as Record<string, unknown>, ...(current === undefined ? {} : { if_version: current.version }) })
  }
  for (const doc of live) {
    if (!desired.has(doc.id)) writes.push({ op: 'delete', collection: 'items', doc_id: doc.id, if_version: doc.version })
  }

  const nextMeta: TrackerMeta = { ...meta, updated: latest }
  if (liveMeta === undefined || !sameFields(liveMeta.data, nextMeta, '')) {
    writes.push({ op: 'set', collection: 'meta', doc_id: 'tracker', data: nextMeta, ...(liveMeta === undefined ? {} : { if_version: liveMeta.version }) })
  }

  return writes
}

/** Documents from an ArtifactData read: one JSON object per line between its BEGIN and END markers. */
export function parseDocs(text: string): LiveDoc[] {
  const docs: LiveDoc[] = []
  for (const line of text.split(/\r?\n/)) {
    const trimmed = line.trim()
    if (!trimmed.startsWith('{"id"')) continue
    try {
      const parsed = JSON.parse(trimmed) as { id?: unknown; version?: unknown; data?: unknown }
      if (typeof parsed.id === 'string' && typeof parsed.version === 'number' && typeof parsed.data === 'object' && parsed.data !== null) {
        docs.push({ id: parsed.id, version: parsed.version, data: parsed.data as Record<string, unknown> })
      }
    } catch {
      // Not a document line.
    }
  }

  return docs
}

/** The artifact URL in an Artifact publish result. */
export function artifactUrlIn(text: string): string | undefined {
  return /https:\/\/claude\.ai\/(?:code\/)?artifact\/[A-Za-z0-9_-]+/.exec(text)?.[0]
}

export function parseBuildOrder(text: string): BuildOrder {
  const parsed = JSON.parse(text) as Partial<BuildOrder>
  if (typeof parsed.title !== 'string' || !Array.isArray(parsed.phases)) {
    throw new Error('a build-order file needs a "title" string and a "phases" array')
  }

  return parsed as BuildOrder
}

/** Local calendar date as YYYY-MM-DD. */
export function dateOf(ms: number): string {
  const d = new Date(ms)
  const pad = (n: number) => String(n).padStart(2, '0')

  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`
}

const ESCAPES: Record<string, string> = { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }
export const escapeHtml = (text: string) => text.replace(/[&<>"']/g, c => ESCAPES[c] ?? c)

/** The page template with its title and spec filled in. */
export function fillTemplate(template: string, order: BuildOrder, repo: string): string {
  return template
    .replaceAll('{{TITLE}}', escapeHtml(order.title))
    .replaceAll('{{REPO}}', escapeHtml(repo))
    .replaceAll('{{SPEC}}', escapeHtml(order.spec ?? ''))
}

/** Splits writes into batches of at most 50, the ArtifactData limit. */
export function chunk<T>(list: T[], size = 50): T[][] {
  const out: T[][] = []
  for (let i = 0; i < list.length; i += size) out.push(list.slice(i, i + size))

  return out
}

/** One build-order file whose tracker differs from the epic docs. */
export type Drift = { name: string; url: string; file: string; writes: Write[] }

/** The file a drift's writes are saved to: ready-made `ArtifactData` batches of at most 50. */
export function pendingJson(drift: Pick<Drift, 'url' | 'writes'>): string {
  return `${JSON.stringify({ url: drift.url, batches: chunk(drift.writes) }, null, 2)}\n`
}

const rowIds = (writes: Write[]) => writes.filter(w => w.collection === 'items').map(w => w.doc_id)

/** One line per drift, for the person: what differs and where the writes are saved. */
export function describeDrift(drift: Drift): string {
  const ids = rowIds(drift.writes)
  const shown = ids.length > 6 ? `${ids.slice(0, 6).join(', ')} and ${ids.length - 6} more` : ids.join(', ')

  return `${drift.name}: ${ids.length === 0 ? 'the title or notes differ' : `${ids.length} ${ids.length === 1 ? 'row' : 'rows'} out of date (${shown})`}; writes saved to ${drift.file}`
}

/**
 * What the model reads after a tool call that changed an epic doc or build-order file: the tracker
 * is out of date and how to bring it in line. Small drifts carry their writes inline.
 */
export function modelNote(drifts: Drift[]): string {
  const parts = drifts.map(d => {
    const inline = d.writes.length <= 8
      ? ` Writes: ${JSON.stringify(d.writes)}`
      : ` ${d.writes.length} writes, in batches of at most 50, are in that file.`

    return `${describeDrift(d)}. Apply them with the ArtifactData tool, action "batch", url ${d.url}.${inline}`
  })

  return `Progress tracker out of date. ${parts.join(' ')} If a write is refused as stale, run /progress-tracker for fresh versions. Do not edit the tracker's rows any other way.`
}
