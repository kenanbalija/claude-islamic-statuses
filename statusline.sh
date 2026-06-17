#!/usr/bin/env bash
# spinner-ads — an animated Claude Code status line that shows a spinner plus a
# rotating authentic hadith.
#
# Claude Code calls this command repeatedly to render the bottom status line
# (passing session JSON on stdin, which we ignore). Each call advances a tick
# counter so the spinner glyph animates while Claude works; the hadith rotates
# on a wall-clock timer so each one stays on screen long enough to read.
#
# It never touches the network — it only reads hadiths.txt, which
# refresh-hadiths.sh populates from the hadith API.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
DATA_FILE="$SCRIPT_DIR/hadiths.txt"

# --- per-render tick counter (drives the spinner animation) ----------------
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

# --- load hadiths (skip blanks + # comments) -------------------------------
ITEMS=()
while IFS= read -r line; do
  ITEMS+=("$line")
done < <(grep -v -e '^[[:space:]]*$' -e '^[[:space:]]*#' "$DATA_FILE" 2>/dev/null)
num_items=${#ITEMS[@]}

if [ "$num_items" -eq 0 ]; then
  printf '%s  (no hadiths yet — run %s/refresh-hadiths.sh)\n' "$frame" "$SCRIPT_DIR"
  exit 0
fi

# --- rotate to a new hadith every ROTATE_SECONDS of wall-clock time --------
ROTATE_SECONDS=30
now="$(date +%s)"
item_index=$(((now / ROTATE_SECONDS) % num_items))
item="${ITEMS[$item_index]}"

# --- final status line: spinner + hadith -----------------------------------
printf '%s  %s\n' "$frame" "$item"
