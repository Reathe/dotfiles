#!/usr/bin/env nu
# vim: ft=nu:
# What terminals run instead of nu (ghostty, Windows Terminal, WezTerm): repair the dead zellij sessions before the
# welcome screen can resurrect one, then become zellij, whose panes run nu (its default_shell). config.nu starts no
# zellij, so nu anywhere else (ssh, nvim, scripts) stays a plain shell.
source env.nu # zellij itself keeps EDITOR, GIT_SSH and the PATH additions, as when nu started it
use custom-commands.nu "zellij repair-sessions"

zellij repair-sessions
exec zellij --layout welcome attach --create welcome
