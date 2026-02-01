# dotfiles

## Installation 

### Download chezmoi
With snap
```bash
snap install chezmoi --classic
```
With winget (windows)
```bash
winget install twpayne.chezmoi Bitwaden.CLI -s winget --accept-package-agreements --accept-source-agreements -h
```
### Copy config powershell
```bash

chezmoi init --apply reathe
```

## Update config

```bash
chezmoi update
```

