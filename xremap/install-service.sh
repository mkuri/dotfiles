#!/usr/bin/env bash
# Install (or migrate to) the xremap@.service template unit for the current
# user. Replaces the old per-machine xremap.service if present. Idempotent.
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
  echo "Run as your normal user (sudo is used where needed)" >&2
  exit 1
fi

unit_src="$(dirname "$(readlink -f "$0")")/xremap@.service"
unit_dir=/etc/systemd/system
instance="xremap@$USER.service"

for f in "$HOME/.local/bin/xremap" "$HOME/.config/xremap/config.yml"; do
  if [[ ! -e $f ]]; then
    echo "Missing $f; see xremap/README.md (Setup)" >&2
    exit 1
  fi
done

# Old unit: stop it and remove its symlinks. It may already be dangling after
# the rename, so systemctl disable can't be relied on.
old="$unit_dir/xremap.service"
if [[ -e $old || -L $old || -L $unit_dir/multi-user.target.wants/xremap.service ]]; then
  sudo systemctl stop xremap.service || true
  sudo rm -fv "$old" "$unit_dir/multi-user.target.wants/xremap.service"
fi
# Stale link from an earlier setup.
if [[ -L $HOME/.config/xremap/xremap.service ]]; then
  rm -fv "$HOME/.config/xremap/xremap.service"
fi

sudo ln -sfnv "$unit_src" "$unit_dir/xremap@.service"
sudo systemctl daemon-reload
sudo systemctl enable --now "$instance"
sudo systemctl restart "$instance"

sleep 2
systemctl --no-pager --lines=5 status "$instance"
