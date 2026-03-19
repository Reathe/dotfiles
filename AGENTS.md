# Repository Guidelines

## Tools and Environment notes

Using windows, and a VM for NixOS.
Coding on NixOS via ssh, mostly with WindowsTerminal,
zellij as multiplexer, Nushell is default shell.
Editor is neovim, using [LazyVim](https://www.lazyvim.org/) setup.
VCS using jj.

## Project Structure & Module Organization

This repository is a Chezmoi source directory for personal dotfiles, storing configs for the tools used.
Top-level files such as [`.chezmoi.yaml.tmpl`](/home/raf/.local/share/chezmoi/.chezmoi.yaml.tmpl) and [`.chezmoidata/packages.yaml`](/home/raf/.local/share/chezmoi/.chezmoidata/packages.yaml) drive templating and package lists. Managed files follow Chezmoi naming rules: `dot_config/` maps to `~/.config/`, `dot_ssh/` maps to `~/.ssh/`, `private_*` marks secret material, `symlink_*` creates symlinks, and `*.tmpl` follow go templates rules with chezmoi variables. Automation scripts are named as `run_*`, with variations like `after` or `before`, meaning after or before applying the config.

## Build, Test, and Development Commands

Use Chezmoi commands to validate changes before applying them:

- `chezmoi diff` previews local changes against the target home directory.
- `chezmoi apply --init` renders and applies the current source state.
- `chezmoi execute-template --file path/to/file.tmpl` checks template output without writing files.
- In general, every file should be formatted using the appropriate tool when possible, except for auto-generated files.
  - `stylua dot_config/nvim` formats the Neovim Lua config using the repo’s `stylua.toml`.
  - `topiary format dot_config/nushell/*.nu dot_config/topiary/queries/nu.scm` formats Nushell and Topiary grammar files when touched.

## jj (jujutsu) change description guidelines

Recent changes descriptions use short, imperative subjects focused on the affected area, for example `nix add codex and use unstable packages for ai` or `nu custom-commands: refreshpath works only on windows`. Follow that pattern: start with the subsystem (`nix`, `nu`, `nvim`, `windows`) and describe the behavior change plainly. Changes should state which OS or host was tested, mention any secrets or machine-specific assumptions, and include rendered output or screenshots only when the change affects visible UI such as terminal or editor behavior.
