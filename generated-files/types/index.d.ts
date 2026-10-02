export type GeneratedFile = {
  path: string
  name: string
  /** The folder, with the home directory shown as ~. */
  folder: string
  at: number
  via: 'Write' | 'Edit' | 'Bash'
}

declare module 'claude-code' {
  interface PluginState {
    'generated-files': { files: GeneratedFile[] }
  }
}
