#!/usr/bin/env nu
# vim: ft=nu:

# The token is fetched when this runs (BWS_ACCESS_TOKEN comes from scriptEnv), not rendered in:
# `chezmoi diff` and `apply -v` print a script's rendered text
let res = try {
  bws secret get 90a30c12-3351-49be-9e4c-b3e400e715ef | from json | get value
  | gh auth login --with-token -p ssh -h github.com
  | complete
} catch {|err|
  # Fallback if the command fails to execute at all
  {exit_code: 1 stderr: $err.rendered stdout: $err.msg}
}

# Use string interpolation for a cleaner log entry
let timestamp = (date now | format date "%Y-%m-%dT%H:%M:%S")
let log_entry = $"($timestamp)|INFO|gh_auth.nu|($res)\n"
# Save the log
$log_entry | save --append .config/chezmoi/chezmoi.log
