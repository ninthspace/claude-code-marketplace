import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { ModelPin } from '../types'
import { effortFor, effortStep, isHeldSkill, isPersonsSwitch, overrideFor, skillName, statusText } from './pin'

const pin = atom({ plugin: 'cpm-next-models', key: 'pin' } as const, null)
const pending = atom({ plugin: 'cpm-next-models', key: 'pending' } as const, null)

// The status line command can't see a per-request model, so the held one is written where it can read it:
// ~/.claude/cpm-next-models/{session id}, holding the footer label, or empty when nothing is held.
async function setPin($: EngineInterface, value: ModelPin) {
  await update($, pin, () => value)
  const home = await $.env.get('HOME')
  if (home !== undefined) await $.fs.write(`${home}/.claude/cpm-next-models/${await $.session.id()}`, statusText(value) ?? '')
}

async function release($: EngineInterface) {
  await update($, pending, () => null)
  await setPin($, null)
}

// The arguments of the last skill invoked by slash command; the expansion hook and `skill.prompt` may
// arrive in either order, so whichever comes second joins them.
let slashArgs: { skill: string; args: string } | null = null

export const register: Register = on => {
  on('classic.UserPromptExpansion', async ($, e, next) => {
    const skill = skillName(e.command_name)
    if (isHeldSkill(skill)) {
      slashArgs = { skill, args: e.command_args }
      const waiting = await read($, pending)
      if (waiting !== null && waiting.skill === skill) await update($, pending, () => ({ ...waiting, args: e.command_args }))
    }

    return next(e)
  })

  // A skill's frontmatter model and effort apply from its expansion to the end of that turn. Remember which
  // skill expanded; the next main-loop request carries what the engine resolved for it.
  on('skill.prompt', async ($, e, next) => {
    const skill = skillName(e.skill)
    if (isHeldSkill(skill)) {
      const waiting = await read($, pending)
      if (waiting?.skill !== skill) await update($, pending, () => ({ skill, args: slashArgs?.skill === skill ? slashArgs.args : '' }))
    } else {
      await release($)
    }

    return next(e)
  })

  // The Skill tool carries the arguments, and its result reports the frontmatter model when one took effect.
  on('tool.call', { tool: 'Skill' }, async ($, e, next) => {
    const skill = skillName(e.skill)
    if (isHeldSkill(skill)) await update($, pending, () => ({ skill, args: e.args ?? '' }))
    const ran = await next(e)
    if (ran.deny !== undefined || ran.isError === true) return ran
    const model = (ran.result as { model?: string }).model
    const waiting = await read($, pending)
    if (model !== undefined && waiting !== null && waiting.skill === skill) await update($, pending, () => ({ ...waiting, model }))

    return ran
  })

  // Main loop only: subagents keep the model and effort their spawn chose.
  on('turn.step', async function* ($, e, next) {
    if (e.agentId !== undefined) return yield* next(e)

    const waiting = await read($, pending)
    if (waiting !== null) {
      await update($, pending, () => null)
      const model = waiting.model ?? e.model
      const effort = effortFor(waiting.skill, waiting.args, e.effort)
      await setPin($, { skill: waiting.skill, model, effort, turnId: e.turnId })
      return yield* next({ ...e, model, effort })
    }

    const held = await read($, pin)
    const stepped = effortStep(held, e.turnId, e.effort)
    if (stepped.pin !== held) await setPin($, stepped.pin)
    const model = overrideFor(held, e.model) ?? e.model

    return yield* next({ ...e, model, effort: stepped.effort })
  })

  on('classic.PostModelSwitch', async ($, e, next) => {
    if (isPersonsSwitch(e.source)) await release($)

    return next(e)
  })

  on('session.end', async ($, e, next) => {
    if (e.reason === 'clear') await release($)

    return next(e)
  })

  on('session.start', async ($, e, next) => {
    await $.command.register({ name: 'cpm-models', description: 'Show which cpm-next skill model and effort are held, or "off" to release them' })
    // A status entry pinned by an earlier load outlives a reload; this mod draws in the footer instead.
    $.ui.status(undefined)

    return next(e)
  })

  // Drawn as one of the footer's mode labels, beside the session model that the status line keeps showing.
  on('ui.render', { component: 'SessionMode' }, async ($, e, next) => {
    const label = statusText(await read($, pin))
    if (label === undefined) return next(e)

    return next({ ...e, props: { ...e.props, modes: [...e.props.modes, label] } })
  })

  on('command.run', { command: 'cpm-models' }, async ($, e) => {
    if (e.args.trim() === 'off') {
      await release($)
      return { text: 'Released: turns now run on the session model.' }
    }
    const held = await read($, pin)

    return { text: held === null ? 'Nothing held: turns run on the session model.' : `Holding ${held.model}${held.effort === undefined ? '' : ` at ${held.effort} effort`} for ${held.skill}. "/cpm-models off" releases it.` }
  })
}
