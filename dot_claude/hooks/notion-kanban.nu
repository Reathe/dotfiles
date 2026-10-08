# vim: ft=nu:
# Claude Code hook: keeps one Notion kanban board per project in sync with what Claude sessions work on.
#
# Wired up in ~/.claude/settings.json (see dot_claude/modify_settings.json):
#   Stop       -> `nu --stdin notion-kanban.nu stop`  (throttled: at most once per $THROTTLE per project)
#   SessionEnd -> `nu --stdin notion-kanban.nu end` (always, so the final state of a session lands)
#
# The hook itself only reads the session transcript and writes a short digest (user prompts, todo/task
# list, git state). It then starts a detached `claude -p` that uses the Notion MCP server to find or
# create the board for the project and update its cards, so Claude Code never waits on Notion.
#
# Environment knobs:
#   NOTION_KANBAN_DISABLE=1      skip entirely
#   NOTION_KANBAN_PARENT=<name>  Notion page holding the boards (default "Project Kanbans")
#   NOTION_KANBAN_MODEL=<model>  model for the sync run (default "sonnet")
# Logs and digests: ~/.local/state/notion-kanban/

const THROTTLE = 20min
const STATE_DIR = ("~/.local/state/notion-kanban" | path expand)

# Project root of `dir` (git, then jj), or null when it is not inside a repository.
def project-root [dir: path] {
  let git = do { ^git -C $dir rev-parse --show-toplevel } | complete
  if $git.exit_code == 0 { return ($git.stdout | str trim) }
  if (which jj | is-empty) { return null }
  let jj = do { ^jj --repository $dir root --ignore-working-copy } | complete
  if $jj.exit_code == 0 { return ($jj.stdout | str trim) }
  null
}

# Text of a transcript message's content, which is either a string or a list of content blocks.
def content-text [content] {
  if ($content | describe) == "string" { return $content }
  $content | where {|b| ($b | get -o type) == "text" } | get -o text | str join "\n"
}

def build-digest [project: string, root: path, transcript: path] {
  let entries = open --raw $transcript | lines | each {|l| try { $l | from json } catch { null } }
  | where {|e| ($e | describe) starts-with "record" }

  let prompts = $entries
  | where {|e| $e.type? == "user" and not ($e.isMeta? | default false) }
  | each {|e| content-text ($e.message?.content? | default "") | str trim }
  | where {|t| $t != "" and not ($t starts-with "<") }
  | each {|t| "- " + ($t | str replace -a "\n" " " | str substring 0..400) }
  | last 25

  let tool_uses = $entries
  | where {|e| $e.type? == "assistant" and ($e.message?.content? | describe) =~ "^(list|table)" }
  | each {|e| $e.message.content | where {|b| ($b | get -o type) == "tool_use" } }
  | flatten

  # Classic todo list: only the latest TodoWrite matters, it always carries the full list.
  let todos = $tool_uses | where name == "TodoWrite" | last 1 | get -o 0.input.todos | default []
  # Newer task tools: every create/update call, oldest first.
  let tasks = $tool_uses | where {|t| $t.name in [TaskCreate TaskUpdate] } | each {|t| {tool: $t.name, input: $t.input} } | last 60

  let branch = do { ^git -C $root branch --show-current } | complete | get stdout | str trim
  let commits = do { ^git -C $root log --oneline -10 } | complete | get stdout | str trim
  let status = do { ^git -C $root status --short } | complete | get stdout | lines | first 30 | str join "\n"

  let sections = [
    $"# Project: ($project)\nRepository: ($root)\nBranch: ($branch)"
    $"## User requests this session \(oldest first\)\n($prompts | str join "\n")"
    (if ($todos | is-empty) { "" } else { $"## Current todo list\n($todos | each {|t| $'- [($t.status)] ($t.content)' } | str join "\n")" })
    (if ($tasks | is-empty) { "" } else { $"## Task tool calls \(oldest first\)\n($tasks | to json)" })
    $"## Recent commits\n($commits)"
    $"## Uncommitted changes\n($status)"
  ]
  {
    text: ($sections | where $it != "" | str join "\n\n")
    substantial: (($todos | is-not-empty) or ($tasks | is-not-empty) or ($prompts | length) >= 2)
  }
}

def sync-prompt [project: string, parent: string] {
  $"You keep a Notion kanban board in sync with a software project. The project is \"($project)\"; a digest
of the latest Claude Code session on it is on stdin.

1. Find the Notion page titled \"($parent)\" \(notion-search\). If it does not exist, create it as a private page.
2. Under it, find the database titled \"($project)\". If it does not exist, create it with these properties:
   Name \(title\), Status \(Backlog, Todo, In progress, Blocked, Done\), Notes \(text\), Updated \(date\),
   and add a Board view grouped by Status as its first view.
3. Read the cards already on the board, then reconcile them with the digest:
   - add a card for each distinct piece of work that has no card yet \(short imperative title\);
   - move cards whose status changed \(completed work -> Done, active work -> In progress\);
   - set Updated to today on every card you touch and add a one-line Notes entry when useful.
   Match cards by meaning, not exact wording; never create duplicates and never delete cards.
   Ignore chit-chat, questions and one-off lookups that are not project work.
4. Reply with a single line saying what changed."
}

# Hook entry point: `nu --stdin notion-kanban.nu stop|end`, hook input JSON on stdin.
def main [event: string] {
  let input = $in | from json
  if ($env.NOTION_KANBAN_DISABLE? | default "") != "" or ($env.NOTION_KANBAN_SYNC? | default "") != "" {
    return
  }

  let root = project-root $input.cwd
  if $root == null or not ($input.transcript_path | path exists) { return }
  let project = $root | path basename

  mkdir $STATE_DIR
  let stamp = $STATE_DIR | path join $"($project).last-sync"
  if $event == "stop" and ($stamp | path exists) and ((date now) - (ls $stamp | get 0.modified)) < $THROTTLE {
    return
  }

  let digest = build-digest $project $root $input.transcript_path
  if not $digest.substantial { return }

  let digest_file = $STATE_DIR | path join $"($project)-($input.session_id).md"
  $digest.text | save -f $digest_file
  touch $stamp

  # Detach so Claude Code doesn't wait on the sync; flock keeps two syncs from racing on one board.
  let lock = $STATE_DIR | path join $"($project).lock"
  let log = $STATE_DIR | path join $"($project).log"
  ^setsid -f sh -c 'exec flock -w 900 "$1" "$2" "$3" sync "$4" "$5" </dev/null >>"$6" 2>&1' _ $lock $nu.current-exe $env.CURRENT_FILE $project $digest_file $log
}

# Worker: push one digest to Notion through a headless Claude run.
def "main sync" [project: string, digest_file: path] {
  let parent = $env.NOTION_KANBAN_PARENT? | default "Project Kanbans"
  let model = $env.NOTION_KANBAN_MODEL? | default "sonnet"
  print $"=== (date now | format date '%F %T') ($digest_file)"
  # NOTION_KANBAN_SYNC stops this run's own hooks from triggering another sync. Both the claude.ai
  # connector and a `claude mcp add`-ed server are allowed, whichever one Notion is connected through.
  with-env {NOTION_KANBAN_SYNC: "1"} {
    open --raw $digest_file | ^claude -p (sync-prompt $project $parent) --model $model --max-turns 40 --allowedTools mcp__claude_ai_Notion mcp__notion
  }
  rm -f $digest_file
}
