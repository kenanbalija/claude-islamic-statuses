#!/usr/bin/env bash
# uninstall.sh — remove this status line from your Claude Code settings.
# Only removes the statusLine if it currently points at this repo; otherwise
# it leaves your settings untouched.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
SETTINGS="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json"

REPO_DIR="$REPO_DIR" SETTINGS="$SETTINGS" python3 - <<'PY'
import json, os, sys

repo, path = os.environ["REPO_DIR"], os.environ["SETTINGS"]
cmd = os.path.join(repo, "statusline.sh")

if not os.path.exists(path):
    sys.exit("No settings file found — nothing to remove.")

with open(path) as f:
    data = json.load(f)

sl = data.get("statusLine")
if isinstance(sl, dict) and sl.get("command") == cmd:
    del data["statusLine"]
    with open(path, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")
    print("Removed statusLine.")
else:
    print("statusLine does not point at this repo — left your settings alone.")
PY

echo "Restart Claude Code to apply."
