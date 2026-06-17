#!/usr/bin/env bash
# claude-islamic-statuses — animated Claude Code status line: a spinner plus a
# rotating hadith that SCROLLS horizontally (marquee) when it's longer than the
# terminal width, so the whole hadith is readable one line at a time.
#
# Rendering runs in python3 so multibyte text (the ﷺ glyph, the em dash) is
# measured and sliced by character, not bytes (macOS bash 3.2 slices by byte and
# would mangle them). Terminal width is read from the status-line JSON on stdin
# when Claude Code provides it, otherwise falls back to 80 columns.
#
# To scroll while Claude is idle too, set "refreshInterval": 1 on the statusLine
# in settings.json (the installer does this). Tunables (DWELL, CPS) are below.
#
# Reads only hadiths.txt (populated by refresh-hadiths.sh) — never the network.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

# Capture the status-line JSON (for terminal width) without hanging on a tty.
INPUT=""
if [ ! -t 0 ]; then INPUT="$(cat 2>/dev/null || true)"; fi

# Fallback if python3 is unavailable: first hadith, static, no scroll.
if ! command -v python3 >/dev/null 2>&1; then
  line="$(grep -v -e '^[[:space:]]*$' -e '^[[:space:]]*#' "$SCRIPT_DIR/hadiths.txt" 2>/dev/null | head -1)"
  printf '%s  %s\n' '⠿' "${line:-(no hadiths)}"
  exit 0
fi

SCRIPT_DIR="$SCRIPT_DIR" CC_STATUSLINE_INPUT="$INPUT" python3 <<'PY'
import os, sys, time, json

script_dir = os.environ["SCRIPT_DIR"]
data_file = os.path.join(script_dir, "hadiths.txt")
state_dir = os.path.join(os.path.expanduser("~"), ".claude-islamic-statuses")
try:
    os.makedirs(state_dir, exist_ok=True)
except Exception:
    pass
tick_file = os.path.join(state_dir, "tick")

# --- spinner frame (advances once per render) ---
try:
    tick = int(open(tick_file).read().strip() or "0")
except Exception:
    tick = 0
try:
    open(tick_file, "w").write(str(tick + 1))
except Exception:
    pass
FRAMES = "⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
spin = FRAMES[tick % len(FRAMES)]

# --- load hadiths ---
try:
    items = [l.rstrip("\n") for l in open(data_file, encoding="utf-8")
             if l.strip() and not l.lstrip().startswith("#")]
except Exception:
    items = []
if not items:
    print(f"{spin}  (no hadiths yet — run {script_dir}/refresh-hadiths.sh)")
    sys.exit(0)

# --- terminal width: status-line JSON -> COLUMNS -> 80 ---
cols = 0
raw = os.environ.get("CC_STATUSLINE_INPUT", "")
if raw:
    try:
        j = json.loads(raw)
        for k in ("width", "cols", "columns"):
            v = j.get(k)
            if isinstance(v, int) and v > 0:
                cols = v; break
        if not cols and isinstance(j.get("terminal"), dict):
            v = j["terminal"].get("width") or j["terminal"].get("cols")
            if isinstance(v, int) and v > 0:
                cols = v
    except Exception:
        pass
if not cols:
    try: cols = int(os.environ.get("COLUMNS") or 0)
    except Exception: cols = 0
if cols < 20:
    cols = 80

# --- tunables ---
DWELL = 55     # seconds each hadith is shown
CPS   = 4      # marquee scroll speed (characters per second)
GAP   = "      •      "

# CC_NOW overrides the clock (test hook only).
now = int(os.environ.get("CC_NOW") or time.time())
idx = (now // DWELL) % len(items)
text = items[idx]

avail = max(10, cols - 3)   # columns left after the "X  " spinner prefix
if len(text) <= avail:
    print(f"{spin}  {text}")
else:
    src = text + GAP
    off = ((now % DWELL) * CPS) % len(src)
    print(f"{spin}  {(src + src)[off:off + avail]}")
PY
