#!/usr/bin/env bash
# setup-statusline.sh — run by the plugin's SessionStart hook.
#
# A Claude Code plugin cannot directly own the primary `statusLine`
# (anthropics/claude-code#64074), and ${CLAUDE_PLUGIN_ROOT} doesn't expand in
# the statusLine execution context. The working pattern is this: on every
# session start, resolve the plugin's *absolute* path and pin it into the user's
# settings.json. Because plugin paths can change on update, re-pinning each
# session keeps it correct (self-healing).
#
# This script is deliberately:
#   - idempotent : writes settings.json only when the path actually changes
#   - silent     : prints nothing on success (no SessionStart noise)
#   - safe       : never fails the session, never clobbers unparseable settings

set -uo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-}"
[ -n "$PLUGIN_ROOT" ] || exit 0

CMD="$PLUGIN_ROOT/statusline.sh"
SETTINGS="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json"

# Need python3 to edit JSON safely; if it's missing, do nothing rather than risk
# corrupting settings.json.
command -v python3 >/dev/null 2>&1 || exit 0

# Make sure the bundled scripts are executable (git usually preserves this).
chmod +x "$CMD" "$PLUGIN_ROOT/refresh-hadiths.sh" 2>/dev/null || true

CMD="$CMD" SETTINGS="$SETTINGS" python3 - <<'PY' || true
import json, os

cmd, path = os.environ["CMD"], os.environ["SETTINGS"]
os.makedirs(os.path.dirname(path), exist_ok=True)

data = {}
if os.path.exists(path):
    try:
        with open(path) as f:
            data = json.load(f)
    except Exception:
        raise SystemExit(0)  # don't touch an unparseable settings file

desired = {"type": "command", "command": cmd}
if data.get("statusLine") == desired:
    raise SystemExit(0)  # already correct — write nothing

data["statusLine"] = desired
tmp = path + ".tmp"
with open(tmp, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
os.replace(tmp, path)  # atomic
PY

exit 0
