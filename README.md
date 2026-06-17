# claude-islamic-statuses

An animated status line for [Claude Code](https://claude.com/claude-code): a
spinner that animates while Claude is working, with a rotating **authentic
hadith** shown along the bottom of your terminal.

```
⠹  Narrated Abu Huraira: Allah's Messenger (ﷺ) said, "The strong is not the one who overcomes people by his strength..."  — Bukhari 6114
```

The spinner advances as Claude generates; the hadith rotates periodically, and
any hadith longer than your terminal is wide **scrolls** right-to-left so you can
read the whole thing on one line. It runs entirely locally — no API key, no
account, no network calls during rendering.

The hadiths are also **curated to uplifting themes** (mercy, kindness, charity,
sincerity, knowledge, patience, gratitude, good character, dhikr) and filtered to
avoid sensitive or easily-misread-out-of-context narrations.

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

### Install as a Claude Code plugin

If you use Claude Code's plugin system, install it from inside Claude Code — no
manual setup:

```text
/plugin marketplace add kenanbalija/claude-islamic-statuses
/plugin install islamic-statuses@kenanbalija
```

The plugin uses a `SessionStart` hook to point your `statusLine` at the installed
copy automatically (idempotent — it only writes `settings.json` when the path
changes). Start a **new** Claude Code session for the status line to appear.

> **Heads up (upstream limitation):** Claude Code plugins can't yet own the
> primary `statusLine` directly
> ([#64074](https://github.com/anthropics/claude-code/issues/64074)) — that's why
> the `SessionStart` hook is used. One consequence: `/plugin uninstall
> islamic-statuses` leaves the `statusLine` entry behind in `settings.json`
> (pointing at a removed folder). After uninstalling, remove that `statusLine`
> block manually or run this repo's `./uninstall.sh`.

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
| `statusline.sh` | The command Claude Code calls. Advances a tick counter (`~/.claude-islamic-statuses/tick`) for the spinner frame, picks a hadith on a wall-clock timer, and prints one line — scrolling it as a marquee if it's wider than the terminal. Renders via `python3` for correct multibyte (ﷺ / em-dash) slicing. Reads only the local cache. |
| `refresh-hadiths.sh` | Downloads the collections from the hadith API, drops abbreviated/cross-reference stubs, curates to uplifting themes, de-dupes, and writes `hadiths.txt`. |

To make long hadiths scroll even while Claude is idle, the status line is
configured with `"refreshInterval": 1` (re-render once a second). Remove it to
scroll only while Claude is working.

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

- **Hadith length** — `MINLEN` / `MAXLEN` in `refresh-hadiths.sh`. With marquee
  scrolling, a higher `MAXLEN` keeps fuller hadiths (they just scroll).
- **Themes** — the `UPLIFTING` / `SENSITIVE` keyword lists at the top of
  `refresh-hadiths.sh` decide what's kept. Tune them to taste (heuristic, not
  scholarly classification).
- **Collections** — add `fetch <slug> <label>` lines in `refresh-hadiths.sh`
  (slugs come from the API's `editions.json`). Keep them authentic.
- **Scroll speed & rotation** — set env vars `CIS_CPS` (scroll chars/second,
  default 8) and `CIS_DWELL` (seconds per hadith, default 55). Put them in your
  shell profile or in settings.json `env`, e.g. `"env": { "CIS_CPS": "12" }`.
  Defaults live in `cis_render.py`. `refreshInterval` (settings.json) sets the
  idle re-render rate (min 1s), which caps how often it steps when you're idle.
- **Spinner style** — the `FRAMES` string in `statusline.sh`.

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
