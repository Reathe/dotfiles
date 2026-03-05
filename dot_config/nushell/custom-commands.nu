# Updates Vencord install
export def "update vencord" [] {
    cd ~/code/Vencord
    git stash
    git pull
    pnpm i
    pnpm build
    pnpm inject
}
