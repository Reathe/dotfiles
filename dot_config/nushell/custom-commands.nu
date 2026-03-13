# Updates Vencord install
export def "update vencord" [] {
  cd ~/code/Vencord
  git stash
  git pull
  pnpm i
  pnpm build
  pnpm inject
}

# refreshenv
export def --env refreshpath [] {
  # TODO: don't execute the command for non windows hosts
  let machine_path = (powershell -command "[Environment]::GetEnvironmentVariable('PATH', 'Machine')" | str trim | split row ";")
  let user_path = (powershell -command "[Environment]::GetEnvironmentVariable('PATH', 'User')" | str trim | split row ";")
  $env.PATH = ($machine_path | append $user_path | append $env.PATH | uniq -i)
}

export def fd [...args] {
  try {
    ^fd ...$args
  } catch {|err|
    rg --files | rg ...$args
  }
}
