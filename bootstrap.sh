#!/usr/bin/env bash
# bootstrap.sh — install claude-islamic-statuses without cloning by hand.
# Clones (or updates) the repo to a stable location, then runs install.sh.
#
# Recommended — read it first, then run:
#   curl -fsSL https://raw.githubusercontent.com/kenanbalija/claude-islamic-statuses/main/bootstrap.sh -o bootstrap.sh
#   less bootstrap.sh
#   bash bootstrap.sh
#
# Convenient — only if you trust the source:
#   curl -fsSL https://raw.githubusercontent.com/kenanbalija/claude-islamic-statuses/main/bootstrap.sh | bash

set -euo pipefail

REPO_SLUG="kenanbalija/claude-islamic-statuses"
REPO_URL="https://github.com/$REPO_SLUG.git"
TARBALL="https://github.com/$REPO_SLUG/archive/refs/heads/main.tar.gz"
DEST="${CLAUDE_ISLAMIC_STATUSES_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/claude-islamic-statuses}"

echo "claude-islamic-statuses bootstrap"
echo "  target: $DEST"
echo

if [ -d "$DEST/.git" ]; then
  echo "Already installed — updating..."
  git -C "$DEST" pull --ff-only
else
  # Fresh install: clone with git, or fall back to a tarball if git is absent.
  rm -rf "$DEST"
  mkdir -p "$(dirname "$DEST")"
  if command -v git >/dev/null 2>&1; then
    git clone --depth 1 "$REPO_URL" "$DEST"
  else
    echo "git not found — downloading tarball..."
    mkdir -p "$DEST"
    curl -fsSL "$TARBALL" | tar -xz -C "$DEST" --strip-components=1
  fi
fi

echo
exec bash "$DEST/install.sh"
