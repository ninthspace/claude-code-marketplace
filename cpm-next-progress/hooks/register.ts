import type { EngineInterface, Register } from 'claude-code'

import type { Drift, EpicFile, LiveDoc } from './progress'
import {
  MAX_NUDGES, artifactUrlIn, buildItems, dateOf, defaultBuildOrder, describeDrift, diff, fillTemplate, modelNote, parseBuildOrder, parseDocs, pendingJson,
  publishNote, turnEndNote, withArtifact,
} from './progress'

const ORDER_FILE = /^\d+-build-order\.json$/
const SPEC_FILE = /^(\d+)-spec-.*\.md$/
const PAGE_FILE = /(?:^|\/)\.claude\/cpm-next-progress\/(\d+-build-order)\.html$/
const EPIC_FILE = /-epic-.*\.md$/
const WRITING_TOOLS = new Set(['Edit', 'Write', 'MultiEdit', 'NotebookEdit', 'Bash'])
const COMMAND = 'progress-tracker'
const TRACKER_TOOL = 'publish_tracker'
const WORK_DIR = '.claude/cpm-next-progress'

type Listing = { name: string; mtimeMs: number; size: number }
type Check = { lines: string[]; drift: Drift[] }
/** When a check reads the artifact: always, when a doc changed, or also when the last check left a tracker behind. */
type When = 'now' | 'ifChanged' | 'ifChangedOrBehind'

async function findRoot($: EngineInterface): Promise<string | null> {
  const home = await $.env.get('HOME')
  let dir = await $.session.cwd()
  for (;;) {
    if (await $.fs.exists(`${dir}/docs/specifications`)) return dir
    // The climb ends at the repo's top and never enters the home folder, so docs above a project are not taken for its own.
    if (await $.fs.exists(`${dir}/.git`)) return null
    const cut = dir.lastIndexOf('/')
    if (cut <= 0) return null
    dir = dir.slice(0, cut)
    if (dir === home) return null
  }
}

async function listDocs($: EngineInterface, dir: string, pattern: RegExp): Promise<Listing[]> {
  if (!(await $.fs.exists(dir))) return []

  return (await $.fs.list(dir)).filter(e => e.kind === 'file' && pattern.test(e.name)).sort((a, b) => a.name.localeCompare(b.name))
}

const signatureOf = (...lists: Listing[][]) => lists.map(list => list.map(e => `${e.name}:${e.mtimeMs}:${e.size}`).join(',')).join('|')

async function readEpics($: EngineInterface, root: string): Promise<EpicFile[]> {
  const files: EpicFile[] = []
  for (const e of await listDocs($, `${root}/docs/epics`, EPIC_FILE)) {
    files.push({ name: e.name, text: await $.fs.read(`${root}/docs/epics/${e.name}`) })
  }

  return files
}

/** Reads one collection of the artifact. Reads need no approval from auto mode; this mod never writes. */
async function readLive($: EngineInterface, url: string, collection: string): Promise<LiveDoc[]> {
  const result = await $.tool.call({ tool: 'ArtifactData', action: 'list', url, collection, query: { limit: 1000 } })
  if ('deny' in result && result.deny !== undefined) throw new Error(result.deny)
  if (result.isError === true) throw new Error(result.text ?? 'the read failed')

  return parseDocs(result.text ?? '')
}

/** Compares one build-order file with the epic docs and the live artifact, and saves the writes that would bring them in line. */
async function checkOne($: EngineInterface, root: string, name: string): Promise<{ line: string; drift?: Drift }> {
  const order = parseBuildOrder(await $.fs.read(`${root}/docs/specifications/${name}`))
  if (order.artifact === undefined) return { line: `${name}: no tracker yet; run /${COMMAND} init ${name}` }

  const { items, missing } = buildItems(order, await readEpics($, root), dateOf(await $.clock.now()))
  const live = await readLive($, order.artifact, 'items')
  const liveMeta = (await readLive($, order.artifact, 'meta')).find(d => d.id === 'tracker')
  const writes = diff(items, { title: order.title, spec: order.spec ?? '', decisions: order.decisions ?? [] }, live, liveMeta)
  const skipped = missing.length === 0 ? '' : `; not found in the epics: ${missing.join(', ')}`
  const file = `${root}/${WORK_DIR}/${name.replace(/\.json$/, '')}.pending.json`
  if (writes.length === 0) {
    // Writes saved by an earlier check have been applied; the file must not offer them again.
    if (await $.fs.exists(file)) await $.fs.write(file, pendingJson({ url: order.artifact, writes: [] }))

    return { line: `${name}: up to date${skipped}` }
  }

  const drift: Drift = { name, url: order.artifact, file, writes }
  await $.fs.write(file, pendingJson(drift))

  return { line: `${describeDrift(drift)}${skipped}`, drift }
}

let isChecking = false

/**
 * Checks every tracker in the repository. Unless told to check now, it does nothing when the epic
 * docs and build-order files are as they were at the last check, so a tool call that changed neither
 * costs two directory listings. `ifChangedOrBehind` also checks while a tracker is known to be behind.
 */
async function checkAll($: EngineInterface, when: When): Promise<Check> {
  if (isChecking) return { lines: ['A check is already running.'], drift: [] }
  isChecking = true
  try {
    const root = await findRoot($)
    if (root === null) return { lines: ['No docs/specifications folder in this directory or above it.'], drift: [] }
    const orders = await listDocs($, `${root}/docs/specifications`, ORDER_FILE)
    if (orders.length === 0) return { lines: [`No docs/specifications/NN-build-order.json in ${root}.`], drift: [] }
    const signature = `${root}|${signatureOf(orders, await listDocs($, `${root}/docs/epics`, EPIC_FILE))}`
    const isBehind = when === 'ifChangedOrBehind' && (await $.store.get(`behind:${root}`)) === true
    if (when !== 'now' && !isBehind && signature === (await $.store.get(`checked:${root}`))) return { lines: [], drift: [] }

    const lines: string[] = []
    const drift: Drift[] = []
    let isFailed = false
    for (const order of orders) {
      try {
        const found = await checkOne($, root, order.name)
        lines.push(found.line)
        if (found.drift !== undefined) drift.push(found.drift)
      } catch (error) {
        isFailed = true
        lines.push(`${order.name}: check failed: ${error instanceof Error ? error.message : String(error)}`)
      }
    }
    // A failed check is repeated at the next change. A finished one is not repeated by a tool call,
    // drift or not; the drift it found is asked for again at the turn's end until the rows match.
    if (!isFailed) await $.store.set(`checked:${root}`, signature)
    if (!isFailed) await $.store.set(`behind:${root}`, drift.length > 0)

    return { lines, drift }
  } finally {
    isChecking = false
  }
}

/** Adds the generated-files folder to the repository's .gitignore unless a line already covers it. */
async function ignoreWorkDir($: EngineInterface, root: string): Promise<boolean> {
  const path = `${root}/.gitignore`
  const text = (await $.fs.exists(path)) ? await $.fs.read(path) : ''
  if (text.split(/\r?\n/).some(line => line.trim().replace(/^\//, '').replace(/\/$/, '') === WORK_DIR)) return false
  await $.fs.write(path, `${text}${text === '' || text.endsWith('\n') ? '' : '\n'}/${WORK_DIR}\n`)

  return true
}

/**
 * The build-order file a spec number, spec file or build-order file names, writing a first one from
 * the spec's epics when none exists yet.
 */
async function orderFileFor($: EngineInterface, root: string, arg: string): Promise<{ name: string; created?: string } | string> {
  const name = arg.split('/').at(-1) ?? arg
  if (ORDER_FILE.test(name)) {
    return (await $.fs.exists(`${root}/docs/specifications/${name}`)) ? { name } : `${root}/docs/specifications/${name} does not exist.`
  }
  const number = /^\d+$/.test(name) ? name.padStart(2, '0') : SPEC_FILE.exec(name)?.[1]
  if (number === undefined) return `Name a spec or a build-order file: /${COMMAND} 01, or /${COMMAND} 01-build-order.json`

  const orderName = `${number}-build-order.json`
  if (await $.fs.exists(`${root}/docs/specifications/${orderName}`)) return { name: orderName }
  const spec = (await listDocs($, `${root}/docs/specifications`, SPEC_FILE)).find(e => SPEC_FILE.exec(e.name)?.[1] === number)
  if (spec === undefined) return `No docs/specifications/${number}-spec-*.md in ${root}.`
  const order = defaultBuildOrder({ name: spec.name, text: await $.fs.read(`${root}/docs/specifications/${spec.name}`) }, await readEpics($, root))
  if (order.phases.length === 0) return `No stories in docs/epics/${number}-*-epic-*.md yet; plan the epics for ${spec.name} first.`
  await $.fs.write(`${root}/docs/specifications/${orderName}`, `${JSON.stringify(order, null, 2)}\n`)
  const stories = order.phases.reduce((n, p) => n + p.items.length, 0)

  return { name: orderName, created: `${stories} ${stories === 1 ? 'story' : 'stories'} in ${order.phases.length} ${order.phases.length === 1 ? 'phase' : 'phases'}, one per epic` }
}

/**
 * Writes the page for a spec's tracker and names it as `page`, to be published. Publishing is left
 * to the model, which is the one the permission system evaluates.
 */
async function prepare($: EngineInterface, arg: string): Promise<{ text: string; page?: string }> {
  const root = await findRoot($)
  if (root === null) return { text: 'No docs/specifications folder in this directory or above it.' }
  const found = await orderFileFor($, root, arg.trim())
  if (typeof found === 'string') return { text: found }
  const { name } = found
  const order = parseBuildOrder(await $.fs.read(`${root}/docs/specifications/${name}`))
  if (order.artifact !== undefined) return { text: `${name} already has a tracker: ${order.artifact}` }

  const repo = root.split('/').filter(Boolean).at(-1) ?? root
  const page = `${root}/${WORK_DIR}/${name.replace(/\.json$/, '')}.html`
  await $.fs.write(page, fillTemplate(await $.fs.read(`${$.plugin.root}/page/tracker.html`), order, repo))
  const isIgnored = await ignoreWorkDir($, root)

  const text = [
    found.created === undefined ? `Using docs/specifications/${name}.` : `Wrote docs/specifications/${name}: ${found.created}. Edit it to change the order or phases.`,
    `Page written to ${page}.${isIgnored ? ` Added /${WORK_DIR} to .gitignore.` : ''}`,
  ].join('\n')

  return { text, page }
}

/** Prepares a spec's tracker and, when a page was written, asks the model to publish it in a turn of its own. */
async function prepareAndPublish($: EngineInterface, arg: string): Promise<string> {
  const { text, page } = await prepare($, arg)
  if (page === undefined) return text
  void $.prompt.submit({ text: publishNote(page) }).catch(() => undefined)

  return `${text}\nClaude is now asked to publish it. The link is saved to the build-order file when it publishes, and Claude is then given the rows to write.`
}

/** The number of the repository's only spec, for a request that names none. */
async function soleSpec($: EngineInterface): Promise<{ number: string } | string> {
  const root = await findRoot($)
  if (root === null) return 'No docs/specifications folder in this directory or above it.'
  const numbers = (await listDocs($, `${root}/docs/specifications`, SPEC_FILE)).map(e => SPEC_FILE.exec(e.name)?.[1] ?? '')
  if (numbers.length === 1 && numbers[0] !== undefined) return { number: numbers[0] }

  return numbers.length === 0 ? `No docs/specifications/NN-spec-*.md in ${root}.` : `Name the spec: ${numbers.join(', ')}.`
}

/** Answers the model's own request for a tracker: the page is written, and the result says how to publish it. */
async function prepareForModel($: EngineInterface, spec: unknown): Promise<string> {
  const named = typeof spec === 'string' && spec.trim() !== '' ? { number: spec } : await soleSpec($)
  if (typeof named === 'string') return named
  const { text, page } = await prepare($, named.number)

  return page === undefined ? text : `${text}\n${publishNote(page)}`
}

/**
 * After the model publishes a tracker page, saves the link to its build-order file and returns the
 * note for the first rows. A republish of a page that already has a link changes nothing.
 */
async function savePublished($: EngineInterface, filePath: unknown, resultText: string): Promise<string | null> {
  if (typeof filePath !== 'string') return null
  const base = PAGE_FILE.exec(filePath)?.[1]
  const url = artifactUrlIn(resultText)
  const root = await findRoot($)
  if (base === undefined || url === undefined || root === null) return null
  const path = `${root}/docs/specifications/${base}.json`
  if (!(await $.fs.exists(path))) return null
  const text = await $.fs.read(path)
  if (parseBuildOrder(text).artifact !== undefined) return null
  await $.fs.write(path, withArtifact(text, url))

  const { drift } = await checkAll($, 'now')

  return [`Saved the tracker link to docs/specifications/${base}.json.`, ...(drift.length > 0 ? [modelNote(drift)] : [])].join(' ')
}

let nudges = 0
// The writes for the prompt on its way in; the prompt.submit hook attaches them where the person does not see them.
let nudgeContext: string | null = null

/**
 * At the end of a turn, asks for the writes a tracker still lacks as a prompt of its own. A note on
 * a tool result is easily passed over in the middle of a task; this one is the task.
 */
async function nudge($: EngineInterface) {
  const { drift } = await checkAll($, 'ifChangedOrBehind')
  if (drift.length === 0) {
    nudges = 0

    return
  }
  // The same writes are not asked for without end: refused writes are left to the person.
  nudges += 1
  if (nudges > MAX_NUDGES) {
    if (nudges === MAX_NUDGES + 1) $.ui.toast(`Progress tracker still out of date after ${MAX_NUDGES} reminders; run /${COMMAND}`)

    return
  }
  const note = turnEndNote(drift)
  nudgeContext = note.context
  await $.prompt.submit({ text: note.text })
}

let isStarted = false

async function start($: EngineInterface) {
  if (isStarted) return
  isStarted = true
  await $.command.register({ name: COMMAND, description: 'Check the cpm-next progress trackers against the epic docs, or name a spec ("01") to prepare its tracker' })
  await $.tool.register({
    name: TRACKER_TOOL,
    description: 'Prepares the cpm-next progress tracker for a spec: the claude.ai page that shows the build order and status of its epics and stories. Call this when asked to make, publish or share a progress tracker or progress page for planned work, and never write such a page by hand. It writes the page from the plugin\'s template and answers with how to publish it; the rows are then kept in step with the epic docs.',
    inputSchema: {
      type: 'object',
      properties: { spec: { type: 'string', description: 'The spec\'s number, e.g. "01". May be left out when the repository has one spec.' } },
    },
    isDeferred: false,
  })
  const { lines, drift } = await checkAll($, 'ifChangedOrBehind')
  if (drift.length > 0) $.ui.toast(`Progress tracker out of date: ${lines.join(' · ')}`)
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await start($).catch(() => undefined)

    return next(e)
  })

  // A plugin loaded by /reload-plugins sees no session.start; start on the first prompt.
  on('prompt.submit', async ($, e, next) => {
    await start($).catch(() => undefined)
    // A prompt from the person starts the count of reminders afresh.
    if (e.origin.kind !== 'plugin') nudges = 0
    if (e.origin.kind === 'plugin' && e.origin.name === $.plugin.name && nudgeContext !== null) {
      const context = [...(e.context ?? []), nudgeContext]
      nudgeContext = null

      return next({ ...e, context })
    }

    return next(e)
  })

  on('command.run', { command: COMMAND }, async ($, e) => {
    const [verb = '', ...rest] = e.args.trim().split(/\s+/)
    if (verb === 'init') return { text: await prepareAndPublish($, rest.join(' ')) }
    if (verb !== '') return { text: await prepareAndPublish($, verb) }
    // With no tracker to check and one spec to make one for, the bare command makes it.
    const root = await findRoot($)
    const sole = root !== null && (await listDocs($, `${root}/docs/specifications`, ORDER_FILE)).length === 0 ? await soleSpec($) : ''
    if (typeof sole !== 'string') return { text: await prepareAndPublish($, sole.number) }
    const { lines } = await checkAll($, 'now')

    return { text: lines.join('\n') }
  })

  // When the model publishes a tracker page, save its link and hand over the first rows.
  on('tool.call', { tool: 'Artifact' }, async ($, e, next) => {
    const result = await next(e)
    if (result.deny !== undefined || result.isError === true || (e.action ?? 'publish') !== 'publish' || e.asset === true) return result
    const note = await savePublished($, e.file_path, result.text ?? '').catch(() => null)
    if (note === null) return result
    $.ui.toast(note.split('. ')[0] ?? note)

    return { ...result, context: [...(result.context ?? []), note] }
  })

  // When the main loop's turn ends with a tracker behind, start a turn that brings it in line.
  on('turn.complete', async ($, e, next) => {
    const result = await next(e)
    if (e.agentId === undefined && e.reason === 'answer') void nudge($).catch(() => undefined)

    return result
  })

  // After a tool call that writes, check the trackers if an epic doc or build-order file changed, and
  // tell the model what to write. The tracker is only ever written by the model's own ArtifactData calls.
  // The mod's own tool is answered here too: its name is not in the typed tool list a matcher takes.
  on('tool.call', async ($, e, next) => {
    if (String(e.tool) === `mcp__${$.plugin.name}__${TRACKER_TOOL}`) {
      try {
        return { result: await prepareForModel($, (e as unknown as { spec?: unknown }).spec) }
      } catch {
        return { deny: `${TRACKER_TOOL} failed; run /${COMMAND} with the spec's number instead.` }
      }
    }
    const result = await next(e)
    if (!WRITING_TOOLS.has(String(e.tool)) || result.deny !== undefined || result.isError === true) return result

    const found = await checkAll($, 'ifChanged').catch(() => null)
    if (found === null || found.drift.length === 0) return result
    $.ui.toast(`Progress tracker out of date: ${found.lines.join(' · ')}`)

    return { ...result, context: [...(result.context ?? []), modelNote(found.drift)] }
  })
}
