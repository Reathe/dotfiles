import { expect, test } from 'claude-code/testing'

import { parseGitDiff } from '../hooks/diff'

const PANE = {
  plugin: 'jj-log',
  component: 'Pane',
  requestId: 'jj-log',
  props: { title: 'jj commits', isFocused: false, bodyColumns: 80, placement: 'dock', scroll: { offset: 0, bodyRows: 40 }, view: {} },
} as const

const LOG = 'aaaaaaaa\t@\t\t1 hour ago\nbbbbbbbb\t\tfix: the thing\t2 days ago\n'
const META = '1234abcd\tReathe\t2 days ago\nfix: the thing\n\nLonger body.\n'
const DIFF = [
  'diff --git a/src/x.ts b/src/x.ts',
  'index 1..2 100644',
  '--- a/src/x.ts',
  '+++ b/src/x.ts',
  '@@ -1,2 +1,2 @@',
  ' keep',
  '-old',
  '+new',
  'diff --git a/new.md b/new.md',
  'new file mode 100644',
  '--- /dev/null',
  '+++ b/new.md',
  '@@ -0,0 +1,2 @@',
  '+one',
  '+two',
  'diff --git a/a.txt b/b.txt',
  'similarity index 100%',
  'rename from a.txt',
  'rename to b.txt',
  'diff --git a/gone.bin b/gone.bin',
  'deleted file mode 100644',
  'Binary files a/gone.bin and /dev/null differ',
  '',
].join('\n')

test('parses a git diff into files with status, counts and hunks', () => {
  const files = parseGitDiff(DIFF)
  expect(files.map(f => [f.status, f.path, f.added, f.removed])).toEqual([
    ['M', 'src/x.ts', 1, 1],
    ['A', 'new.md', 2, 0],
    ['R', 'a.txt → b.txt', 0, 0],
    ['D', 'gone.bin', 0, 0],
  ])
  expect(files[0]?.hunks).toBe('@@ -1,2 +1,2 @@\n keep\n-old\n+new')
  expect(files[3]?.hunks).toBe('')
})

test('a first hunk past the cap still shows, cut at a line', () => {
  const big = Array.from({ length: 10000 }, (_, i) => `+line ${i}`).join('\n')
  const [file] = parseGitDiff(`diff --git a/big.txt b/big.txt\n--- a/big.txt\n+++ b/big.txt\n@@ -0,0 +1,10000 @@\n${big}\n`)
  expect(file?.isCut).toBe(true)
  expect(file?.hunks.startsWith('@@ -0,0 +1,10000 @@\n+line 0')).toBe(true)
  expect(file?.hunks.length).toBeLessThanOrEqual(40000)
  expect(file?.hunks.endsWith('\n')).toBe(false)
})

test('a commit opens to its files, a file to its diff, Explain runs /btw', async ($, on) => {
  const ran: { command: string; args?: string }[] = []
  on('command.register', () => ({ value: { command: 'jj' } }))
  on('ui.open', () => ({ value: { isPlaced: true } }))
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  on('process.run', (_, e) => {
    const stdout = e.argv.includes('diff') ? DIFF : e.argv.includes('show') ? 'diff --git a/x b/x' : e.argv.includes('-r') ? META : LOG
    return { value: { exitCode: 0, stdout, stderr: '', isStdoutTruncated: false, isStderrTruncated: false } } as never
  })
  on('command.run', (_, e) => {
    ran.push({ command: e.command, args: e.args })
    return { text: '' }
  })
  await $.session.start({ cwd: '/', surface: 'desktop', isInteractive: true })

  for (const surface of ['terminal', 'desktop'] as const) {
    const ui = await $.ui.mount({ ...PANE, surface })
    expect(await ui.find({ key: 'file-src/x.ts' })).toBeUndefined()

    await ui.press({ key: 'c-bbbbbbbb' })
    expect(await ui.find({ type: 'Text', text: /Longer body/ })).toBeDefined()
    expect(await ui.find({ type: 'Text', text: /Reathe · 2 days ago · commit 1234abcd/ })).toBeDefined()
    expect(await ui.find({ type: 'Code' })).toBeUndefined()

    await ui.press({ key: 'file-src/x.ts' })
    expect(await ui.find({ type: 'Code' })).toBeDefined()
    // One file open at a time keeps the drawing under its 100000 characters.
    await ui.press({ key: 'file-new.md' })
    expect((await ui.findAll({ type: 'Code' })).map(c => c.props.path)).toEqual(['new.md'])
    await ui.press({ key: 'file-new.md' })
    await ui.press({ key: 'file-src/x.ts' })
    await ui.press({ key: 'file-src/x.ts' })
    expect(await ui.find({ type: 'Code' })).toBeUndefined()

    await ui.press({ key: 'explain-bbbbbbbb' })
    expect(ran.at(-1)?.command).toBe('btw')

    await ui.press({ key: 'c-bbbbbbbb' })
    expect(await ui.find({ key: 'file-src/x.ts' })).toBeUndefined()
    await ui.unmount()
  }
})
