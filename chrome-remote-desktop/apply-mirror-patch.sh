#!/usr/bin/env bash
# Patch Chrome Remote Desktop to share the physical X11 session instead of
# spawning a virtual one. Idempotent; re-run after chrome-remote-desktop
# package upgrades, which overwrite the launcher, or after editing
# mirror-patch.py, which re-patches from the saved original.
set -euo pipefail

target=/opt/google/chrome-remote-desktop/chrome-remote-desktop
block="$(dirname "$(readlink -f "$0")")/mirror-patch.py"
marker="# dotfiles: mirror physical display"

source=$target
if grep -qF "$marker" "$target"; then
  if [[ ! -f "$target.orig" ]] || grep -qF "$marker" "$target.orig"; then
    echo "Already patched and no clean $target.orig to re-patch from" >&2
    exit 1
  fi
  source=$target.orig
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
' "$source" >"$tmp"

if ! grep -qF "$marker" "$tmp"; then
  echo "Insertion point not found in $target; launcher layout changed?" >&2
  exit 1
fi
python3 -c 'import ast, sys; ast.parse(open(sys.argv[1]).read())' "$tmp"

if [[ "$source" == "$target" ]]; then
  sudo cp "$target" "$target.orig"
fi
sudo install -m 755 -o root -g root "$tmp" "$target"
echo "Patched $target (original saved as $target.orig)"
