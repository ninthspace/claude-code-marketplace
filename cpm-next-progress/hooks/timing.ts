// Story timings: when each story went In Progress and Complete, read from the epic docs as checks see
// them change, and the estimates those timings support once there are enough of them.

import type { EpicFile, WorkStatus } from './progress'
import { parseEpic, storyStatus } from './progress'

/** One story's record. `started` and `finished` are epoch ms, set only when the change was seen happen. */
export type StoryTime = { status: WorkStatus; effort: string; started?: number; finished?: number }

/** A project's records, keyed as the tracker names stories: "04-01 S5". */
export type Times = Record<string, StoryTime>

export type Observed = { key: string; status: WorkStatus; effort: string; at: number }

/** Finished stories needed before an estimate is given. */
export const MIN_STORIES = 10
/** How many times the quick quartile the slow one may be for an estimate still to count as a prediction. */
export const MAX_SPREAD = 3

const effortOf = (raw: string) => (raw === 'low' || raw === 'high' || raw === 'xhigh' ? raw : 'medium')

/** Each story in the epic docs, stamped with the time its doc was last written. */
export function observe(files: (EpicFile & { mtimeMs: number })[]): Observed[] {
  return files.flatMap(file => {
    const epic = parseEpic(file)

    return epic.stories.map(story => ({
      key: `${epic.short} S${story.number}`,
      status: storyStatus(story, epic),
      effort: effortOf(story.effort),
      at: file.mtimeMs,
    }))
  })
}

/**
 * Folds a check's observations into the records. A start is taken only when a story seen Pending is
 * next seen In Progress, and a finish only when one seen In Progress with a start is next seen
 * Complete, so a story first seen part-way, or one that moved twice between checks, gets no time.
 */
export function recordTimes(before: Times, observed: Observed[]): Times {
  const times: Times = { ...before }
  for (const { key, status, effort, at } of observed) {
    const prior = times[key]
    if (prior === undefined) {
      times[key] = { status, effort }
      continue
    }
    const next: StoryTime = { ...prior, status, effort }
    if (prior.status === 'Pending' && status === 'In Progress') next.started = at
    if (prior.status === 'In Progress' && status === 'Complete' && prior.started !== undefined) next.finished = at
    // A story reopened goes on from its first start.
    if (status === 'In Progress') delete next.finished
    times[key] = next
  }

  return times
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
const range = (e: Estimate) => (Math.round(e.high) < 60 ? `${Math.round(e.low)}–${span(e.high)}` : `${span(e.low)}–${span(e.high)}`)

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
    lines.push(`${key} (${story.effort}): ${span(elapsed)} in${left}.`)
  }

  return lines.join('\n')
}
