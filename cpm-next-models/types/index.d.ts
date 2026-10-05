/** An effort level as a model request carries it. */
export type Effort = 'low' | 'medium' | 'high' | 'xhigh' | 'max' | number

/**
 * The cpm-next skill whose model and effort are held; null when nothing is held.
 * `turnId` is the turn the skill started in. `baseline` is the session's effort as first seen after that
 * turn, so a later `/effort` shows up as a difference from it and releases the held effort.
 */
export type ModelPin = { skill: string; model: string; effort?: Effort; turnId: string; baseline?: Effort } | null

/** A cpm-next skill just invoked, with its arguments and, from the Skill tool, its frontmatter model. */
export type PendingSkill = { skill: string; args: string; model?: string } | null

declare module 'claude-code' {
  interface PluginState {
    'cpm-next-models': { pin: ModelPin; pending: PendingSkill }
  }
}
