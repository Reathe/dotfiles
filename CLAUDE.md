# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

See also `AGENTS.md`, which holds the same repo guidelines in the shared agent format.

## What this repository is

The chezmoi **source directory** for personal dotfiles (`~/.local/share/chezmoi`), covering both a NixOS
desktop and a Windows machine from one tree. It is not an application — nothing is "built"; source files
are *rendered and applied* into `$HOME` by chezmoi, and on NixOS a subset also feeds a NixOS flake.

VCS is **jj** colocated with git (`git status` shows detached HEAD — that is normal, use `jj st` / `jj log`).

## Commands

```bash
chezmoi diff                                   # preview what applying would change in $HOME
chezmoi apply --init                            # render + apply (alias `cma`); re-reads .chezmoi.yaml.tmpl
chezmoi execute-template --file path/to/x.tmpl  # render one template to stdout, no writes
sudo nixos-rebuild switch --flake /home/raf/.local/share/chezmoi#nixos   # alias `nrs`
```

Formatting (every hand-written file should be formatted; skip generated ones):

```bash
stylua dot_config/nvim                                                  # uses dot_config/nvim/stylua.toml
topiary format dot_config/nushell/*.nu dot_config/topiary/queries/nu.scm
nixfmt .nix/**/*.nix && statix check .nix                               # nix files
```

There are no tests. "Testing" a change means `chezmoi diff` / `chezmoi execute-template`, and for NixOS
changes a `nixos-rebuild switch` (or `build`) that succeeds.

## Architecture

### Two apply paths, one tree

1. **chezmoi path** — `dot_config/` → `~/.config/`, `dot_ssh/` → `~/.ssh/`, `AppData/` and `dot_glzr/`
   → Windows-only targets. Standard chezmoi attributes apply: `private_*`, `readonly_*`, `symlink_*`,
   `*.tmpl`, `run_*`.
2. **Nix path** — `flake.nix` + `.nix/` define `nixosConfigurations.nixos`. Because `.nix/` and
   `flake.nix` start with a dot or are listed in `.chezmoiignore`, chezmoi never copies them into
   `$HOME`; they are consumed *in place* from the source dir by `nixos-rebuild --flake path:<sourceDir>`.

The two paths are joined by `run_onchange_before_linux1_install-packages.sh.tmpl`: on NixOS it embeds
`sha256sum` of `flake.lock`, `flake.nix`, `.chezmoitemplates/kanata.kbd` and every file under `.nix/`
as comments, so **editing any Nix file changes the script's content hash and `chezmoi apply` re-runs
`nixos-rebuild switch` automatically**. On non-NixOS Linux the same script installs Homebrew packages
from `.chezmoidata/packages.yaml` (hashed the same way); Windows has a parallel `run_onchange_before_windows1_*.bat.tmpl` using winget/choco.

### Nix layout

`flake.nix` pins both `nixpkgs` (stable, currently `nixos-26.05`) and `nixpkgs-unstable`, and passes
`unstable` through `specialArgs` — so a package can be moved between the stable and unstable blocks in
`.nix/modules/raf-user.nix` without touching the flake. Hosts live in `.nix/hosts/<host>/default.nix`
and import the shared `.nix/modules/{common,raf-user}.nix`. User-level packages belong in
`raf-user.nix`; system-level settings in `common.nix` or the host file.

### Platform gating

Platform differences are expressed in three places — check all three when adding a config:

- `.chezmoiignore` (templated) decides which *files* exist per OS/distro, e.g. `.config/kanata` is
  ignored on NixOS (kanata is configured by the NixOS module instead), `.config/opencode` on non-NixOS.
- Inline `{{ if eq .chezmoi.os "windows" }}` blocks inside `*.tmpl` files.
- Separate `run_*_windows*` / `run_*_linux*` scripts.

### The `symlink_*` + dot-file trick

Several configs need to stay editable live and be valid for their tool's own schema/LSP:
`dot_config/jj/symlink_config.toml.tmpl` renders to a symlink pointing back at
`<sourceDir>/dot_config/jj/.config.toml`. The target starts with `.`, so chezmoi ignores it as source
state — the file in `$HOME` *is* the file in the repo. Same pattern for zellij, nvim's `.lazyvim.json`
/ `.lazy-lock.json`, and the Windows Terminal / jj / zellij AppData entries. **Edit the dot-prefixed
file, not the `symlink_*.tmpl`.**

### Shared template fragments

`.chezmoitemplates/kanata.kbd` is the single keyboard layout, pulled in by
`dot_config/kanata/kanata.kbd.tmpl` and `AppData/Roaming/kanata/kanata.kbd.tmpl` via
`{{ template "kanata.kbd" }}`, and referenced directly as `configFile` by the NixOS kanata service.
Edit the shared fragment, not the per-OS wrappers.

### Secrets

Secrets come from Bitwarden Secrets Manager. `.chezmoi.yaml.tmpl` prompts once for `BWS_ACCESS_TOKEN`
(or takes it from the env) and exports it via `scriptEnv`; templates then call
`bitwardenSecrets "<uuid>" (env "BWS_ACCESS_TOKEN")` — see `dot_ssh/private_readonly_id_ed25519.tmpl`
and `run_after_gh_auth.nu.tmpl`. On non-NixOS a `read-source-state` hook
(`.install-pw-manager.sh` / `.ps1`) installs the `bws` CLI first.

## Conventions

- New root-level docs/metadata that should not land in `$HOME` must be added to `.chezmoiignore`
  (as `README.md`, `AGENTS.md`, `CLAUDE.md` and `flake.nix` already are).
- Nushell is the default shell; scripts use `#!{{ lookPath "nu" }}` and `# vim: ft=nu:`. Aliases go in
  `dot_config/nushell/add_alias.nu.tmpl`, functions in `custom-commands.nu.tmpl`.
- Neovim is a LazyVim setup: config in `dot_config/nvim/lua/config/`, plugin specs one file per concern
  in `dot_config/nvim/lua/plugins/`.
- Windows package lists live in `.chezmoidata/packages.yaml`; NixOS packages live in `.nix/`, not there.
