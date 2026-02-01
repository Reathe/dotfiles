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
bw login bachourian@gmail.com
$env:BW_SESSION = bw unlock --raw
chezmoi init --apply reathe
```

## Update config

```bash
chezmoi update
```

