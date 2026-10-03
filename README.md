# dotfiles

> My development environment as code. One [chezmoi](https://www.chezmoi.io/) repository sets up both a
> **NixOS** workstation (declarative, from a Nix flake) and a **Windows** machine, from a single command, with
> secrets pulled from Bitwarden.

![NixOS](https://img.shields.io/badge/NixOS-5277C3?logo=nixos&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-0078D6?logo=windows&logoColor=white)
![chezmoi](https://img.shields.io/badge/chezmoi-managed-1A1A1A)
![Nushell](https://img.shields.io/badge/shell-Nushell-4E9A06)
![Neovim](https://img.shields.io/badge/editor-Neovim_(LazyVim)-57A143?logo=neovim&logoColor=white)

## Highlights

- **One tree, two operating systems.** OS- and distro-specific behaviour is handled with chezmoi templates,
  a templated `.chezmoiignore`, and per-platform scripts.
- **NixOS from a flake.** `flake.nix` and `.nix/` describe the whole system (packages, services, desktop).
  Stable `nixpkgs` and `nixpkgs-unstable` are both pinned, so any package can move between channels without
  touching the flake.
- **Automatic rebuilds.** The install script embeds the hashes of every Nix file. Editing the system config
  and running `chezmoi apply` triggers `nixos-rebuild switch` by itself.
- **Automated package installs elsewhere:** **winget** and **Chocolatey** on Windows, **Homebrew** on
  non-NixOS Linux, all from one list in `.chezmoidata/packages.yaml`.
- **No secrets in the repo.** SSH keys and tokens are fetched at apply time from **Bitwarden Secrets
  Manager** (`bws`), using a single access token that is prompted for once.
- **Live-editable configs.** Tools that rewrite their own config (Neovim lock files, jj, zellij, Windows
  Terminal) are symlinked back into the repo, so changes made from the app are tracked automatically.
- **One keyboard layout everywhere.** A single [kanata](https://github.com/jtroo/kanata) layout with
  **home-row mods** and caps-lock as Esc is shared by the Windows config and the NixOS kanata service.

## What's inside

| Area | Tools |
| --- | --- |
| Shell & prompt | [Nushell](https://www.nushell.sh/), [Starship](https://starship.rs/), [carapace](https://carapace.sh/) completions, zoxide, fzf |
| Editor | [Neovim](https://neovim.io/) with [LazyVim](https://www.lazyvim.org/) and custom plugin specs |
| Terminal & multiplexer | Ghostty, WezTerm, Windows Terminal, [Zellij](https://zellij.dev/) |
| Version control | [Jujutsu (jj)](https://github.com/jj-vcs/jj) colocated with git, lazygit, GitHub CLI |
| Linux desktop | [niri](https://github.com/YaLTeR/niri) scrolling Wayland compositor with DankMaterialShell, greetd |
| Windows desktop | [komorebi](https://github.com/LGUG2Z/komorebi) + whkd tiling window manager, GlazeWM |
| Keyboard | [kanata](https://github.com/jtroo/kanata) (home-row mods, layers) |
| Secrets | Bitwarden Secrets Manager |

## Installation

### 1. Install chezmoi

```bash
# Windows
winget install twpayne.chezmoi -s winget --accept-package-agreements --accept-source-agreements -h

# Linux (snap)
snap install chezmoi --classic

# NixOS (temporary shell)
nix-shell -p chezmoi
```

### 2. Apply the configuration

```bash
chezmoi init --apply reathe
```

On first run you will be asked for a `BWS_ACCESS_TOKEN` (Bitwarden Secrets Manager), unless it is already set
in the environment. chezmoi then:

1. installs the `bws` CLI if needed (non-NixOS),
2. installs packages (`nixos-rebuild switch` on NixOS, winget/choco on Windows, Homebrew on other Linux
   distributions),
3. renders the templates (pulling secrets from Bitwarden) and writes the config files into `$HOME`,
4. authenticates the GitHub CLI.

### 3. Keep it up to date

```bash
chezmoi update        # pull the latest changes and apply them
chezmoi diff          # preview what would change
```

On NixOS, the system can also be rebuilt directly from the source directory:

```bash
sudo nixos-rebuild switch --flake ~/.local/share/chezmoi#nixos
```

## Repository layout

```
.
├── .chezmoi.yaml.tmpl        # chezmoi config: secret prompt, per-OS hooks & interpreters
├── .chezmoiignore            # Templated: which files exist on which OS / distro
├── .chezmoidata/packages.yaml# Package lists (Windows winget/choco, Linux Homebrew)
├── .chezmoitemplates/        # Shared fragments (e.g. the kanata keyboard layout)
├── flake.nix, flake.lock     # NixOS flake (nixpkgs stable + unstable)
├── .nix/
│   ├── hosts/<host>/         # Per-machine NixOS config + hardware
│   └── modules/              # Shared system (common.nix) and user (raf-user.nix) modules
├── dot_config/               # → ~/.config (nvim, nushell, zellij, jj, niri, wezterm, ghostty, …)
├── dot_ssh/                  # → ~/.ssh (keys rendered from Bitwarden)
├── AppData/, dot_glzr/       # Windows-only targets
└── run_*                     # Install / setup scripts run by chezmoi
```

For more detail on how the pieces fit together, see [`CLAUDE.md`](CLAUDE.md) / [`AGENTS.md`](AGENTS.md).
