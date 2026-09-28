#!/usr/bin/env nu
# vim: ft=nu:

# Test this chezmoi source on a fresh Windows, using the Omarchy Windows VM.
#
#   nu .tests/windows.nu setup      one-time: test key + in-VM OpenSSH script
#   nu .tests/windows.nu run        reset VM -> apply @ -> checks -> screenshot
#   nu .tests/windows.nu ps         run PowerShell from stdin in the VM
#   nu .tests/windows.nu ssh        shell into the VM
#   nu .tests/windows.nu screenshot capture the VM desktop
#
# Needs sudoless Docker (docker group) and a snapshot ~/.windows-clean taken
# after `setup` (winvm save clean). The host's BWS_ACCESS_TOKEN (from its chezmoi
# config) is passed to the apply only. Results go to ~/.local/state/winvm/runs/<timestamp>/.

const COMPOSE = "/var/lib/omarchy/windows/docker-compose.yml"
const CONTAINER = "omarchy-windows"

def state-dir [] { $nu.home-dir | path join .local state winvm }
def key-file [] { state-dir | path join id_ed25519 }
def repo-dir [] { $env.FILE_PWD | path dirname }

def vm-running [] {
  (^docker inspect -f "{{.State.Running}}" $CONTAINER | complete | get stdout | str trim) == "true"
}

def vm-ip [] {
  ^docker inspect -f "{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}" $CONTAINER | str trim
}

def vm-user [] {
  open ($nu.home-dir | path join .config windows credentials)
  | lines
  | parse "{key}={value}"
  | where key == USERNAME
  | get 0.value
  | str trim -c '"'
}

# Every VM start gets a fresh host key, and the container IP is not stable.
def ssh-opts [] {
  [
    -i (key-file)
    -o StrictHostKeyChecking=no
    -o UserKnownHostsFile=/dev/null
    -o LogLevel=ERROR
    -o BatchMode=yes
    -o ConnectTimeout=5
  ]
}

def vm-target [] { $"(vm-user)@(vm-ip)" }

# -EncodedCommand sidesteps ssh + PowerShell quoting entirely.
def encode-ps [script: string] {
  $"$ProgressPreference = 'SilentlyContinue'\n($script)"
  | ^iconv -f utf-8 -t utf-16le
  | encode base64
}

# Run a PowerShell script in the VM; returns {stdout stderr exit_code}.
def vm-ps [script: string] {
  ^ssh ...(ssh-opts) (vm-target) $"powershell -NoProfile -NonInteractive -EncodedCommand (encode-ps $script)"
  | complete
}

def vm-stop [] {
  if (vm-running) { ^omarchy-windows-vm stop }
}

# Start without RDP. Omarchy pins ~/.windows and ~/Windows into root-owned
# anchors, which a reboot removes; a bare `compose up` would then hand Docker
# empty directories. Its privileged `up` recreates them and starts the VM: one
# polkit prompt per boot. It refuses unless ~/Windows is exactly 700, and the
# container leaves setgid on it (2777), which its own chmod 0700 keeps.
def vm-start [] {
  let base = $"/var/lib/omarchy/windows/mounts/users/(^id -u | str trim)"
  let pinned = ([storage shared] | all {|m| (^findmnt -n $"($base)/($m)" | complete).exit_code == 0 })
  if $pinned {
    ^docker-compose -f $COMPOSE up -d
  } else {
    print "VM folders not set up since boot: pinning them (asks for your password once)"
    ^chmod g-s ($nu.home-dir | path join Windows)
    ^pkexec /usr/bin/omarchy-windows-vm __priv up
  }
}

def wait-ssh [timeout: duration = 5min] {
  let deadline = (date now) + $timeout
  while (vm-ps "exit 0").exit_code != 0 {
    if (date now) > $deadline { error make {msg: "VM did not answer on ssh in time"} }
    sleep 5sec
  }
}

# Scripts chezmoi runs on every apply, as `chezmoi status` names them.
def always-run-scripts [] {
  ls (repo-dir) | get name | path basename
  | where {|n| ($n =~ '^run_(after|before)_') and not ($n =~ '^run_(after|before)_(onchange|once)_') }
  | where {|n| not ($n =~ '\.(sh|bat)(\.tmpl)?$') }
  | each {|n| $n | str replace -r '^run_(after|before)_' '' | str replace -r '\.tmpl$' '' }
}

const PS_PATH = "$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')"
const PS_CHEZMOI = "$chezmoi = \"$env:LOCALAPPDATA\\Microsoft\\WinGet\\Links\\chezmoi.exe\""

const PS_CHECKS = r#'
# nu, jj and nvim come from mise: they resolve through its shims, which the
# install script puts on the user PATH
$tools = "chezmoi", "mise", "git", "nu", "jj", "nvim"
$status = @(& $chezmoi status 2>&1 | % { "$_" })
& $chezmoi verify --exclude scripts 2>&1 | Out-Null
$verify = $LASTEXITCODE
$symlinks = @(& $chezmoi managed --include symlinks --path-style absolute 2>&1 | % { "$_" } | ? { $_ } | % {
  $item = Get-Item -LiteralPath $_ -Force -ErrorAction SilentlyContinue
  $target = if ($item) { $item.Target } else { $null }
  [pscustomobject]@{ path = $_; target = "$target"; ok = [bool]($target -and (Test-Path -LiteralPath $target)) }
})
$missing = @(mise ls --missing 2>$null | % { "$_" } | ? { $_ })
[pscustomobject]@{
  verify_exit = $verify
  status      = $status
  tools       = @($tools | % { [pscustomobject]@{ name = $_; path = "$((Get-Command $_ -ErrorAction SilentlyContinue).Source)" } })
  mise_missing = $missing
  symlinks    = $symlinks
} | ConvertTo-Json -Depth 4
'#

# Runs as a scheduled task in the logged-on desktop session: ssh sessions have
# no desktop to capture. Opens Windows Terminal so its profile/theme show up.
const PS_SHOT = r#'
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
Add-Type -Namespace W -Name Dpi -MemberDefinition '[DllImport("user32.dll")] public static extern bool SetProcessDPIAware();'
[W.Dpi]::SetProcessDPIAware() | Out-Null
Start-Process wt -ErrorAction SilentlyContinue
Start-Sleep -Seconds 20
$b = [Windows.Forms.SystemInformation]::VirtualScreen
$bmp = New-Object Drawing.Bitmap $b.Width, $b.Height
[Drawing.Graphics]::FromImage($bmp).CopyFromScreen($b.Left, $b.Top, 0, 0, $bmp.Size)
$bmp.Save("$HOME\winvm-shot.png")
'#

def screenshot [out: path] {
  let shot = ($PS_SHOT | ^iconv -f utf-8 -t utf-16le | encode base64)
  let r = (vm-ps $"
    Remove-Item \"$HOME\\winvm-shot.png\" -ErrorAction SilentlyContinue
    $a = New-ScheduledTaskAction -Execute powershell.exe -Argument '-NoProfile -WindowStyle Hidden -EncodedCommand ($shot)'
    Register-ScheduledTask -TaskName winvm-shot -Action $a -User $env:USERNAME -Force | Out-Null
    Start-ScheduledTask -TaskName winvm-shot
    for \($i = 0; $i -lt 45 -and -not \(Test-Path \"$HOME\\winvm-shot.png\"\); $i++\) { Start-Sleep 1 }
    Start-Sleep 1
    Unregister-ScheduledTask -TaskName winvm-shot -Confirm:$false
    if \(-not \(Test-Path \"$HOME\\winvm-shot.png\"\)\) { exit 1 }
  ")
  if $r.exit_code != 0 { return false }
  (^scp ...(ssh-opts) $"(vm-target):winvm-shot.png" $out | complete).exit_code == 0
}

# Run a PowerShell script in a visible window on the VM's desktop, as a
# scheduled task in the logged-on session (like the screenshot), so it can be
# watched in the viewer; its output streams into $log on the host. The task is
# elevated (RunLevel Highest), as the ssh session was, so installers never stop
# at a UAC prompt. The script file deletes itself once loaded: it may hold
# secrets. Returns the script's exit code.
def vm-visible [title: string, script: string, log: path, --timeout: duration = 90min] {
  let body = $"Remove-Item -LiteralPath $PSCommandPath
$Host.UI.RawUI.WindowTitle = '($title)'
$ProgressPreference = 'SilentlyContinue'
& {
($script)
} *>&1 | % { \"$_\" } | Tee-Object -FilePath \"$HOME\\winvm-step.log\"
\"winvm-exit=$LASTEXITCODE\" | Tee-Object -Append -FilePath \"$HOME\\winvm-step.log\"
Start-Sleep 5
"
  let b64 = ($body | encode utf-8 | encode base64)
  let started = (vm-ps $"
    Remove-Item \"$HOME\\winvm-step.log\" -ErrorAction SilentlyContinue
    $text = [Text.Encoding]::UTF8.GetString\([Convert]::FromBase64String\('($b64)'\)\)
    [IO.File]::WriteAllText\(\"$HOME\\winvm-step.ps1\", $text, [Text.UTF8Encoding]::new\($true\)\)
    $a = New-ScheduledTaskAction -Execute powershell.exe -Argument \"-NoProfile -ExecutionPolicy Bypass -File `\"$HOME\\winvm-step.ps1`\"\"
    $p = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest
    Register-ScheduledTask -TaskName winvm-step -Action $a -Principal $p -Force | Out-Null
    Start-ScheduledTask -TaskName winvm-step
  ")
  if $started.exit_code != 0 {
    $started.stdout + $started.stderr | save -f $log
    return (-1)
  }

  # Poll the VM-side log; the last line may still be half written, so it is
  # only taken once the exit marker shows the script is done.
  "" | save -f $log
  let deadline = (date now) + $timeout
  mut seen = 0
  loop {
    let r = (vm-ps $"$l = \"$HOME\\winvm-step.log\"; if \(Test-Path $l\) { Get-Content $l | Select-Object -Skip ($seen) }")
    let new = ($r.stdout | lines | each {|l| $l | str trim -r -c "\r" })
    let done = ($new | any {|l| $l starts-with "winvm-exit=" })
    let take = if $done { $new } else { $new | drop 1 }
    if ($take | is-not-empty) { $take | str join "\n" | $in + "\n" | save -a $log }
    $seen += ($take | length)
    if $done {
      vm-ps "Unregister-ScheduledTask -TaskName winvm-step -Confirm:$false" | ignore
      return ($take | parse "winvm-exit={code}" | get 0.code | str trim | into int)
    }
    if (date now) > $deadline {
      print -e $"timed out after ($timeout): ($title)"
      return (-1)
    }
    sleep 5sec
  }
}

# One-time setup: test key, and the script that enables OpenSSH in the VM.
def "main setup" [] {
  mkdir (state-dir)
  ^chmod 700 (state-dir)
  if not ((key-file) | path exists) {
    ^ssh-keygen -q -t ed25519 -N "" -C winvm-test -f (key-file)
  }
  let pub = (open --raw $"(key-file).pub" | str trim)
  open --raw ($env.FILE_PWD | path join windows-enable-ssh.ps1)
  | str replace "@PUBKEY@" $pub
  | save -f ($nu.home-dir | path join Windows enable-ssh.ps1)
  print "In the VM, in an elevated PowerShell, run:"
  print '  powershell -ExecutionPolicy Bypass -File \\host.lan\Data\enable-ssh.ps1'
  print "then stop the VM and snapshot it: winvm save clean"
}

# Shell into the running VM
def --wrapped "main ssh" [...args] {
  ^ssh ...(ssh-opts) (vm-target) ...$args
}

# Run PowerShell from stdin in the running VM
def "main ps" [] {
  let r = (vm-ps (^cat))
  print -n $r.stdout
  print -e -n $r.stderr
  exit $r.exit_code
}

# Screenshot the running VM's desktop (opens Windows Terminal first)
def "main screenshot" [out: path = "winvm-shot.png"] {
  if not (screenshot $out) { error make {msg: "screenshot failed"} }
  print ($out | path expand)
}

# Reset the VM to a snapshot, apply the current jj working copy, check the result
def "main run" [
  --snapshot: string = "clean" # ~/.windows-<snapshot> to start from
  --keep # leave the VM running afterwards
  --view # open the VM's web viewer in the browser
] {
  let snap = ($nu.home-dir | path join $".windows-($snapshot)")
  if not ($snap | path exists) { error make {msg: $"no snapshot ($snap)"} }
  let out = (state-dir | path join runs (date now | format date "%Y%m%d-%H%M%S"))
  mkdir $out
  print $"results: ($out)"

  # Snapshot of @ as a git tree: tracked files only, uncommitted edits included.
  let commit = (^jj --no-pager -R (repo-dir) log -r @ --no-graph -T commit_id | str trim)
  ^git -C (repo-dir) archive --format=tar -o ($out | path join source.tar) $commit

  print "resetting VM"
  vm-stop
  ^cp -a --reflink=always $"($snap)/." ($nu.home-dir | path join .windows)
  vm-start
  wait-ssh
  print $"VM up at (vm-ip)"
  let viewer = "http://127.0.0.1:8006"
  print $"watch it: ($viewer | ansi link) \(log in with the VM user\)"
  if $view { ^xdg-open $viewer | complete | ignore }

  ^scp ...(ssh-opts) ($out | path join source.tar) $"(vm-target):dotfiles.tar"
  print "> tar -xf dotfiles.tar; winget install twpayne.chezmoi (log: prepare.log)"
  vm-visible "winvm: prepare" r#'
$src = "$HOME\.local\share\chezmoi"
Write-Host "> tar -xf dotfiles.tar -C $src" -ForegroundColor Cyan
New-Item -ItemType Directory -Force $src | Out-Null
tar -xf "$HOME\dotfiles.tar" -C $src
Write-Host "> winget install twpayne.chezmoi" -ForegroundColor Cyan
winget install twpayne.chezmoi -s winget --accept-package-agreements --accept-source-agreements -h --disable-interactivity
'# ($out | path join prepare.log) | ignore

  # Secrets come from the host's own chezmoi config, for this apply only: the env
  # var skips the init prompt, and the value never reaches a log or file. mise's
  # GITHUB_TOKEN comes from Bitwarden through it, as on a real machine.
  let bws = (^chezmoi execute-template "{{ .BWS_ACCESS_TOKEN }}" | complete)
  if $bws.exit_code != 0 or ($bws.stdout | str trim | is-empty) {
    error make {msg: "no BWS_ACCESS_TOKEN in the host's chezmoi config"}
  }
  let bws_ps = $"$env:BWS_ACCESS_TOKEN = '($bws.stdout | str trim)'"

  print "> chezmoi init --apply (log: apply.log)"
  let apply_log = ($out | path join apply.log)
  let apply_exit = (vm-visible "winvm: chezmoi init --apply" $"($bws_ps)
($PS_PATH)
($PS_CHEZMOI)
Write-Host '> chezmoi init --apply --no-tty' -ForegroundColor Cyan
& $chezmoi init --apply --no-tty" $apply_log)

  print "checks"
  let checks_raw = (vm-ps $"($PS_PATH)\n($PS_CHEZMOI)\n($PS_CHECKS)")
  $checks_raw.stdout + $checks_raw.stderr | save -f ($out | path join checks.raw)
  let checks = (try { $checks_raw.stdout | from json } catch { null })

  print "screenshot"
  let shot_ok = (screenshot ($out | path join screenshot.png))

  let expected = (always-run-scripts)
  let failures = if $checks == null {
    ["checks did not produce JSON, see checks.raw"]
  } else {
    let unexpected = ($checks.status | where {|l| ($l | str trim | split row -r '\s+' | last) not-in $expected })
    [
      (if $apply_exit != 0 { $"chezmoi init --apply exited ($apply_exit), see apply.log" })
      (if $checks.verify_exit != 0 { "chezmoi verify: files differ from source after apply" })
      (if ($unexpected | is-not-empty) { $"re-apply is not a no-op: ($unexpected | str join '; ')" })
      ...($checks.tools | where path == "" | each {|t| $"tool not found: ($t.name)" })
      (if ($checks.mise_missing | is-not-empty) { $"mise tools missing: ($checks.mise_missing | str join '; ')" })
      ...($checks.symlinks | where not ok | each {|s| $"broken symlink: ($s.path) -> ($s.target)" })
      (if not $shot_ok { "screenshot failed" })
    ] | compact
  }

  let summary = {
    commit: $commit
    snapshot: $snapshot
    apply_exit: $apply_exit
    failures: $failures
    checks: $checks
  }
  $summary | to json | save -f ($out | path join summary.json)

  if not $keep { vm-stop }

  if ($failures | is-empty) {
    print "PASS"
  } else {
    print "FAIL"
    $failures | each {|f| print $"  - ($f)" } | ignore
    exit 1
  }
}

def main [] {
  help main
}
