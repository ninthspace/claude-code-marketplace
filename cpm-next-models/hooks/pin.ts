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
  return skillName(skill) === 'cpm-next:do' && /^\s*all\b/i.test(args) ? 'high' : resolved
}

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

/** The footer label, e.g. "cpm-next:do · sonnet · high"; undefined when nothing is held. */
export function statusText(pin: ModelPin): string | undefined {
  if (pin === null) return undefined
  const effort = pin.effort === undefined ? '' : ` · ${pin.effort}`

  return `${pin.skill} · ${familyOf(pin.model)}${effort}`
}
