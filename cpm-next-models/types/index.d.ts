/** The cpm-next skill whose model is held, and that model as the engine resolved it; null when nothing is held. */
export type ModelPin = { skill: string; model: string } | null

/** A cpm-next skill whose prompt has just been expanded; its model is read from the next main-loop request. */
export type PendingSkill = string | null

declare module 'claude-code' {
  interface PluginState {
    'cpm-next-models': { pin: ModelPin; pending: PendingSkill }
  }
}
