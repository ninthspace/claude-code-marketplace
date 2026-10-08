import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { ModelPin, PendingSkill } from '../types'
import {
  effortFor, effortStep, floorFor, isHeldSkill, isPersonsSwitch, isStoryEffort, overrideFor, parseFrontmatter,
  pickInstall, resolveModel, skillName, slashSkill, statusText, storyStep,
} from './pin'

const STORY_TOOL = 'set_story_effort'

const pin = atom({ plugin: 'cpm-next-models', key: 'pin' } as const, null)
const pending = atom({ plugin: 'cpm-next-models', key: 'pending' } as const, null)

async function setPin($: EngineInterface, value: ModelPin) {
  await update($, pin, () => value)
}

async function release($: EngineInterface) {
  await update($, pending, () => null)
  await setPin($, null)
}

// A skill is seen by up to three events (the typed prompt, the expansion, the Skill tool); the first one
// to name it sets the pending skill and the rest leave it be.
async function capture($: EngineInterface, name: string, args: string) {
  const skill = skillName(name)
  if (!isHeldSkill(skill)) return
  const waiting: PendingSkill = await read($, pending)
  if (waiting?.skill === skill) return
  await update($, pending, () => ({ skill, args }))
}

// The engine doesn't pass a skill's frontmatter effort on to the request, and passes its model only in the
// Skill tool's result, so both are read from the installed SKILL.md.
async function frontmatterOf($: EngineInterface, skill: string) {
  try {
    const home = await $.env.get('HOME')
    const [plugin, name] = skill.split(':')
    const installed = JSON.parse(await $.fs.read(`${home}/.claude/plugins/installed_plugins.json`)) as {
      plugins?: Record<string, { scope?: string; projectPath?: string; installPath: string }[]>
    }
    const key = Object.keys(installed.plugins ?? {}).find(k => k.startsWith(`${plugin}@`))
    const path = pickInstall(installed.plugins?.[key ?? ''] ?? [], await $.session.root())

    return path === undefined ? {} : parseFrontmatter(await $.fs.read(`${path}/skills/${name}/SKILL.md`))
  } catch {
    return {}
  }
}

export const register: Register = on => {
  on('prompt.submit', async ($, e, next) => {
    const typed = slashSkill(e.text)
    if (typed !== null) await capture($, typed.skill, typed.args)

    return next(e)
  })

  on('classic.UserPromptExpansion', async ($, e, next) => {
    await capture($, e.command_name, e.command_args)

    return next(e)
  })

  on('skill.prompt', async ($, e, next) => {
    if (isHeldSkill(skillName(e.skill))) await capture($, e.skill, '')
    else await release($)

    return next(e)
  })

  on('tool.call', { tool: 'Skill' }, async ($, e, next) => {
    await capture($, e.skill, e.args ?? '')

    return next(e)
  })

  // Main loop only: subagents keep the model and effort their spawn chose.
  on('turn.step', async function* ($, e, next) {
    if (e.agentId !== undefined) return yield* next(e)

    const waiting = await read($, pending)
    if (waiting !== null) {
      await update($, pending, () => null)
      const found = await frontmatterOf($, waiting.skill)
      const model = resolveModel(found.model, e.model)
      const effort = effortFor(waiting.skill, waiting.args, found.effort ?? e.effort)
      const floor = floorFor(waiting.skill, waiting.args)
      await setPin($, { skill: waiting.skill, model, effort, turnId: e.turnId, ...(floor === undefined ? {} : { floor }) })
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
    await $.tool.register({
      name: STORY_TOOL,
      description: 'Sets the effort the current /cpm-next:do run builds at, for the story it is starting or the fix it is making. Changes nothing outside a do run, never goes below the run\'s floor, and leaves an effort the person set with /effort alone.',
      inputSchema: {
        type: 'object',
        properties: {
          effort: { type: 'string', enum: ['low', 'medium', 'high', 'xhigh'] },
          story: { type: 'string', description: 'The story number, e.g. "3"' },
        },
        required: ['effort'],
      },
    })
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

  // Unfiltered: a registered tool's name is not in the typed tool list until the mod has reloaded once.
  on('tool.call', async ($, e, next) => {
    if (String(e.tool) !== `mcp__cpm-next-models__${STORY_TOOL}`) return next(e)
    const { effort, story } = e as unknown as { effort?: unknown; story?: unknown }
    if (!isStoryEffort(effort)) return { deny: 'effort must be one of low, medium, high, xhigh.' }
    const held = await read($, pin)
    const step = storyStep(held, effort, typeof story === 'string' && story !== '' ? story : undefined)
    if (step.pin !== held) await setPin($, step.pin)

    return { result: step.text }
  }).catch(($, e, next) => (next.called ? next(e) : { deny: `${STORY_TOOL} failed; build at the current effort.` }))

  on('command.run', { command: 'cpm-models' }, async ($, e) => {
    if (e.args.trim() === 'off') {
      await release($)
      return { text: 'Released: turns now run on the session model.' }
    }
    const held = await read($, pin)

    return { text: held === null ? 'Nothing held: turns run on the session model.' : `Holding ${held.model}${held.effort === undefined ? '' : ` at ${held.effort} effort`} for ${held.skill}. "/cpm-models off" releases it.` }
  })
}
