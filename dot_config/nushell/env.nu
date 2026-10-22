# Nushell Environment Config File

# To load from a custom file you can use:
# source ($nu.default-config-dir | path join 'custom.nu')
source ($nu.default-config-dir | path join 'add_to_path.nu')

$env.EDITOR = "nvim"
$env.GIT_SSH = (which ssh | get path | get -o 0)
# nh bundles a search.nixos.org index version that goes stale; use the one the site uses (cached daily)
if (which nh | is-not-empty) {
  let idx = nu ($nu.default-config-dir | path join nh-search-index.nu)
  if $idx != "" { $env.NH_SEARCH_BACKEND_VERSION = $idx }
}

# Carapace autocompletion
$env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense' # optional
mkdir $"($nu.cache-dir)"
carapace _carapace nushell | save --force $"($nu.cache-dir)/carapace.nu"

# zoxide better cd
zoxide init --cmd cd nushell | save -f $"($nu.cache-dir)/.zoxide.nu"

# mise activation: per-project tools from mise.toml/.tool-versions on cd (`use`d in config.nu; no mise on NixOS)
if (which mise | is-not-empty) { mise activate nu | save -f ($nu.cache-dir | path join mise.nu) }
