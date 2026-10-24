import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import { parseGitDiff } from './diff'
import type { JjCommit, JjFile, JjPane } from '../types'

const PANE = 'jj-log'
const TITLE = 'jj commits'
const EMPTY: JjPane = { commits: [], error: '', expanded: '', openFile: '' }
const pane = atom({ plugin: 'jj-log', key: 'pane' } as const, EMPTY)
const LOG_TEMPLATE = 'change_id.short(8) ++ "\\t" ++ if(current_working_copy, "@", "") ++ "\\t" ++ description.first_line() ++ "\\t" ++ author.timestamp().ago() ++ "\\n"'
const META_TEMPLATE = 'commit_id.short(8) ++ "\\t" ++ author.name() ++ "\\t" ++ author.timestamp().ago() ++ "\\n" ++ description'
// /btw answers without tools, so the diff goes in the question itself.
// shortcut: a diff past this is cut; raise it if big commits get vague explanations.
const DIFF_CHARS = 20000
const STATUS_COLOR = { A: 'diffAdded', D: 'diffRemoved', M: 'warning', R: 'suggestion' } as const

const jj = ($: EngineInterface, args: string[]) => $.process.run(['jj', '--no-pager', '--color', 'never', ...args])

function parseLog(stdout: string): JjCommit[] {
  return stdout
    .split('\n')
    .filter(line => line !== '')
    .map(line => {
      const [id = '', at = '', title = '', age = ''] = line.split('\t')
      return { id, isCurrent: at === '@', title, age }
    })
}

async function refresh($: EngineInterface) {
  const r = await jj($, ['log', '--no-graph', '-n', '30', '-T', LOG_TEMPLATE]).catch(err => ({ exitCode: 1, stdout: '', stderr: String(err) }))
  const ok = r.exitCode === 0
  const p = await update($, pane, p => ({ ...p, commits: ok ? parseLog(r.stdout) : [], error: ok ? '' : (r.stderr.trim().split('\n')[0] ?? 'jj failed') }))
  // A commit that is open shows its new diff after an edit.
  if (p.expanded !== '') await load($, p.expanded)
}

async function load($: EngineInterface, id: string) {
  const [meta, diff] = await Promise.all([jj($, ['log', '--no-graph', '-r', id, '-T', META_TEMPLATE]), jj($, ['diff', '--git', '-r', id])])
  const [head = '', ...rest] = meta.stdout.split('\n')
  const [commitId = '', author = '', age = ''] = head.split('\t')
  const error = meta.exitCode !== 0 ? meta.stderr.trim() : diff.exitCode !== 0 ? diff.stderr.trim() : ''
  const detail = { id, commitId, author, age, description: rest.join('\n').trim(), files: parseGitDiff(diff.stdout), error }
  await update($, pane, p => (p.expanded === id ? { ...p, detail } : p))
}

async function toggleCommit($: EngineInterface, id: string) {
  const p = await update($, pane, p => ({ ...p, expanded: p.expanded === id ? '' : id, detail: undefined, openFile: '' }))
  if (p.expanded !== '') await load($, id)
}

const toggleFile = ($: EngineInterface, path: string) =>
  update($, pane, p => ({ ...p, openFile: p.openFile === path ? '' : path }))

async function explain($: EngineInterface, id: string) {
  const r = await jj($, ['show', '--git', '-r', id])
  await $.command
    .run({ command: 'btw', args: `Explain this jj commit to me: what it changes and why.\n\n${r.stdout.slice(0, DIFF_CHARS)}` })
    .catch(err => $.ui.toast(`Could not start /btw: ${String(err)}`))
}

const open = ($: EngineInterface) => $.ui.open({ id: PANE, title: TITLE })

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({ name: 'jj', description: 'Open the jj commits pane' })
    await refresh($).catch(() => {})
    void open($)
    return next(e)
  }).catch(($, e, next) => next(e))

  on('command.run', { command: 'jj' }, async $ => {
    await refresh($)
    await open($)
    return { text: 'jj commits pane opened.' }
  })

  // jj commands run through Bash, and edits change @.
  on('tool.call', async ($, e, next) => {
    const ran = await next(e)
    if (['Bash', 'Edit', 'Write', 'NotebookEdit'].includes(e.tool)) await refresh($).catch(() => {})
    return ran
  }).catch(($, e, next) => next(e))

  on('ui.render', { component: 'Pane', requestId: PANE }, async ($, e) => {
    const p = await read($, pane)
    const { Box, Text, Button, Code } = $.ui.resolve(e)

    const fileRow = (f: JjFile) => {
      const isOpen = p.openFile === f.path
      return (
        <Box key={`f-${f.path}`} flexDirection="column">
          <Button key={`file-${f.path}`} plain onPress={() => toggleFile($, f.path)}>
            <Text dimColor>{isOpen ? '▾' : '▸'}</Text> <Text color={STATUS_COLOR[f.status]} bold>{f.status}</Text> {f.path}{' '}
            <Text color="diffAdded">+{f.added}</Text> <Text color="diffRemoved">−{f.removed}</Text>
          </Button>
          {isOpen &&
            (f.hunks === '' ? (
              <Text dimColor>  no text changes (binary or mode only)</Text>
            ) : (
              <Box flexDirection="column" marginY={1}>
                <Code source={f.hunks} format="diff" path={f.path} />
                {f.isCut && <Text dimColor>  … diff too long, rest not shown</Text>}
              </Box>
            ))}
        </Box>
      )
    }

    const details = (c: JjCommit) => {
      const d = p.detail
      if (d === undefined || d.id !== c.id) return <Text dimColor>  Loading…</Text>
      const added = d.files.reduce((n, f) => n + f.added, 0)
      const removed = d.files.reduce((n, f) => n + f.removed, 0)
      const [title = '', ...rest] = d.description.split('\n')
      const body = rest.join('\n').trim()
      return (
        <Box flexDirection="column" borderStyle="round" borderColor="subtle" paddingX={1} marginBottom={1} gap={1}>
          {d.error !== '' && <Text color="error">{d.error}</Text>}
          <Box flexDirection="column">
            <Text bold>{title || '(no description)'}</Text>
            {body !== '' && <Text dimColor>{body}</Text>}
          </Box>
          <Text dimColor>{`${d.author} · ${d.age} · commit ${d.commitId}`}</Text>
          <Box flexDirection="column">
            <Text>
              {d.files.length} {d.files.length === 1 ? 'file' : 'files'} <Text color="diffAdded">+{added}</Text>{' '}
              <Text color="diffRemoved">−{removed}</Text>
            </Text>
            {d.files.map(fileRow)}
          </Box>
          <Box flexDirection="row">
            <Button key={`explain-${c.id}`} label="Explain in /btw" onPress={() => explain($, c.id)} />
          </Box>
        </Box>
      )
    }

    return (
      <Box flexDirection="column" gap={1} width={e.props.bodyColumns}>
        <Box flexDirection="row" alignItems="center">
          <Text dimColor>{p.commits.length} commits</Text>
          <Box flexGrow={1} />
          <Button key="refresh" plain label="Refresh" onPress={() => refresh($)} />
        </Box>
        {p.error !== '' && <Text color="warning">{p.error}</Text>}
        <Box flexDirection="column">
          {p.commits.map(c => {
            const isOpen = c.id === p.expanded
            return (
              <Box key={`row-${c.id}`} flexDirection="column">
                <Button key={`c-${c.id}`} plain onPress={() => toggleCommit($, c.id)}>
                  <Text dimColor>{isOpen ? '▾' : '▸'}</Text> <Text color={c.isCurrent ? 'suggestion' : undefined}>{c.isCurrent ? '@' : '○'} {c.id}</Text>{' '}
                  {c.title || '(no description)'} <Text dimColor>{c.age}</Text>
                </Button>
                {isOpen && details(c)}
              </Box>
            )
          })}
        </Box>
      </Box>
    )
  })
}
