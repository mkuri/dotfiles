#!/usr/bin/env bash
# Patch Chrome Remote Desktop to share the physical X11 session instead of
# spawning a virtual one. Idempotent; re-run after chrome-remote-desktop
# package upgrades, which overwrite the launcher.
set -euo pipefail

target=/opt/google/chrome-remote-desktop/chrome-remote-desktop
block="$(dirname "$(readlink -f "$0")")/mirror-patch.py"
marker="# dotfiles: mirror physical display"

if grep -qF "$marker" "$target"; then
  echo "Already patched: $target"
  exit 0
fi

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

awk -v blockfile="$block" '
  /^if __name__ == "__main__":/ && !done {
    while ((getline line < blockfile) > 0) print line
    print ""
    print ""
    done = 1
  }
  { print }
' "$target" >"$tmp"

if ! grep -qF "$marker" "$tmp"; then
  echo "Insertion point not found in $target; launcher layout changed?" >&2
  exit 1
fi
python3 -c 'import ast, sys; ast.parse(open(sys.argv[1]).read())' "$tmp"

sudo cp -n "$target" "$target.orig"
sudo install -m 755 -o root -g root "$tmp" "$target"
echo "Patched $target (original saved as $target.orig)"
