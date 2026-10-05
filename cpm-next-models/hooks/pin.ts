import type { ModelPin } from '../types'

const PREFIX = 'cpm-next:'

/** Whether a skill's model is held across turns: every cpm-next skill, so one without a model releases the last one's. */
export function isHeldSkill(skill: string): boolean {
  return skill.startsWith(PREFIX)
}

/** The model a main-loop request should be sent on instead of `stepModel`, or undefined to leave it. */
export function overrideFor(pin: ModelPin, stepModel: string): string | undefined {
  return pin !== null && pin.model !== stepModel ? pin.model : undefined
}

/** Whether a model switch is the person's own choice, which releases the hold; a fallback or resume does not. */
export function isPersonsSwitch(source: string): boolean {
  return source === 'command' || source === 'picker' || source === 'sdk'
}

/** `claude-sonnet-5-5` → `sonnet`; an id with no family name is shown whole. */
export function familyOf(model: string): string {
  return /opus|sonnet|haiku|fable/.exec(model)?.[0] ?? model
}

/** The footer label, e.g. "cpm-next:do · sonnet"; undefined when nothing is held. */
export function statusText(pin: ModelPin): string | undefined {
  return pin === null ? undefined : `${pin.skill} · ${familyOf(pin.model)}`
}
