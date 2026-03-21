# Repository Guidelines

## Tools and Environment notes

Using windows, and a VM for NixOS.
Coding on NixOS using wsl, mostly with WindowsTerminal,
zellij as multiplexer, Nushell is default shell.
Editor is neovim, using [LazyVim](https://www.lazyvim.org/) setup.
VCS using jj.

## Project Structure & Module Organization

This repository is a Chezmoi source directory for personal dotfiles, storing configs for the tools used.
Top-level files such as [`.chezmoi.yaml.tmpl`](/home/raf/.local/share/chezmoi/.chezmoi.yaml.tmpl) and [`.chezmoidata/packages.yaml`](/home/raf/.local/share/chezmoi/.chezmoidata/packages.yaml) drive templating and package lists. Managed files follow Chezmoi naming rules: `dot_config/` maps to `~/.config/`, `dot_ssh/` maps to `~/.ssh/`, `private_*` marks secret material, `symlink_*` creates symlinks, and `*.tmpl` follow go templates rules with chezmoi variables. Automation scripts are named as `run_*`, with variations like `after` or `before`, meaning after or before applying the config.

## Build, Test, and Development Commands

For templates (files ending in .tmpl or special chezmoi files/directories), use Chezmoi commands to validate changes before applying them:

- `chezmoi diff` previews local changes against the target home directory.
- `chezmoi apply --init` renders and applies the current source state.
- `chezmoi execute-template --file path/to/file.tmpl` checks template output without writing files.
- In general, every file should be formatted using the appropriate tool when possible, except for auto-generated files.
  - `stylua dot_config/nvim` formats the Neovim Lua config using the repo’s `stylua.toml`.
  - `topiary format dot_config/nushell/*.nu dot_config/topiary/queries/nu.scm` formats Nushell and Topiary grammar files when touched.
