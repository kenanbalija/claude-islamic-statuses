#!/usr/bin/env python3
# claude-islamic-statuses renderer. Invoked by statusline.sh as:
#   python3 cis_render.py <repo_dir>
#
# Default mode "wrap": prints the spinner + the WHOLE hadith, word-wrapped across
# a few lines (each printed line is a separate status row).
# Mode "scroll": single-line marquee that scrolls long hadiths (CIS_MODE=scroll).
#
# Width comes from $COLUMNS (Claude Code sets it, v2.1.153+), then the status-line
# JSON on stdin (read non-blocking so it can never hang), then 80. Rendering in
# python keeps multibyte text (the ﷺ glyph, em dash) measured by character.
import os, sys, time, json, select, textwrap

def _envint(name, default):
    try:
        v = int(os.environ.get(name, ""))
        return v if v > 0 else default
    except Exception:
        return default

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

# --- terminal width: $COLUMNS -> status-line JSON -> 80 ---
try:
    cols = int(os.environ.get("COLUMNS") or 0)
except Exception:
    cols = 0
if not cols:
    raw = ""
    try:
        if select.select([0], [], [], 0.1)[0]:
            raw = os.read(0, 65536).decode("utf-8", "ignore")
    except Exception:
        pass
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
if cols < 20:
    cols = 80

# --- pick the current hadith ---
DWELL = _envint("CIS_DWELL", 55)   # seconds each hadith is shown
avail = max(10, cols - 3)          # columns after the "X  " spinner prefix
now = float(os.environ.get("CC_NOW") or time.time())   # CC_NOW = test hook
text = items[int(now // DWELL) % len(items)]
text = text.replace("(ﷺ)", "(saw)").replace("ﷺ", "(saw)")   # ASCII for broken-font terminals

mode = os.environ.get("CIS_MODE", "wrap").strip().lower()

if mode == "scroll":
    # single-line marquee
    CPS = _envint("CIS_CPS", 16)   # scroll speed (characters per second)
    GAP = "      •      "
    if len(text) <= avail:
        print(f"{spin}  {text}")
    else:
        src = text + GAP
        off = int((now % DWELL) * CPS) % len(src)
        print(f"{spin}  {(src + src)[off:off + avail]}")
else:
    # wrap (default): the whole hadith across a few lines
    maxlines = _envint("CIS_LINES", 4)
    lines = textwrap.wrap(text, width=avail) or [""]
    if len(lines) > maxlines:
        lines = lines[:maxlines]
        lines[-1] = lines[-1][:avail - 1].rstrip() + "…"
    print(f"{spin}  {lines[0]}")
    for ln in lines[1:]:
        print(f"   {ln}")            # indent continuation lines under the text
