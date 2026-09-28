---
name: test-windows
description: Test these dotfiles on a fresh Windows by applying the current jj working copy in the Omarchy Windows VM, then checking and fixing the result. Use when asked to test, verify or debug the Windows side of the dotfiles (winget/choco/mise installs, AppData configs, Windows Terminal, symlinks, run_*_windows scripts), or before pushing changes that touch Windows paths.
---

# Test the dotfiles on Windows

`.tests/windows.nu` resets the Omarchy Windows VM to a clean snapshot, applies
the current jj working copy (`@`, uncommitted edits included) with
`chezmoi init --apply`, runs checks, and takes a screenshot of the desktop.

Only works on the Omarchy machine, which has the VM. The host's
`BWS_ACCESS_TOKEN` is read from its chezmoi config and passed to the apply as an
env var, so secrets (`~/.ssh/id_ed25519`, `gh auth`) are tested too; the run stops
if the host has none. mise's GitHub API calls are authenticated with the GitHub
token from Bitwarden, as on a real machine (the anonymous limit is 60/h).

## Run

A run takes a long time (packages download on every run), so start it in the
background and read the log while it runs:

```bash
nu .tests/windows.nu run            # stops the VM at the end
nu .tests/windows.nu run --keep     # leaves it running, to debug afterwards
```

The first output line is the results dir, `~/.local/state/winvm/runs/<timestamp>/`:

| File | What it holds |
|------|---------------|
| `apply.log` | Full `chezmoi init --apply` output, written as it runs |
| `prepare.log` | Unpacking the source and installing chezmoi with winget |
| `summary.json` | Commit tested, apply exit code, `failures`, raw `checks` |
| `checks.raw` | Raw output of the checks, if they did not produce JSON |
| `screenshot.png` | The desktop with Windows Terminal open, after apply |

The run ends with `PASS`, or `FAIL` and one line per failure. It checks that:

- `chezmoi init --apply` exits 0
- `chezmoi verify --exclude scripts` passes: files match the source
- a second apply would be a no-op: `chezmoi status` lists nothing except the
  scripts that run on every apply (`run_after_*` / `run_before_*` without
  `onchange`/`once`)
- `chezmoi`, `mise`, `git`, `nu`, `jj` and `nvim` resolve on PATH (the mise
  ones through mise's shims, on the user PATH), and `mise ls --missing` is empty
- every symlink chezmoi manages points at a file that exists

Always look at `screenshot.png` with the Read tool too: it catches what the
checks cannot, such as a broken Windows Terminal profile or a missing font.

## Debug

With `--keep`, or after a failed run, the VM keeps running:

```bash
nu .tests/windows.nu ssh                        # interactive PowerShell
echo 'chezmoi status' | nu .tests/windows.nu ps # one-off script from stdin
```

Freshly installed tools are not on PATH in an ssh session until you reload it:
`$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')`.

Fix the source in this repo, never in the VM, then run again. Each run starts
from the clean snapshot. Stop the VM when done: `omarchy windows vm stop`.

## When a run dies halfway

`Connection reset by peer` in `apply.log`, then `no such object: omarchy-windows`,
means the VM was stopped mid-run. The usual cause is the Windows desktop
launcher: it stops the VM as soon as its RDP window closes. Tell the user not to
open it during a run (http://127.0.0.1:8006 is safe to watch from), then rerun.

## When it cannot start

- **"VM folders not set up since boot"**: the machine rebooted, so the run asks
  for the user's password once (a polkit dialog on their desktop) to recreate
  the VM's folder mounts. Tell the user to expect it; if they dismiss it, the run
  fails and needs to be started again.
- **ssh never answers**: the snapshot may lack OpenSSH. Ask the user to redo the
  setup: `nu .tests/windows.nu setup`, then follow what it prints.
- **permission denied on the Docker socket**: sudoless Docker is off. That is
  the user's decision (`omarchy setup security sudoless docker`); do not enable
  it yourself.

Never read or print `~/.config/windows/credentials` beyond `USERNAME`, and never
print `BWS_ACCESS_TOKEN`: the script passes it itself.
