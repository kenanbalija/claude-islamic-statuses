# spinner-ads

A tiny, dependency-free **mock "sponsored spinner"** for the terminal. It renders
a Claude Code status line that animates a spinner and rotates through mock ads
while Claude works.

This is a toy/MVP. It does **not** earn money — there's no ad network, tracking,
or payouts. It just demonstrates the rendering surface (see "Going real" below).

## How it works

Claude Code lets you replace the bottom status line with the output of any
command (`statusLine` in `settings.json`). It calls that command repeatedly to
re-render — frequently while Claude is generating. `statusline.sh`:

1. Bumps a tick counter at `~/.spinner-ads/tick` on every render.
2. Uses the tick to pick the current braille spinner frame (so it animates).
3. Rotates to the next ad from `ads.txt` every ~20 renders.
4. Prints one line: `⠹  ShipFast — git push... → shipfast.example  · sponsored`

No external dependencies — just bash, `grep`, and `printf` (works with the
bash 3.2 that ships on macOS).

## Enable it

Point your Claude Code `statusLine` at the script. In `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "/Users/kenanbalija/spinner-ads/statusline.sh"
  }
}
```

Then start (or restart) Claude Code. The ad line shows at the bottom; the
spinner animates while Claude is working.

## Test it without enabling

```bash
# render once
echo '{}' | ./statusline.sh

# watch it animate + rotate
for i in $(seq 1 60); do echo '{}' | ./statusline.sh; sleep 0.2; done
```

## Customize

- **Ads:** edit `ads.txt` — one ad per line, `#` for comments.
- **Rotation speed:** change `FRAMES_PER_AD` in `statusline.sh` (higher = each
  ad lingers longer).
- **Spinner style:** edit the `frames=` line (e.g. `'| / - \'`).

## Going real (what's deliberately NOT here)

The hard 95% of something like kickbacks.ai is the backend, not this script:
an ad network (advertisers + inventory + an ad-serving endpoint), impression/
click tracking with anti-fraud, billing, and a payout pipeline. This project is
only the client-side rendering surface, with static local ads standing in for
all of that.
