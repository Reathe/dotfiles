#!/usr/bin/env nu
# vim: ft=nu:
# Checks the layout fixer behind `zellij repair-sessions` (dot_config/nushell/custom-commands.nu.tmpl) on the
# layouts in .tests/zellij: a tab that lost its terminal pane gets one back, while healthy tabs, a tab of floating
# panes and a plugin's tab are left as they are. Run it after touching the zj-* commands or a zellij update:
#   nu .tests/zellij-repair.nu    prints "ok", or stops at the first wrong case

let repo = $env.FILE_PWD | path dirname
let dir = $env.FILE_PWD | path join zellij
let commands = mktemp --tmpdir --suffix .nu
^chezmoi --source $repo execute-template --file ($repo | path join dot_config/nushell/custom-commands.nu.tmpl) | save --force $commands

# the fixer's lines for one layout file; a child nu, since `source` needs a path known when the script is parsed
def fix [commands: string file: string] {
  ^nu -n -c $"source '($commands)'; zj-fix-layout \(open --raw '($file)' | lines\) | str join \(char nl\)" | lines
}

def check [ok: bool what: string] {
  if not $ok { error make --unspanned {msg: $"zellij-repair: ($what)"} }
}

let healthy = $dir | path join healthy.kdl
let broken = $dir | path join broken.kdl
let fixed = $dir | path join broken.fixed.kdl
check ((fix $commands $healthy) == (open --raw $healthy | lines)) "a healthy layout is left as is"
check ((fix $commands $broken) == (open --raw $fixed | lines)) "Tab #2 gets a terminal pane back; Tab #3 and Sessions are left as is"
check ((fix $commands $fixed) == (open --raw $fixed | lines)) "a repaired layout is left as is"

rm $commands
print "ok"
