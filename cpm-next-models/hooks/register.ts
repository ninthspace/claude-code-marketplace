import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { ModelPin } from '../types'
import { isHeldSkill, isPersonsSwitch, overrideFor, statusText } from './pin'

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

export const register: Register = on => {
  // A skill's frontmatter model applies from its expansion to the end of that turn. Remember which
  // skill expanded; the next main-loop request carries the model the engine resolved for it.
  on('skill.prompt', async ($, e, next) => {
    if (isHeldSkill(e.skill)) await update($, pending, () => e.skill)
    else await release($)

    return next(e)
  })

  // The Skill tool reports the frontmatter model outright, when one took effect.
  on('tool.call', { tool: 'Skill' }, async ($, e, next) => {
    const ran = await next(e)
    if (ran.deny !== undefined || ran.isError === true) return ran
    const result = ran.result as { commandName?: string; model?: string }
    if (result.commandName !== undefined && result.model !== undefined && isHeldSkill(result.commandName)) {
      await update($, pending, () => null)
      await setPin($, { skill: result.commandName, model: result.model })
    }

    return ran
  })

  // Main loop only: subagents keep the model their spawn chose.
  on('turn.step', async function* ($, e, next) {
    if (e.agentId !== undefined) return yield* next(e)

    const skill = await read($, pending)
    if (skill !== null) {
      await update($, pending, () => null)
      await setPin($, { skill, model: e.model })
      return yield* next(e)
    }

    const model = overrideFor(await read($, pin), e.model)
    return yield* next(model === undefined ? e : { ...e, model })
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
    await $.command.register({ name: 'cpm-models', description: 'Show which cpm-next skill model is held, or "off" to release it' })
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

    return { text: held === null ? 'Nothing held: turns run on the session model.' : `Holding ${held.model} for ${held.skill}. "/cpm-models off" releases it.` }
  })
}
