# xremap

Key remapping on Ubuntu with [xremap](https://github.com/xremap/xremap),
run as a system service (root, for access to the input devices).

- `config.ubuntu<version>.yml`: per Ubuntu version config, linked as
  `~/.config/xremap/config.yml`.
- `xremap@.service`: systemd template unit. The instance name is the user
  whose `~/.local/bin/xremap` and `~/.config/xremap/config.yml` are used,
  so the file needs no per-machine edits.

## Setup

```sh
mkdir -p ~/.config/xremap
ln -s ~/projects/dotfiles/xremap/config.ubuntu$(. /etc/os-release && echo ${VERSION_ID//./}).yml \
  ~/.config/xremap/config.yml
~/projects/dotfiles/xremap/install-service.sh
```

[`install-service.sh`](install-service.sh) links `xremap@.service` into
`/etc/systemd/system`, then enables and starts `xremap@$USER.service`.
It is idempotent.

## Migrating from `xremap.service`

The unit used to be `xremap.service` with the home path written in it.
After pulling the rename, the old `/etc/systemd/system/xremap.service`
symlink is dangling and xremap will not start on the next boot. Run the
same script; it stops the old unit, removes its symlinks (including the
`multi-user.target.wants` one and a stale `~/.config/xremap/xremap.service`),
and switches to the template unit:

```sh
~/projects/dotfiles/xremap/install-service.sh
```
