#!/usr/bin/env python3
# claude-islamic-statuses renderer. Invoked by statusline.sh as:
#   python3 cis_render.py <repo_dir>
# Prints one status line: a spinner + a hadith that scrolls (marquee) when it's
# wider than the terminal. Rendering in python keeps multibyte text (the ﷺ
# glyph, em dash) measured/sliced by character. Reads the status-line JSON from
# stdin NON-BLOCKINGLY (so it can never hang), only to learn the terminal width.
import os, sys, time, json, select

script_dir = sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(os.path.abspath(__file__))
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

# --- terminal width: status-line JSON (read safely) -> COLUMNS -> 80 ---
raw = ""
try:
    if select.select([0], [], [], 0.1)[0]:
        raw = os.read(0, 65536).decode("utf-8", "ignore")
except Exception:
    pass
cols = 0
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
