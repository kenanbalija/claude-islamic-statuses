#!/usr/bin/env bash
# refresh-hadiths.sh — pull authentic hadiths and cache one-line-friendly ones
# to hadiths.txt. The status line only ever reads that cache; it never hits the
# network. Run this whenever you want to refresh the pool (e.g. via cron/launchd).
#
# Source: https://github.com/fawazahmed0/hadith-api  (free, no API key)
# We pull only Sahih al-Bukhari and Sahih Muslim — the two Sahihayn — whose
# contents are authentic (sahih) by scholarly consensus, so every hadith pulled
# here qualifies as "confirmed". Each line keeps its collection + number so it's
# verifiable.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
OUT="$SCRIPT_DIR/hadiths.txt"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

BASE="https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions"

# edition slug -> short attribution label
fetch() {
  local slug="$1" label="$2"
  echo "Fetching $slug ..." >&2
  curl -fsSL --max-time 90 "$BASE/$slug.json" -o "$TMP/$slug.json"
  printf '%s\t%s\n' "$slug" "$label" >> "$TMP/manifest"
}

fetch eng-bukhari "Bukhari"
fetch eng-muslim  "Muslim"

# Extract, clean, length-filter, de-dupe — write hadiths.txt.
MINLEN=40 MAXLEN=200 python3 - "$TMP" "$OUT" <<'PY'
import json, os, re, sys, glob
tmp, out = sys.argv[1], sys.argv[2]
minlen, maxlen = int(os.environ["MINLEN"]), int(os.environ["MAXLEN"])

# --- uplifting-themes curation (heuristic keyword pass; tune to taste) -------
# Keep a hadith only if it hits an UPLIFTING theme AND avoids every SENSITIVE
# one. SENSITIVE wins: a charity hadith that also mentions Hellfire is dropped.
# This is a keyword heuristic, not scholarly classification — edit freely.
UPLIFTING = re.compile(r"\b(" + "|".join([
    r"merc\w*", r"compassion\w*", r"kindness", r"kind-?hearted", r"kind to", r"gentle\w*",
    r"forgiv\w*", r"pardon\w*",
    r"charit\w*", r"alms\w*", r"generou\w*", r"generosity", r"feed the (poor|hungry|needy)",
    r"love[sd]?", r"loving", r"affection",
    r"patien\w*", r"gratitude", r"grateful", r"thankful",
    r"sincer\w*", r"intention[s]?",
    r"knowledge", r"wisdom",
    r"neighbou?r[s]?", r"parent[s]?", r"dutiful",
    r"kinship", r"orphan[s]?", r"guest[s]?",
    r"truthful", r"honest\w*", r"trustworth\w*", r"promise[sd]?",
    r"humble", r"humility", r"modest\w*",
    r"smil\w*", r"cheerful", r"righteous\w*", r"virtue",
    r"good (word|deed|deeds|manners|character|conduct)", r"best of you",
    r"remember\w* allah", r"remembrance of allah", r"glorif\w*", r"prais\w* (allah|his lord|the lord)",
    r"supplicat\w*", r"repent\w*",
    r"help[s]?", r"ease[sd]?", r"reliev\w*", r"relief",
    r"self-control", r"controls? himself", r"restrain\w*",
    r"trust in allah", r"rely on allah", r"reliance",
]) + r")\b", re.I)
SENSITIVE = re.compile(r"\b(" + "|".join([
    r"hell\w*", r"fire", r"blaz\w*", r"torment\w*", r"tortur\w*",
    r"punish\w*", r"chastis\w*", r"grave[s]?", r"grievous",
    r"kill\w*", r"murder\w*", r"slay", r"slain", r"blood\w*",
    r"stone[sd]?", r"stoning", r"lash\w*", r"whip\w*", r"flog\w*", r"amputat\w*",
    r"adulter\w*", r"fornicat\w*", r"zina", r"intercourse", r"menstru\w*",
    r"semen", r"urin\w*", r"f[ae]ces", r"impur\w*", r"najis",
    r"women would", r"woman is", r"deficient", r"minorit\w*", r"inmates",
    r"dajjal", r"antichrist", r"satan", r"devil[s]?", r"iblis",
    r"sorcer\w*", r"witch\w*", r"magic",
    r"war[s]?", r"battle[s]?", r"fight\w*", r"fought", r"army", r"armies", r"enem\w*",
    r"sword[s]?", r"spear[s]?", r"captive[s]?", r"booty", r"spoils",
    r"slave-?girl[s]?", r"slaver\w*",
    r"wine", r"alcohol\w*", r"intoxicant[s]?", r"khamr", r"drunk\w*",
    r"divorc\w*", r"curse[sd]?", r"cursing", r"wrath",
    r"hypocri\w*", r"disbelie\w*", r"apostat\w*", r"kufr", r"infidel[s]?", r"idol\w*",
]) + r")\b", re.I)

labels = {}
with open(os.path.join(tmp, "manifest")) as f:
    for line in f:
        slug, label = line.rstrip("\n").split("\t")
        labels[slug] = label

lines, seen = [], set()
for path in sorted(glob.glob(os.path.join(tmp, "*.json"))):
    slug = os.path.splitext(os.path.basename(path))[0]
    label = labels.get(slug, slug)
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    for h in data.get("hadiths", []):
        text = re.sub(r"\s+", " ", (h.get("text") or "")).strip()
        # The ﷺ ligature (U+FDFA) breaks in many terminal fonts — use ASCII.
        text = text.replace("(ﷺ)", "(saw)").replace("ﷺ", "(saw)")
        if not (minlen <= len(text) <= maxlen):
            continue
        # Skip source-abbreviated stubs / cross-references — these read as "cut"
        # (the elision is in the original data, not our truncation).
        low = text.lower()
        if ".." in text or "…" in text:
            continue
        if ("(see" in low or "(above)" in low or "(the above" in low
                or "related in the chapter" in low or "(this narration" in low
                or "(for this narration" in low):
            continue
        # Drop isnad-only / "same as another chain" meta entries (not content).
        if any(m in low for m in (
                "rest of the hadith", "another chain", "chain of transmitters",
                "same chain", "the same as", "with the same meaning",
                "has been transmitted", "as narrated above", "similar hadith",
                "with a slight variation", "like the one narrated",
                "the rest of the", "transmitted on the authority")):
            continue
        # Curate to uplifting themes (see UPLIFTING / SENSITIVE above).
        if SENSITIVE.search(low) or not UPLIFTING.search(low):
            continue
        key = low
        if key in seen:
            continue
        seen.add(key)
        lines.append(f"{text}  — {label} {h.get('hadithnumber')}")

with open(out, "w", encoding="utf-8") as f:
    f.write("# Authentic hadiths (Sahih al-Bukhari & Sahih Muslim) via fawazahmed0/hadith-api.\n")
    f.write("# Auto-generated by refresh-hadiths.sh — edits here are overwritten on refresh.\n")
    for ln in lines:
        f.write(ln + "\n")

print(f"Wrote {len(lines)} hadiths to {out}", file=sys.stderr)
PY
