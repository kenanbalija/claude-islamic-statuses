#!/usr/bin/env bash
# install.sh — set up claude-islamic-statuses as your Claude Code status line.
#
# Safe to re-run: it updates the path and preserves all your other settings.
# It will NOT overwrite a settings.json it can't parse.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
SETTINGS="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json"

echo "claude-islamic-statuses installer"
echo "  repo:     $REPO_DIR"
echo "  settings: $SETTINGS"
echo

chmod +x "$REPO_DIR/statusline.sh" "$REPO_DIR/refresh-hadiths.sh"

# Populate the hadith cache if there isn't a real (non-comment) line yet.
if ! grep -q '^[^[:space:]#]' "$REPO_DIR/hadiths.txt" 2>/dev/null; then
  echo "No cached hadiths found — fetching..."
  "$REPO_DIR/refresh-hadiths.sh"
  echo
fi

mkdir -p "$(dirname "$SETTINGS")"

# Merge the statusLine into settings.json without disturbing anything else.
REPO_DIR="$REPO_DIR" SETTINGS="$SETTINGS" python3 - <<'PY'
import json, os, sys

repo, path = os.environ["REPO_DIR"], os.environ["SETTINGS"]
cmd = os.path.join(repo, "statusline.sh")

data = {}
if os.path.exists(path):
    try:
        with open(path) as f:
            data = json.load(f)
    except Exception as e:
        sys.exit(f"ERROR: {path} is not valid JSON ({e}).\n"
                 f"Refusing to touch it. Add this statusLine yourself:\n"
                 f'  "statusLine": {{ "type": "command", "command": "{cmd}" }}')

data["statusLine"] = {"type": "command", "command": cmd}
with open(path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
print(f"Wired statusLine -> {cmd}")
PY

echo
echo "Done. Start or restart Claude Code to see your status line."
echo "Refresh the hadith pool any time with: $REPO_DIR/refresh-hadiths.sh"
