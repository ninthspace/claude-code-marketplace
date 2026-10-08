import type { Effort, ModelPin } from '../types'

const PREFIX = 'cpm-next:'

/** `/cpm-next:do` → `cpm-next:do`: slash expansions and the Skill tool spell the name differently. */
export function skillName(name: string): string {
  return name.replace(/^\//, '')
}

/** Whether a skill's model is held across turns: every cpm-next skill, so one without a model releases the last one's. */
export function isHeldSkill(skill: string): boolean {
  return skillName(skill).startsWith(PREFIX)
}

/**
 * The effort to hold for a skill: `high` for an unattended `do all` run, where Sonnet tends to stop and
 * check in at `medium`; otherwise the frontmatter's, as the engine resolved it for the skill's first request.
 */
export function effortFor(skill: string, args: string, resolved: Effort | undefined): Effort | undefined {
  return floorFor(skill, args) ?? resolved
}

/** The lowest effort a story may set in this run: `high` for `do all`, so a `low` story can't bring back the check-ins. */
export function floorFor(skill: string, args: string): Effort | undefined {
  return skillName(skill) === 'cpm-next:do' && /^\s*all\b/i.test(args) ? 'high' : undefined
}

const STORY_LEVELS = ['low', 'medium', 'high', 'xhigh'] as const

/** Whether a value is an effort a story may set: one of the four build levels. */
export function isStoryEffort(value: unknown): value is (typeof STORY_LEVELS)[number] {
  return typeof value === 'string' && (STORY_LEVELS as readonly string[]).includes(value)
}

/**
 * The pin after `do` sets a story's effort, and what the tool tells the model. Only a `do` run's held effort
 * changes, never below its floor; a person's `/effort` (which clears the held effort) is left to stand.
 */
export function storyStep(pin: ModelPin, effort: Effort, story: string | undefined): { pin: ModelPin; text: string } {
  if (pin === null || pin.skill !== 'cpm-next:do') return { pin, text: 'No /cpm-next:do run is held; the session effort applies.' }
  if (pin.effort === undefined) return { pin, text: 'The person set /effort during this run; their effort applies.' }
  const floor = pin.floor
  const level = floor !== undefined && rank(effort) < rank(floor) ? floor : effort
  const next = { ...pin, effort: level, ...(story === undefined ? {} : { story }) }
  const raised = level === effort ? '' : ` (raised from ${effort}: this run's floor is ${floor})`

  return { pin: next, text: `Effort ${level}${raised}${story === undefined ? '' : ` for story ${story}`}.` }
}

const rank = (effort: Effort) => typeof effort === 'number' ? effort : LEVELS.indexOf(effort)

/** The model a main-loop request should be sent on instead of `stepModel`, or undefined to leave it. */
export function overrideFor(pin: ModelPin, stepModel: string): string | undefined {
  return pin !== null && pin.model !== stepModel ? pin.model : undefined
}

/**
 * The effort a main-loop request should carry, and the pin as it stands afterwards. Inside the skill's own
 * turn the held effort applies. On the first request of a later turn the session's effort is recorded as the
 * baseline; a later request whose effort differs from it means the person ran `/effort`, which wins.
 */
export function effortStep(pin: ModelPin, turnId: string, stepEffort: Effort | undefined): { effort: Effort | undefined; pin: ModelPin } {
  if (pin === null || pin.effort === undefined) return { effort: stepEffort, pin }
  if (turnId === pin.turnId) return { effort: pin.effort, pin }
  if (pin.baseline === undefined) return { effort: pin.effort, pin: stepEffort === undefined ? pin : { ...pin, baseline: stepEffort } }
  if (stepEffort !== pin.baseline) return { effort: stepEffort, pin: { ...pin, effort: undefined } }

  return { effort: pin.effort, pin }
}

/** Whether a model switch is the person's own choice, which releases the hold; a fallback or resume does not. */
export function isPersonsSwitch(source: string): boolean {
  return source === 'command' || source === 'picker' || source === 'sdk'
}

/** `claude-sonnet-5-5` → `sonnet`; an id with no family name is shown whole. */
export function familyOf(model: string): string {
  return /opus|sonnet|haiku|fable/.exec(model)?.[0] ?? model
}

/** The footer label, e.g. "cpm-next:do · story 3 · sonnet · high"; undefined when nothing is held. */
export function statusText(pin: ModelPin): string | undefined {
  if (pin === null) return undefined
  const story = pin.story === undefined ? '' : ` · story ${pin.story}`
  const effort = pin.effort === undefined ? '' : ` · ${pin.effort}`

  return `${pin.skill}${story} · ${familyOf(pin.model)}${effort}`
}

const LEVELS = ['low', 'medium', 'high', 'xhigh', 'max']

/** The `model` and `effort` lines of a SKILL.md's frontmatter; absent keys, or an unknown effort, are left out. */
export function parseFrontmatter(text: string): { model?: string; effort?: Effort } {
  const block = /^---\r?\n([\s\S]*?)\r?\n---/.exec(text)?.[1]
  if (block === undefined) return {}
  const get = (key: string) => new RegExp(`^${key}:\\s*(\\S+)\\s*$`, 'm').exec(block)?.[1]
  const effort = get('effort')

  return { model: get('model'), effort: LEVELS.includes(effort ?? '') ? (effort as Effort) : undefined }
}

/** `/cpm-next:do all` → `{ skill: 'cpm-next:do', args: 'all' }`; null for anything else a person types. */
export function slashSkill(text: string): { skill: string; args: string } | null {
  const found = /^\/(cpm-next:[\w-]+)(?:\s+([\s\S]*))?$/.exec(text.trim())

  return found === null ? null : { skill: found[1] ?? '', args: found[2] ?? '' }
}

/** A frontmatter model as a request can name it: a bare family (`sonnet`) takes the session model's version. */
export function resolveModel(requested: string | undefined, sessionModel: string): string {
  if (requested === undefined || requested === 'inherit') return sessionModel
  if (!/^(opus|sonnet|haiku|fable)$/.test(requested)) return requested

  return sessionModel.replace(/opus|sonnet|haiku|fable/, requested)
}

/** Which install of a plugin the session runs: the project's own, else the user-scope one, else the first. */
export function pickInstall(installs: { scope?: string; projectPath?: string; installPath: string }[], root: string): string | undefined {
  return (installs.find(i => i.projectPath === root) ?? installs.find(i => i.scope === 'user') ?? installs[0])?.installPath
}
