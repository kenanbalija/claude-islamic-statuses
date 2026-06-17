#!/usr/bin/env bash
# spinner-ads — a mock "sponsored spinner" status line for Claude Code.
#
# Claude Code calls this command repeatedly to render the status line at the
# bottom of the terminal (passing session JSON on stdin, which we ignore for
# the MVP). Each call advances a tick counter, so the spinner glyph animates
# and the mock ad rotates. It refreshes often while Claude is working, so the
# spinner naturally "spins" during activity.
#
# Wire it up by pointing settings.json -> statusLine.command at this file.
# See README.md.

set -euo pipefail

# --- locate ourselves so we can find ads.txt regardless of cwd -------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
ADS_FILE="$SCRIPT_DIR/ads.txt"

# --- per-render tick counter (drives spinner frame + ad rotation) ----------
STATE_DIR="$HOME/.spinner-ads"
TICK_FILE="$STATE_DIR/tick"
mkdir -p "$STATE_DIR"

tick="$(cat "$TICK_FILE" 2>/dev/null || true)"
# guard against a missing/empty/corrupted state file
case "$tick" in
  ''|*[!0-9]*) tick=0 ;;
esac
printf '%s\n' "$((tick + 1))" > "$TICK_FILE"

# --- spinner frame ---------------------------------------------------------
# braille spinner; split on whitespace into an array (works on macOS bash 3.2)
frames='⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏'
read -ra FRAMES <<< "$frames"
num_frames=${#FRAMES[@]}
frame="${FRAMES[$((tick % num_frames))]}"

# --- load mock ads (skip blanks + # comments) ------------------------------
ADS=()
while IFS= read -r line; do
  ADS+=("$line")
done < <(grep -v -e '^[[:space:]]*$' -e '^[[:space:]]*#' "$ADS_FILE" 2>/dev/null)
num_ads=${#ADS[@]}

if [ "$num_ads" -eq 0 ]; then
  printf '%s  (no ads loaded — check %s)\n' "$frame" "$ADS_FILE"
  exit 0
fi

# rotate to the next ad every FRAMES_PER_AD renders
FRAMES_PER_AD=20
ad_index=$(((tick / FRAMES_PER_AD) % num_ads))
ad="${ADS[$ad_index]}"

# --- final status line -----------------------------------------------------
printf '%s  %s  · sponsored\n' "$frame" "$ad"
