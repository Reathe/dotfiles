export type JjCommit = { id: string; isCurrent: boolean; title: string; age: string }
export type JjFile = { path: string; status: 'A' | 'D' | 'M' | 'R'; added: number; removed: number; hunks: string; isCut: boolean }
export type JjDetail = { id: string; commitId: string; author: string; age: string; description: string; files: JjFile[]; error: string }
export type JjPane = { commits: JjCommit[]; error: string; expanded: string; detail?: JjDetail; openFile: string }

declare module 'claude-code' {
  interface PluginState {
    'jj-log': { pane: JjPane }
  }
}
