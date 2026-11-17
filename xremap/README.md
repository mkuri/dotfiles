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
sudo ln -s ~/projects/dotfiles/xremap/xremap@.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now xremap@$USER.service
```

## Migrating from `xremap.service`

The unit used to be `xremap.service` with the home path written in it.
After pulling the rename, the old `/etc/systemd/system/xremap.service`
symlink is dangling and xremap will not start on the next boot. Switch
to the template unit:

```sh
sudo systemctl disable --now xremap.service
sudo rm -f /etc/systemd/system/xremap.service
rm -f ~/.config/xremap/xremap.service
sudo ln -s ~/projects/dotfiles/xremap/xremap@.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now xremap@$USER.service
```
