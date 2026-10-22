#!/usr/bin/env nu
# vim: ft=nu:
# Checks `nixpkg.nu apply` (the code that edits raf-user.nix) on a copy of the repo's raf-user.nix and flake.nix,
# with a fake sudo standing in for the rebuild. Run it after touching apply, bounds, installed or rebuild:
#   nu test-apply.nu    prints "ok", or stops at the first wrong case

let script = $env.FILE_PWD | path expand | path join nixpkg.nu
let repo = $script | path dirname --num-levels 5
let tmp = mktemp -d
mkdir ($tmp | path join src/.nix/modules) ($tmp | path join bin)
cp ($repo | path join .nix/modules/raf-user.nix) ($tmp | path join src/.nix/modules/)
cp ($repo | path join flake.nix) ($tmp | path join src/)
# the fake sudo exits FAKE_RC; with FAKE_EDIT it also appends to that file mid-"rebuild", like an nvim save would
'#!/bin/sh
[ -n "${FAKE_EDIT:-}" ] && echo "# edited meanwhile" >> "$FAKE_EDIT"
exit "${FAKE_RC:-0}"
' | save ($tmp | path join bin/sudo)
chmod +x ($tmp | path join bin/sudo)
let file = $tmp | path join src/.nix/modules/raf-user.nix
let original = open --raw $file

def apply [tmp: string, script: string, env_extra: record, ...changes: string] {
  let vars = { PATH: ($env.PATH | prepend ($tmp | path join bin)), NIXPKG_SRC: ($tmp | path join src) } | merge $env_extra
  with-env $vars { ^nu $script apply ...$changes | complete }
}

# "stable" / "unstable" / null: which list holds `attr`
def list-of [text: string, attr: string] {
  let ls = $text | lines
  let at = {|t| $ls | enumerate | where item == $t | get 0.index }
  let start = do $at "      (with pkgs; ["
  let split = do $at "      ++ (with unstable; ["
  let end = do $at "      ]);"
  let i = $ls | enumerate | where {|l| $l.index > $start and $l.index < $end and ($l.item | str trim | split row " " | first) == $attr } | get -o 0.index
  if $i == null { null } else if $i < $split { "stable" } else { "unstable" }
}

def check [ok: bool, what: string] {
  if not $ok { error make --unspanned { msg: $"test-apply: ($what)" } }
}

# three packages the copy already has in its stable list
let stable = $original | lines | where $it =~ '^\s{8}[A-Za-z0-9_.+-]+\s*(#.*)?$' | each { str trim | split row " " | first }
| where {|a| (list-of $original $a) == "stable" } | first 3
check ((list-of $original hello) == null and (list-of $original cowsay) == null) "hello and cowsay must not be installed for this test"

# a batch: add to each list, remove, move, and one that is already there
let r = apply $tmp $script {} stable:hello unstable:cowsay $"remove:($stable.0)" $"unstable:($stable.1)" $"stable:($stable.2)"
let now = open --raw $file
check ($r.exit_code == 0) $"batch exits 0, got ($r.exit_code): ($r.stderr)"
check ((list-of $now hello) == "stable") "hello added to stable"
check ((list-of $now cowsay) == "unstable") "cowsay added to unstable"
check ((list-of $now $stable.0) == null) $"($stable.0) removed"
check ((list-of $now $stable.1) == "unstable") $"($stable.1) moved to unstable"
check ((list-of $now $stable.2) == "stable") $"($stable.2) left in stable"
check (($now | lines | length) == ($original | lines | length) + 1) "batch adds two lines and removes one"
check ($r.stdout =~ $"Skipping ($stable.2)") "an already installed package is reported as skipped"

# a failed rebuild puts the file back and exits 1, for run.sh to offer the agent
$original | save --force $file
let r = apply $tmp $script { FAKE_RC: "1" } stable:hello
check ($r.exit_code == 1) $"failed rebuild exits 1, got ($r.exit_code)"
check ((open --raw $file) == $original) "failed rebuild restores raf-user.nix"

# ...unless the file changed during the rebuild: then it is left alone
let r = apply $tmp $script { FAKE_RC: "1", FAKE_EDIT: $file } stable:hello
let now = open --raw $file
check ($r.exit_code == 1) "failed rebuild with an edit exits 1"
check ((list-of $now hello) == "stable" and ($now | str contains "# edited meanwhile")) "an edit during the rebuild is kept"

# names that are not nix attrs are refused before anything is written
$original | save --force $file
let r = apply $tmp $script {} 'stable:a;b'
check ($r.exit_code != 0 and (open --raw $file) == $original) "an odd attr name is refused"

rm -r $tmp
print "ok"
