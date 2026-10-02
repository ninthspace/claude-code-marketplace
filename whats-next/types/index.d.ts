export type WorkStatus = 'Pending' | 'In Progress' | 'Complete' | 'Superseded' | 'Withdrawn'

export type NextTask = { id: string; title: string; status: WorkStatus }

export type NextStory = {
  epicId: string
  epicTitle: string
  number: number
  title: string
  status: WorkStatus
  /** True when nothing it depends on is outstanding right now. */
  isReady: boolean
  /** Dependencies not yet Complete, as written in the epic doc. */
  waitsOn: string[]
  tasksDone: number
  tasksTotal: number
  nextTask: NextTask | null
}

export type NextEpic = {
  id: string
  title: string
  status: WorkStatus
  storiesDone: number
  storiesTotal: number
  waitsOn: string[]
}

export type NextPlan = {
  root: string
  repo: string
  /** Epics with work left, in number order. */
  epics: NextEpic[]
  /** Every story left, in recommended order of execution. */
  order: NextStory[]
  signature: string
}

export type NextNote = { root: string; signature: string; text: string; at: number }

declare module 'claude-code' {
  interface PluginState {
    'whats-next': {
      plan: NextPlan | null
      note: NextNote | null
      isNoteBusy: boolean
      noteError: string | null
    }
  }
}
