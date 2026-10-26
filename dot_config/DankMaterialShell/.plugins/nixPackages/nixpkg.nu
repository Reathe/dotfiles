#!/usr/bin/env nu
# vim: ft=nu:
# Backend of the nixPackages DMS launcher plugin: search, show details, install into / uninstall from raf-user.nix.

# same search.nixos.org index as env.nu sets (the plugin runs nu without env.nu)
let idx = nu ($nu.default-config-dir | path join nh-search-index.nu)
if $idx != "" { $env.NH_SEARCH_BACKEND_VERSION = $idx }

# The repo this plugin lives in: its folder is linked from <repo>/dot_config/DankMaterialShell/.plugins/nixPackages.
# NIXPKG_SRC points at another source tree (used to test installs on a copy).
def src [] {
  $env.NIXPKG_SRC? | default ($env.FILE_PWD | path expand | path dirname --num-levels 4)
}
def user-nix [] { src | path join ".nix/modules/raf-user.nix" }

# search.nixos.org channels of flake.nix's two nixpkgs inputs, so searches follow channel bumps
def channels [] {
  let f = open --raw (src | path join flake.nix)
  let channel = {|input|
    $f | parse --regex ($input + '\.url = "nixpkgs/(?<c>[^"]+)"') | get -o 0.c
    | default { error make --unspanned { msg: $"flake.nix: expected ($input).url = \"nixpkgs/<channel>\"" } }
  }
  { stable: (do $channel nixpkgs) unstable: (do $channel nixpkgs-unstable) }
}

# line indexes of raf-user.nix's package lists: `(with pkgs; [` start, `++ (with unstable; [` split, `]);` end
def bounds [ls: list<string>] {
  let at = {|text| $ls | enumerate | where item == $text | get -o 0.index }
  let b = { start: (do $at "      (with pkgs; [") split: (do $at "      ++ (with unstable; [") end: (do $at "      ]);") }
  if ($b | values | any { $in == null }) or ($ls | get ($b.split - 1)) != "      ])" {
    error make { msg: $"unexpected package list layout in (user-nix)" }
  }
  $b
}

# {attr, list, index} for each package line in raf-user.nix (or in these lines of it)
def installed [ls?: list<string>] {
  let ls = $ls | default (open --raw (user-nix) | lines)
  let b = bounds $ls
  $ls | enumerate | where {|l| $l.index > $b.start and $l.index < $b.end }
  | where item =~ '^\s{8}[A-Za-z0-9_.+-]+\s*(#.*)?$'
  | each {|l| { attr: ($l.item | str trim | split row " " | first) list: (if $l.index < $b.split { "stable" } else { "unstable" }) index: $l.index } }
}

# {stable: "26.05", unstable: "unstable"} for the launcher's labels
def labels [] { channels | transpose k v | each { [$in.k ($in.v | str replace "nixos-" "")] } | into record }

def check-attr [attr: string] {
  if ($attr !~ '^[A-Za-z0-9_+-][A-Za-z0-9_.+-]*$') { error make { msg: $"refusing odd attr name: ($attr)" } }
}

# both channels searched in parallel; stable's ranking first, then what only unstable has
def lookup [query: list<string>, limit: int] {
  let ch = channels
  let have = installed
  let found = [stable unstable] | par-each {|k|
    # a missing nh throws instead of exiting non-zero; the launcher reports missing commands itself
    let r = try { do { nh search -c ($ch | get $k) --json -l $limit ...$query } | complete } catch { { exit_code: 127 } }
    { k: $k results: (if $r.exit_code == 0 { $r.stdout | from json | get results } else { [] }) }
  }
  let s = $found | where k == stable | get 0.results
  let u = $found | where k == unstable | get 0.results
  let s_attrs = $s | each { $in.package_attr_name }
  let results = $s | append ($u | where package_attr_name not-in $s_attrs) | each {|p|
    let attr = $p.package_attr_name
    {
      attr: $attr
      stable: (if $attr in $s_attrs { $p.package_pversion })
      unstable: ($u | where package_attr_name == $attr | get -o 0.package_pversion)
      description: ($p.package_description? | default "")
      homepage: ($p.package_homepage? | default [] | get -o 0 | default "")
      installed: ($have | where attr == $attr | get -o 0.list)
    }
  }
  # an exact name match goes first
  let exact = $query | str join " "
  { channels: (labels) results: (($results | where attr == $exact) ++ ($results | where attr != $exact)) }
}

# JSON for the launcher: {channels: {stable, unstable}, results: [{attr, stable, unstable, description, homepage, installed}]}
# (or {error} when it fails: the launcher shows it as a line that can be sent to the agent)
def "main search" [...query: string] {
  try { lookup $query 25 } catch {|e| { error: $e.msg } } | to json --raw
}

# installed.nix over raf-user.nix's packages; `refs` (nix attrset source) also asks for channel updates
def eval-installed [refs: string = "null"] {
  let items = installed | select attr list
  let nix = $env.FILE_PWD | path join installed.nix
  let apply = 'f: f { src = "' + (src) + '"; items = ' + "''" + ($items | to json --raw) + "''" + '; refs = ' + $refs + '; }'
  let r = do { nix eval --json --impure --file $nix --apply $apply } | complete
  if $r.exit_code == 0 { $r.stdout | from json } else { $items }
}

# JSON {<attr>: <newer version>} for installed packages whose channel has moved past the flake.lock pin
# (nix re-fetches a channel at most hourly, its tarball-ttl)
def "main updates" [] {
  let refs = channels | items {|k, c| $'($k) = "nixpkgs/($c)";' } | str join " "
  eval-installed $"{ ($refs) }" | where update? != null | each {|p| [$p.attr $p.update] } | into record | to json --raw
}

# Same shape as search for everything raf-user.nix installs, versions from the flake.lock-pinned nixpkgs (installed.nix)
def "main installed" [] {
  try {
    let info = eval-installed
    {
      channels: (labels)
      results: ($info | each {|p| {
        attr: $p.attr
        stable: (if $p.list == "stable" { $p.version? })
        unstable: (if $p.list == "unstable" { $p.version? })
        description: ($p.description? | default "")
        homepage: ($p.homepage? | default "")
        installed: $p.list
      } } | sort-by attr)
    }
  } catch {|e| { error: $e.msg } } | to json --raw
}

# Details in a terminal, then offer to install, remove, switch lists or update the channel
def "main show" [attr: string] {
  check-attr $attr
  nix-search-tv preview $"nixpkgs/ ($attr)"
  let l = lookup [$attr] 5
  let p = $l.results | where attr == $attr | get -o 0
  print ""
  print $"($l.channels.stable): ($p.stable? | default 'not available')   ($l.channels.unstable): ($p.unstable? | default 'not available')"
  let inst = installed | where attr == $attr | get -o 0.list
  if $inst != null {
    let other = if $inst == "stable" { "unstable" } else { "stable" }
    print $"(ansi green)Installed from the ($inst) list.(ansi reset)"
    match (input $"[r]emove, [s]witch to ($l.channels | get $other), [u]pdate ($l.channels | get $inst) \(all its packages\), [t]ry ($l.channels | get $other) in a shell, anything else to close: " | str trim | str lowercase) {
      "r" => { main uninstall $attr }
      "s" => { main install $attr $other }
      "u" => { main update $inst }
      "t" => { main try $attr $other }
    }
    return
  }
  match (input $"Install? [s]table ($l.channels.stable), [u]nstable; try in a shell: [ts] stable, [tu] unstable; anything else to close: " | str trim | str lowercase) {
    "s" => { main install $attr stable }
    "u" => { main install $attr unstable }
    "ts" => { main try $attr stable }
    "tu" => { main try $attr unstable }
  }
}

# Rebuild after `file` went from `before` to `after`; if the rebuild fails, put `before` back, unless the file changed
# again meanwhile (an edit in nvim, another install): restoring would wipe that. Else show which packages changed.
def rebuild [file: string, before: string, after: string, done: string] {
  let old = ^readlink -f /run/current-system | str trim
  # a plain path: git+file (only tracked files) in a git repo, root included; path: in a test copy without .git
  let ok = try { sudo nixos-rebuild switch --flake $"(src)#nixos"; true } catch { false }
  let name = $file | path basename
  if $ok {
    print "" "Version changes:"
    nix store diff-closures $old /run/current-system
    print $"(ansi green)($done)(ansi reset) Commit the ($name) change when you're happy with it."
    return
  }
  if (open --raw $file) == $after {
    $before | save --force $file
    print $"(ansi red)Rebuild failed; ($name) restored.(ansi reset)"
  } else {
    print $"(ansi red)Rebuild failed, and ($name) changed during the rebuild, so it was left as is: undo this change by hand.(ansi reset)"
  }
  # run.sh turns a non-zero exit into the "ask the agent" notification
  exit 1
}

# Apply several `stable:<attr>`, `unstable:<attr>` or `remove:<attr>` changes to raf-user.nix, then rebuild once.
# stable/unstable on a package already in the other list moves it there.
def "main apply" [...changes: string] {
  let todo = $changes | parse "{op}:{attr}"
  if ($todo | length) != ($changes | length) { error make { msg: $"changes look like stable:<attr>, unstable:<attr> or remove:<attr>: ($changes)" } }
  for c in $todo {
    check-attr $c.attr
    if $c.op not-in [stable unstable remove] { error make { msg: $"unknown change ($c.op):($c.attr)" } }
  }
  let before = open --raw (user-nix)
  mut ls = $before | lines
  for c in $todo {
    let have = installed $ls | where attr == $c.attr | get -o 0
    if $c.op == "remove" {
      if $have == null { print $"Skipping ($c.attr): not in raf-user.nix's package lists, so this plugin can't remove it."; continue }
      $ls = $ls | drop nth $have.index
      print $"Removing ($c.attr) from the ($have.list) list"
      continue
    }
    if $have != null and $have.list == $c.op { print $"Skipping ($c.attr): already in the ($have.list) list"; continue }
    # a move keeps the line as is, comment included
    let line = if $have != null { $ls | get $have.index } else { $"        ($c.attr)" }
    if $have != null { $ls = $ls | drop nth $have.index }
    let b = bounds $ls
    # stable list ends on the `      ])` line before the split, unstable on `      ]);`
    $ls = $ls | insert (if $c.op == "stable" { $b.split - 1 } else { $b.end }) $line
    print (if $have != null { $"Moving ($c.attr) from the ($have.list) to the ($c.op) list" } else { $"Adding ($c.attr) to the ($c.op) list" })
  }
  if $ls == ($before | lines) {
    print "Nothing to change."
    return
  }
  let after = $ls | str join "\n" | $in + "\n"
  $after | save --force (user-nix)
  print "Rebuilding…"
  rebuild (user-nix) $before $after "Done."
}

# Open raf-user.nix in nvim on the attr's line
def "main edit" [attr: string] {
  check-attr $attr
  let entry = installed | where attr == $attr | get -o 0
  if $entry == null { error make { msg: $"($attr) is not in raf-user.nix's package lists" } }
  nvim $"+($entry.index + 1)" "+normal! zz" (user-nix)
}

def "main install" [attr: string, list: string] { main apply $"($list):($attr)" }
def "main uninstall" [attr: string] { main apply $"remove:($attr)" }

def flake-input [list: string] {
  match $list { "stable" => "nixpkgs", "unstable" => "nixpkgs-unstable", _ => { error make { msg: "list must be stable or unstable" } } }
}

# A throwaway nu with the package on PATH, from the flake.lock-pinned channel: nothing is installed
def "main try" [attr: string, list: string] {
  check-attr $attr
  print $"($attr) from ($list), until you exit this shell."
  with-env { NIXPKGS_ALLOW_UNFREE: "1" } {
    nix shell --impure --inputs-from (src) $"(flake-input $list)#($attr)" --command nu
  }
}

# Update one channel's flake input (every package from that list) and rebuild; flake.lock is restored if that fails
def "main update" [list: string] {
  let input = flake-input $list
  let lock = src | path join flake.lock
  let before = open --raw $lock
  print $"Updating ($input)…"
  nix flake update $input --flake (src)
  let after = open --raw $lock
  if $after == $before {
    print "Already up to date."
    return
  }
  rebuild $lock $before $after $"($input) updated."
}

# The plugin's settings page (DMS saves it to plugin_settings.json); read at use so changes need no reload
def setting [key: string, fallback: string] {
  let file = $env.HOME | path join .config/DankMaterialShell/plugin_settings.json
  try { open $file | get nixPackages | get $key } catch { $fallback } | default $fallback
}

# Name of the agent errors go to, for labels
def "main agent-name" [] {
  match (setting agent claude) { "claude" => "Claude", "codex" => "Codex", "opencode" => "OpenCode", _ => "the agent" }
}

# Write a prompt about a failure to its own file (an older notification keeps asking about its own error) and print the path
def save-prompt [what: string, output: string] {
  let dir = $env.HOME | path join .cache/nixpkg-errors
  mkdir $dir
  let file = $dir | path join $"(date now | format date '%Y%m%d-%H%M%S-%f').md"
  let plugin = src | path join dot_config/DankMaterialShell/.plugins/nixPackages
  $"The nixPackages launcher plugin for DankMaterialShell failed while running: ($what)

Its code is in ($plugin): nixpkg.nu is the backend, run.sh runs it in a terminal, NixPackagesLauncher.qml is the
launcher side, installed.nix reads package versions. It edits .nix/modules/raf-user.nix and flake.lock in (src),
then runs nixos-rebuild.

Output:
```
($output)
```

Find out why it failed. Fix it if the fix is in the plugin or the config, otherwise tell me what to do.
" | save $file
  $file
}

# From run.sh after a failure: the end of the terminal log, cleaned up, into a prompt file
def "main report" [log: path, ...cmd: string] {
  let output = open --raw $log | ansi strip | lines
  # progress redraws: only what is after a line's last carriage return is what was left on screen
  | each { split row "\r" | where { is-not-empty } | last | default "" }
  | where $it !~ '^Script (started|done) '
  | last 80 | str join "\n" | str trim
  save-prompt $"nixpkg.nu ($cmd | str join ' ')" $output
}

# From the launcher's error line: its message into a prompt file, then ask
def "main ask-text" [what: string, message: string] { main ask (save-prompt $what $message) }

# Start the chosen agent in the repo with the prompt in `file`
def "main ask" [file: path] {
  let prompt = open --raw $file
  cd (src)
  match (setting agent claude) {
    "claude" => { ^claude $prompt }
    "codex" => { ^codex $prompt }
    "opencode" => { ^opencode --prompt $prompt }
    "custom" => {
      let cmd = setting customAgent ""
      if $cmd == "" { error make { msg: "Pick a custom agent command in the Nix packages plugin settings" } }
      ^sh -c $"($cmd) \"$1\"" sh $prompt
    }
    $other => { error make { msg: $"unknown agent setting: ($other)" } }
  }
}

def main [] { print "usage: nixpkg.nu search <query> | installed | show <attr> | edit <attr> | install <attr> stable|unstable | uninstall <attr> | apply stable:<attr> unstable:<attr> remove:<attr>… | update stable|unstable | updates | report <log> <cmd…> | ask <prompt file> | ask-text <what> <message> | agent-name" }
