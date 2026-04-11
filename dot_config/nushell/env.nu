# Nushell Environment Config File

# To load from a custom file you can use:
# source ($nu.default-config-dir | path join 'custom.nu')
source ($nu.default-config-dir | path join 'add_to_path.nu')

$env.EDITOR = "nvim"
$env.GIT_SSH = (which ssh | get path | get -o 0)

# Carapace autocompletion
$env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense' # optional
mkdir $"($nu.cache-dir)"
carapace _carapace nushell | save --force $"($nu.cache-dir)/carapace.nu"

# zoxide better cd
zoxide init --cmd cd nushell | save -f $"($nu.cache-dir)/.zoxide.nu"
