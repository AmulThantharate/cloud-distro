#!/bin/sh
# Daily login banner for CloudDistro WSL2
# Displays /etc/godzilla.art once per calendar day on interactive login

# Ensure stdout is a terminal
[ -t 1 ] || return 0 2>/dev/null || exit 0

_ART="/etc/godzilla.art"
[ -f "$_ART" ] || return 0 2>/dev/null || exit 0

_TODAY="$(date +%Y-%m-%d 2>/dev/null)"
_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
_STAMP_FILE="$_CACHE_DIR/.godzilla_login_date"

# Display once per calendar day
if [ ! -f "$_STAMP_FILE" ] || [ "$(cat "$_STAMP_FILE" 2>/dev/null)" != "$_TODAY" ]; then
    mkdir -p "$_CACHE_DIR" 2>/dev/null
    echo "$_TODAY" > "$_STAMP_FILE" 2>/dev/null
    # Green ANSI color for Godzilla, followed by reset
    printf '\033[32m'
    cat "$_ART"
    printf '\033[0m\n'
fi
