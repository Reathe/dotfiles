import type { JjFile } from '../types'

// One drawing holds 100000 characters, and a diff cut mid-hunk does not parse: cut between hunks.
const FILE_CHARS = 40000

export function parseGitDiff(text: string): JjFile[] {
  return text
    .split(/^diff --git /m)
    .filter(chunk => chunk.trim() !== '')
    .map(chunk => {
      const lines = chunk.split('\n')
      const has = (prefix: string) => lines.some(l => l.startsWith(prefix))
      const from = lines.find(l => l.startsWith('rename from '))?.slice(12)
      const to = lines.find(l => l.startsWith('rename to '))?.slice(10)
      const status = has('new file mode') ? 'A' : has('deleted file mode') ? 'D' : from !== undefined ? 'R' : 'M'
      const path = from !== undefined && to !== undefined ? `${from} → ${to}` : (/ b\/(.*)$/.exec(lines[0] ?? '')?.[1] ?? '')

      const first = lines.findIndex(l => l.startsWith('@@'))
      const body = first === -1 ? [] : lines.slice(first)
      let hunks = ''
      let isCut = false
      for (const hunk of body.join('\n').split(/^(?=@@)/m)) {
        if (hunks.length + hunk.length > FILE_CHARS) {
          isCut = true
          break
        }
        hunks += hunk
      }
      // A first hunk past the cap is cut at a line: drawn as plain code, but still shown.
      if (hunks === '' && isCut) hunks = body.join('\n').slice(0, FILE_CHARS).replace(/\n[^\n]*$/, '')
      return {
        path,
        status,
        added: body.filter(l => l.startsWith('+')).length,
        removed: body.filter(l => l.startsWith('-')).length,
        hunks: hunks.trimEnd(),
        isCut,
      }
    })
}
