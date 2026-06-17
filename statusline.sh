#!/usr/bin/env bash
# claude-islamic-statuses — animated Claude Code status line: a spinner plus a
# rotating hadith that scrolls (marquee) when wider than the terminal.
#
# The real renderer is cis_render.py (python3 — for correct multibyte slicing
# and non-blocking stdin). This wrapper just locates it and execs it, so the
# status-line JSON Claude Code pipes in is inherited on python's stdin.
#
# Reads only hadiths.txt (populated by refresh-hadiths.sh) — never the network.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

if command -v python3 >/dev/null 2>&1; then
  exec python3 "$SCRIPT_DIR/cis_render.py" "$SCRIPT_DIR"
fi

# Fallback when python3 is unavailable: first hadith, static, no scroll.
line="$(grep -v -e '^[[:space:]]*$' -e '^[[:space:]]*#' "$SCRIPT_DIR/hadiths.txt" 2>/dev/null | head -1)"
printf '%s  %s\n' '⠿' "${line:-(no hadiths)}"
