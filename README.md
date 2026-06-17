# spinner-ads

An animated Claude Code status line: a spinner that animates while Claude works,
plus a rotating **authentic hadith** shown at the bottom of the terminal.

(The project is still named `spinner-ads` from its mock-ad origins — see git
history. It now shows hadiths instead of ads. `ads.txt` is kept as a legacy
example and is no longer read.)

## How it works

Claude Code lets you replace the bottom status line with the output of any
command (`statusLine` in `settings.json`). It calls that command repeatedly to
re-render — frequently while Claude is generating.

- **`statusline.sh`** is that command. It bumps a tick counter
  (`~/.spinner-ads/tick`) each render to pick the braille spinner frame (so it
  animates), and rotates to a different hadith every 30 seconds of wall-clock
  time (so each one stays readable). It **never hits the network** — it only
  reads `hadiths.txt`.
- **`refresh-hadiths.sh`** populates `hadiths.txt` from the
  [fawazahmed0/hadith-api](https://github.com/fawazahmed0/hadith-api) (free, no
  API key). It pulls **Sahih al-Bukhari + Sahih Muslim** — the two *Sahihayn*,
  authentic by scholarly consensus — keeps only short, one-line-friendly
  hadiths, and tags each with its collection + number so it's verifiable.

No external dependencies beyond `bash`, `curl`, `python3`, and `grep` — all
present on a stock macOS.

### Why only Bukhari & Muslim?

You asked for **confirmed** hadiths only. Rather than trust per-hadith grade
fields (quality varies across datasets), this restricts the pool to the two
collections whose contents are graded *sahih* by consensus. Every line is
authentic by construction.

> Note: the API edition is **English** (it has no Bosnian edition). To switch to
> Bosnian later, point `refresh-hadiths.sh` at a Bosnian source, or drop Bosnian
> lines straight into `hadiths.txt` (same `text  — Collection N` format).

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

(Already wired up on this machine.) Restart or start a Claude Code session; the
hadith line shows at the bottom and the spinner animates while Claude works.

## Refresh the hadith pool

```bash
./refresh-hadiths.sh        # re-pull Bukhari + Muslim into hadiths.txt
```

Run it whenever; it overwrites `hadiths.txt`. To keep it fresh automatically,
schedule it (cron/launchd) — ask and I'll set that up.

## Test it without enabling

```bash
echo '{}' | ./statusline.sh                                  # render once
for i in $(seq 1 20); do echo '{}' | ./statusline.sh; sleep 0.2; done   # watch spinner
```

## Customize

- **Length filter:** `MINLEN` / `MAXLEN` in `refresh-hadiths.sh` (shorter max =
  safer fit on narrow terminals).
- **Collections:** add more `fetch <slug> <label>` lines in `refresh-hadiths.sh`
  (slugs from the API's `editions.json`). Keep them authentic.
- **Rotation speed:** `ROTATE_SECONDS` in `statusline.sh`.
- **Spinner style:** the `frames=` line in `statusline.sh`.
