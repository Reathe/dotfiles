# Updates Vencord install
export def "update vencord" [] {
    cd ~/code/Vencord
    git pull
    pnpm i
    pnpm build
    pnpm inject
}

# unlock bitwarden for this session
export def --env bw-unlock [] {
    $env.BW_SESSION = (bw unlock --raw)
}

