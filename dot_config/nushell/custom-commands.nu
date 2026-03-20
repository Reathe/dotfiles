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
  if $nu.os-info.name != "windows" {
    error make {msg: "Windows only command"}
  }

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

export def zjz [] {
  let all_sessions = try { zellij ls }
  let session = try { $all_sessions | fzf --ansi --select-1 --exit-0 | split row ' ' | get 0? }

  if ($session | is-not-empty) {
    zellij attach $session
  } else {
    zellij --layout welcome attach --create welcome
  }
}
