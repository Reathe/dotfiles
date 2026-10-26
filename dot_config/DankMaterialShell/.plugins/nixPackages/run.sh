#!/bin/sh
# Terminal side of the nixPackages plugin. When an action fails, a notification offers the output to a coding agent,
# the way Omarchy does: clicking it opens the agent (plugin settings) in the repo with a prompt about the failure.
#   run.sh run <terminal> <nixpkg.nu args…>   run an action in this terminal, keeping a log of its output
#   run.sh notify <terminal> <prompt file> <what>   wait on the notification, detached from the closing terminal
#   run.sh ask <terminal> <prompt file>, ask-text <terminal> <what> <message>   the agent, in this terminal
set -u
dir=$(dirname "$(readlink -f "$0")")
mode=$1 term=$2
shift 2

case $mode in
run)
  # The args become a command line for script(1); the attr names in them come from search.nixos.org, so refuse
  # anything outside what nix attr names and nixpkg.nu's own words use rather than escape it.
  for a in "$@"; do
    case $a in '' | *[!A-Za-z0-9_.+:-]*) echo "Refusing odd argument: $a"; read -r _; exit 1 ;; esac
  done
  log=$(mktemp --tmpdir nixpkg.XXXXXX.log)
  # One window at a time: two overlapping rebuilds can activate a system built before the other's edit.
  # The lock is held for the script line only (-o: not by its children), so the notification below never holds it.
  lock=${XDG_RUNTIME_DIR:-/tmp}/nixpkg.lock
  flock -n "$lock" true || echo "Waiting for the other Nix packages window to close…"
  # script(1) keeps the terminal a terminal (sudo prompt, nvim, nix's progress) and records only output;
  # SHELL=/bin/sh because it runs the line with $SHELL, which may be nu
  SHELL=/bin/sh flock -o "$lock" script -qefc "nu '$dir/nixpkg.nu' $*" "$log"
  rc=$?
  if [ $rc -eq 0 ] || [ $rc -eq 130 ]; then
    rm -f "$log"
    # nvim closing is the end of an edit, anything else leaves its output to read
    [ "$1" = edit ] || [ $rc -eq 130 ] || { printf '\nPress Enter to close'; read -r _; }
    exit $rc
  fi
  prompt=$(nu "$dir/nixpkg.nu" report "$log" "$@")
  rm -f "$log"
  if command -v notify-send >/dev/null; then
    setsid -f sh "$0" notify "$term" "$prompt" "$*" </dev/null >/dev/null 2>&1
  else
    printf '\nInstall libnotify to be offered the agent; the prompt is in %s\n' "$prompt"
  fi
  printf '\nFailed. Press Enter to close'
  read -r _
  exit $rc
  ;;
notify)
  prompt=$1 what=$2
  agent=$(nu "$dir/nixpkg.nu" agent-name)
  # critical stays until clicked or dismissed; a click on the body runs the first action
  clicked=$(notify-send -a "Nix packages" -u critical -i dialog-error -A ask="Ask $agent" --wait \
    "nixpkg.nu $what failed" "Click to ask $agent about it")
  [ "$clicked" = ask ] && exec "$term" -e sh "$0" ask "$term" "$prompt"
  ;;
ask | ask-text)
  # the agent's own window: pause only if it could not start
  nu "$dir/nixpkg.nu" "$mode" "$@" || { printf '\nFailed. Press Enter to close'; read -r _; }
  ;;
esac
