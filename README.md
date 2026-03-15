# dotfiles

## Installation

### Download chezmoi

With snap

```bash
snap install chezmoi --classic
```

With winget (windows)

```bash
winget install twpayne.chezmoi -s winget --accept-package-agreements --accept-source-agreements -h
```

With Nix (spawning a shell with chezmoi)

```bash
nix-shell -p chezmoi
```

### Copy the config

`BWS_ACCESS_TOKEN` will be asked the first time if the environment variable is not set

```bash
chezmoi init --apply reathe
```

## Update config

```bash
chezmoi update
```
