// Story timings: when each story went In Progress and Complete, read from the epic docs as checks see
// them change, and the estimates those timings support once there are enough of them.

import type { EpicFile, IndexEntry, TimeRecord, Timing, TrackerItem, TypicalRange, WorkStatus } from './progress'
import { effortOf, familyOf, parseEpic, storyStatus } from './progress'

export { effortOf, familyOf }

/**
 * One story's record. `started` and `finished` are epoch ms, set only when the change was seen happen;
 * `model` is the family of the model that last wrote the story's epic doc when its start was seen.
 */
export type StoryTime = TimeRecord

/** A project's records, keyed as the tracker names stories: "04-01 S5". */
export type Times = Record<string, StoryTime>

/** One story as a check saw it; `file` is its epic doc's file name. */
export type Observed = { key: string; status: WorkStatus; effort: string; at: number; file: string }

/** The last model to write each epic doc, by file name: a model id as the step that wrote it was answered by. */
export type Writers = Record<string, string>

/** Finished stories needed before an estimate is given. */
export const MIN_STORIES = 10
/** How many times the quick quartile the slow one may be for an estimate still to count as a prediction. */
export const MAX_SPREAD = 3


/** Each story in the epic docs, stamped with the time its doc was last written. */
export function observe(files: (EpicFile & { mtimeMs: number })[]): Observed[] {
  return files.flatMap(file => {
    const epic = parseEpic(file)

    return epic.stories.map(story => ({
      key: `${epic.short} S${story.number}`,
      status: storyStatus(story, epic),
      effort: effortOf(story.effort),
      at: file.mtimeMs,
      file: file.name,
    }))
  })
}

/**
 * Folds a check's observations into the records. A start is taken only when a story seen Pending is
 * next seen In Progress, and a finish only when one seen In Progress with a start is next seen
 * Complete, so a story first seen part-way, or one that moved twice between checks, gets no time.
 * A start records the family of its epic doc's last writer, when the doc has one.
 */
export function recordTimes(before: Times, observed: Observed[], writers: Writers = {}): Times {
  const times: Times = { ...before }
  for (const { key, status, effort, at, file } of observed) {
    const prior = times[key]
    if (prior === undefined) {
      times[key] = { status, effort }
      continue
    }
    const next: StoryTime = { ...prior, status, effort }
    if (prior.status === 'Pending' && status === 'In Progress') {
      next.started = at
      const writer = writers[file]
      if (writer !== undefined) next.model = familyOf(writer)
    }
    if (prior.status === 'In Progress' && status === 'Complete' && prior.started !== undefined) next.finished = at
    // A story reopened goes on from its first start.
    if (status === 'In Progress') delete next.finished
    times[key] = next
  }

  return times
}

/** Each live agent loop's model, keyed by its `agentId`, `''` for the main loop. */
export type LoopModels = ReadonlyMap<string, string>

const loopKey = (agentId: string | undefined) => agentId ?? ''

/**
 * The loop models after one step: `source.usage.model` replaces the loop's entry when it is a string.
 * A null usage leaves the entry as it was, and any error reading the source leaves the map unchanged.
 */
export function recordStep(map: LoopModels, agentId: string | undefined, source: { usage?: { model?: unknown } | null }): LoopModels {
  try {
    const model = source.usage?.model
    if (typeof model !== 'string' || model === '') return map

    return new Map(map).set(loopKey(agentId), model)
  } catch {
    return map
  }
}

/** The loop models once a subagent's loop has ended; the main loop's entry is never dropped. */
export function forgetLoop(map: LoopModels, agentId: string | undefined): LoopModels {
  if (agentId === undefined || !map.has(agentId)) return map
  const next = new Map(map)
  next.delete(agentId)

  return next
}

/** The model a loop is answered by, if one of its steps has been seen. */
export const modelOf = (map: LoopModels, agentId: string | undefined) => map.get(loopKey(agentId))

const EPIC_NAME = /[\w.-]+-epic-[\w.-]*\.md/g

/**
 * The epic docs a tool call writes, by file name: an `Edit`, `Write` or `MultiEdit` whose `file_path`
 * ends in one, or a `Bash` whose command names one. Other tools write none.
 */
export function writtenEpics(tool: string, input: { file_path?: unknown; command?: unknown }): string[] {
  if (tool === 'Edit' || tool === 'Write' || tool === 'MultiEdit') {
    const name = typeof input.file_path === 'string' ? input.file_path.split('/').at(-1) ?? '' : ''

    return /-epic-.*\.md$/.test(name) ? [name] : []
  }
  if (tool === 'Bash' && typeof input.command === 'string') return [...new Set(input.command.match(EPIC_NAME) ?? [])]

  return []
}

const MINUTE = 60_000

/** Minutes each finished story took, for one effort or all. */
export function durations(times: Times, effort?: string): number[] {
  return Object.values(times)
    .filter(t => t.status === 'Complete' && t.started !== undefined && t.finished !== undefined && t.finished > t.started)
    .filter(t => effort === undefined || t.effort === effort)
    .map(t => ((t.finished ?? 0) - (t.started ?? 0)) / MINUTE)
}

export type Estimate = { count: number; low: number; mid: number; high: number; isSteady: boolean }

function quantile(sorted: number[], q: number): number {
  const at = (sorted.length - 1) * q
  const below = sorted[Math.floor(at)] ?? 0
  const above = sorted[Math.ceil(at)] ?? below

  return below + (above - below) * (at - Math.floor(at))
}

/** The middle half of the timings and their median, or nothing below `MIN_STORIES`. */
export function estimate(minutes: number[]): Estimate | undefined {
  if (minutes.length < MIN_STORIES) return undefined
  const sorted = [...minutes].sort((a, b) => a - b)
  const low = quantile(sorted, 0.25)
  const high = quantile(sorted, 0.75)

  return { count: sorted.length, low, mid: quantile(sorted, 0.5), high, isSteady: high <= Math.max(low, 1) * MAX_SPREAD }
}

/** The estimate for a story of this effort: from stories of the same effort when there are enough, else from all. */
export function estimateFor(times: Times, effort: string): { estimate: Estimate; basis: string } | undefined {
  const same = estimate(durations(times, effort))
  if (same !== undefined) return { estimate: same, basis: `${effort} stories` }
  const all = estimate(durations(times))

  return all === undefined ? undefined : { estimate: all, basis: 'stories' }
}

/** "45 min", "1 h 20 min". */
export function span(minutes: number): string {
  const whole = Math.max(0, Math.round(minutes))
  if (whole < 60) return `${whole} min`

  return whole % 60 === 0 ? `${whole / 60} h` : `${Math.floor(whole / 60)} h ${whole % 60} min`
}

/** "35–50 min", "50 min–1 h 20 min". */
export const range = (e: Estimate) => (Math.round(e.high) < 60 ? `${Math.round(e.low)}–${span(e.high)}` : `${span(e.low)}–${span(e.high)}`)

/** What a page row carries for a story in progress: when it started, and its typical range when that is a prediction. */
export function timingOf(times: Times, key: string): { started: number; typical: string } | undefined {
  const story = times[key]
  if (story?.started === undefined || story.status !== 'In Progress') return undefined
  const found = estimateFor(times, story.effort)

  return { started: story.started, typical: found?.estimate.isSteady === true ? range(found.estimate) : '' }
}

/**
 * A tracker's entry from its rows, keeping the date the counts last moved from the entry before. A timed
 * story in progress carries its start, and its typical range from the timing records.
 */
export function indexEntry(
  base: Pick<IndexEntry, 'root' | 'name' | 'title' | 'state' | 'artifact'>,
  items: Map<string, TrackerItem>,
  today: string,
  before: IndexEntry | undefined,
  times: Times = {},
): IndexEntry {
  const rows = [...items.values()]
  const counts = {
    done: rows.filter(r => r.status === 'Complete').length,
    total: rows.length,
    active: rows.filter(r => r.status === 'In progress').map(r => `${r.epic} ${r.story}`),
    waiting: rows.filter(r => r.status === 'Waiting on input').length,
  }
  const timings: Timing[] = rows
    .filter(r => r.status === 'In progress' && r.started !== undefined)
    .map(r => ({ story: `${r.epic} ${r.story}`, started: r.started ?? 0, typical: timingOf(times, `${r.epic} ${r.story}`)?.typical ?? '' }))
  const isSame = before !== undefined && before.done === counts.done && before.total === counts.total
    && JSON.stringify(before.active) === JSON.stringify(counts.active) && before.waiting === counts.waiting

  return { ...base, ...counts, ...(timings.length === 0 ? {} : { timings }), changed: isSame ? before.changed : today, checked: today }
}


const EFFORTS = ['low', 'medium', 'high', 'xhigh']

/**
 * What `meta/tracker` carries of the timings: how many stories are timed, and for each effort level
 * with a steady estimate its range text and bounds. One document, so a moving estimate rewrites no row.
 */
export function typicalRanges(times: Times): { timed: number; typical: Record<string, TypicalRange> } {
  const typical: Record<string, TypicalRange> = {}
  for (const effort of EFFORTS) {
    const found = estimateFor(times, effort)
    if (found?.estimate.isSteady === true) typical[effort] = { range: range(found.estimate), low: found.estimate.low, high: found.estimate.high }
  }

  return { timed: durations(times).length, typical }
}

/** What the overview pane adds after an in-progress story: how long it has run, and the steady estimate if there is one. */
export function activeNote(times: Times, key: string, now: number): string {
  const story = times[key]
  if (story?.started === undefined || story.status !== 'In Progress') return ''
  const elapsed = span((now - story.started) / MINUTE)
  const found = estimateFor(times, story.effort)

  return found?.estimate.isSteady === true ? `${elapsed} in, typically ${range(found.estimate)}` : `${elapsed} in`
}

/** The answer to "how long will it take": what the project's timings show, and where each in-progress story stands. */
export function timesReport(repo: string, times: Times, now: number): string {
  const all = durations(times)
  if (all.length === 0 && Object.values(times).every(t => t.started === undefined)) {
    return `${repo}: no story has been timed yet. A story is timed from the check that sees it go In Progress to the one that sees it Complete; stories already under way when timing began are not.`
  }
  const lines = [`${repo}: ${all.length} ${all.length === 1 ? 'story' : 'stories'} timed from In Progress to Complete.`]
  const overall = estimate(all)
  if (overall === undefined) {
    lines.push(`No estimate until ${MIN_STORIES} are timed; so far they took ${all.length === 0 ? 'nothing yet' : all.map(span).join(', ')}.`)
  } else {
    for (const [label, e] of [['All', overall], ...['low', 'medium', 'high', 'xhigh'].map(effort => [`${effort[0]?.toUpperCase()}${effort.slice(1)} effort`, estimate(durations(times, effort))])] as [string, Estimate | undefined][]) {
      if (e === undefined) continue
      lines.push(`${label}: half took ${range(e)}, median ${span(e.mid)}, of ${e.count}${e.isSteady ? '' : '; too spread out to predict from'}.`)
    }
  }
  for (const [key, story] of Object.entries(times)) {
    if (story.status !== 'In Progress') continue
    if (story.started === undefined) {
      lines.push(`${key}: in progress since before timing began; no time for it.`)
      continue
    }
    const elapsed = (now - story.started) / MINUTE
    const found = estimateFor(times, story.effort)
    let left = ''
    if (found !== undefined && found.estimate.isSteady) {
      const { low, high } = found.estimate
      left = elapsed >= high
        ? `; past the slower half of ${found.basis} (${span(high)})`
        : `; ${found.basis} typically take ${range(found.estimate)}, so about ${range({ ...found.estimate, low: Math.max(0, low - elapsed), high: high - elapsed })} left`
    }
    lines.push(`${key} (${story.effort}${story.model === undefined ? '' : `, ${story.model.toLowerCase()}`}): ${span(elapsed)} in${left}.`)
  }

  return lines.join('\n')
}
