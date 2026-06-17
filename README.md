# claude-islamic-statuses

An animated status line for [Claude Code](https://claude.com/claude-code): a
spinner that animates while Claude is working, with a rotating **authentic
hadith** shown along the bottom of your terminal.

```
⠹  Narrated Abu Huraira: Allah's Messenger (ﷺ) said, "The strong is not the one who overcomes people by his strength..."  — Bukhari 6114
```

The spinner advances as Claude generates; the hadith changes every 30 seconds so
each one stays long enough to read. It runs entirely locally — no API key, no
account, no network calls during rendering.

## Features

- ✅ **Authentic only** — pulls exclusively from *Sahih al-Bukhari* and *Sahih
  Muslim* (the two *Sahihayn*), whose contents are graded *sahih* by scholarly
  consensus. Every line carries its collection + number so it's verifiable.
- ⚡ **Zero runtime dependencies on the network** — the status line reads a local
  cache; a separate script refreshes it on demand.
- 🪶 **Tiny & transparent** — a couple of short shell scripts. Nothing patches or
  injects into Claude Code; it only uses the supported `statusLine` hook.
- 🔧 **Easy to extend** — change collections, length limits, or rotation speed in
  one place.

## Requirements

- [Claude Code](https://claude.com/claude-code)
- `bash`, `curl`, `python3`, `grep` — all present on a stock macOS; on Linux
  install `python3`/`curl` if missing. Windows: use WSL.

## Install

```bash
git clone https://github.com/kenanbalija/claude-islamic-statuses.git
cd claude-islamic-statuses
./install.sh
```

Then start (or restart) Claude Code. `install.sh` will:

1. make the scripts executable,
2. fetch the hadiths into `hadiths.txt` (if not already present), and
3. add a `statusLine` to your Claude Code `settings.json` pointing at this clone
   — **merging** with your existing settings, never overwriting them.

It's safe to re-run (e.g. after moving the folder).

### One-line install (curl) — no `git clone` or Homebrew needed

The installer lives in this repo, so you can **read it before running it** — which
is the recommended way:

```bash
curl -fsSL https://raw.githubusercontent.com/kenanbalija/claude-islamic-statuses/main/bootstrap.sh -o bootstrap.sh
less bootstrap.sh        # inspect exactly what it will do
bash bootstrap.sh
```

Or, if you already trust the source, the convenient form:

```bash
curl -fsSL https://raw.githubusercontent.com/kenanbalija/claude-islamic-statuses/main/bootstrap.sh | bash
```

This clones the repo to `~/.local/share/claude-islamic-statuses` (override with
`CLAUDE_ISLAMIC_STATUSES_DIR`), runs `install.sh`, and falls back to a tarball
download if you don't have `git`. Re-run it any time to update.

> Piping a script straight into your shell runs code you haven't read. That's
> fine when you trust the source and it's auditable (this one is — it's right
> here), but the inspect-first form above is the safer habit in general.

### Manual install

If you'd rather not run the script, add this to `~/.claude/settings.json`
(use the absolute path to *your* clone):

```json
{
  "statusLine": {
    "type": "command",
    "command": "/absolute/path/to/claude-islamic-statuses/statusline.sh"
  }
}
```

Then run `./refresh-hadiths.sh` once to create `hadiths.txt`.

## Updating the hadiths

```bash
./refresh-hadiths.sh
```

Re-pulls Bukhari + Muslim and rewrites `hadiths.txt`. The set is fixed, so you
only need this to pick up changes. To keep it fresh automatically, schedule it
with `cron` or a launchd agent.

## How it works

Claude Code renders its bottom status line by running a command you configure
and displaying the output, re-running it on activity. Two scripts:

| Script | Role |
|--------|------|
| `statusline.sh` | The command Claude Code calls. Advances a tick counter (`~/.claude-islamic-statuses/tick`) for the spinner frame, picks a hadith by a 30-second wall-clock timer, prints one line. Reads only the local cache. |
| `refresh-hadiths.sh` | Downloads the collections from the hadith API, keeps short one-line-friendly hadiths, de-dupes, and writes `hadiths.txt`. |

Because the status line never makes network calls, it stays instant and works
offline once the cache exists.

## Authenticity & source

Hadith text comes from the open
[fawazahmed0/hadith-api](https://github.com/fawazahmed0/hadith-api) (no API key).
Rather than rely on per-hadith grade fields (whose quality varies across
datasets), this project restricts the pool to the two collections that are
authentic by consensus — so a line can't be weak (*da'if*) by construction.
Each entry keeps its `— Collection Number` reference for verification.

> **Language:** the API edition used is **English** — it has no Bosnian edition.
> To use another language, point `refresh-hadiths.sh` at a different source, or
> add your own lines directly to `hadiths.txt` in the same
> `text  — Collection N` format.

## Customize

All knobs live at the top of the two scripts:

- **Hadith length** — `MINLEN` / `MAXLEN` in `refresh-hadiths.sh` (lower max =
  safer fit on narrow terminals).
- **Collections** — add `fetch <slug> <label>` lines in `refresh-hadiths.sh`
  (slugs come from the API's `editions.json`). Keep them authentic.
- **Rotation speed** — `ROTATE_SECONDS` in `statusline.sh`.
- **Spinner style** — the `frames=` line in `statusline.sh`.

## Uninstall

```bash
./uninstall.sh
```

Removes the `statusLine` from your settings (only if it points at this repo) and
leaves everything else intact. Then delete the folder. If you installed via the
curl one-liner, the folder is `~/.local/share/claude-islamic-statuses`, so run
`~/.local/share/claude-islamic-statuses/uninstall.sh`.

## Credits

- Hadith data: [fawazahmed0/hadith-api](https://github.com/fawazahmed0/hadith-api)
- Built for [Claude Code](https://claude.com/claude-code)

## License

[MIT](./LICENSE) © Kenan Balija

---

*Please use respectfully. Hadith texts are sacred to Muslims; this tool surfaces
short narrations with their references so they can be looked up in full.*
