#!/usr/bin/bash

DOTDIR=$HOME/projects/dotfiles
XDG_CONFIG_HOME=$HOME/.config
XDG_DATA_HOME=$HOME/.local/share

# alacritty
if [ ! -e $XDG_CONFIG_HOME/alacritty/alacritty.yml ]; then
  mkdir -p --verbose $XDG_CONFIG_HOME/alacritty
  ln -s --verbose $DOTDIR/alacritty/alacritty.yml $XDG_CONFIG_HOME/alacritty/
fi

# bash
if [ ! -L $HOME/.bashrc ]; then
  # if default .bashrc exists, remove it
  if [ -f $HOME/.bashrc ]; then
    rm -rf --verbose $HOME/.bashrc
  fi

  ln -s --verbose $DOTDIR/bash/.bashrc.ubuntu $HOME/.bashrc
  # mkdir for bash history
  mkdir -p --verbose $XDG_DATA_HOME/bash
fi

# git
if [ ! -e $XDG_CONFIG_HOME/git/config ]; then
  mkdir -p --verbose $XDG_CONFIG_HOME/git
  ln -s --verbose $DOTDIR/git/config $XDG_CONFIG_HOME/git/
fi

# gitui
if [ ! -e $XDG_CONFIG_HOME/gitui/key_bindings.ron ]; then
  mkdir -p --verbose $XDG_CONFIG_HOME/gitui
  ln -s --verbose $DOTDIR/gitui/key_bindings.ron $XDG_CONFIG_HOME/gitui/
fi

# nvim
if [ ! -e $XDG_CONFIG_HOME/nvim/init.lua ]; then
  mkdir -p --verbose $XDG_CONFIG_HOME/nvim
  ln -s --verbose $DOTDIR/nvim/init.lua $XDG_CONFIG_HOME/nvim/
  if [ ! -e ~/.local/share/nvim/site/pack/packer/start/packer.nvim ]; then
    git clone --depth 1 https://github.com/wbthomason/packer.nvim\
     ~/.local/share/nvim/site/pack/packer/start/packer.nvim
  fi
fi

# python
if [ ! -e $XDG_CONFIG_HOME/python/startup.py ]; then
  mkdir -p --verbose $XDG_CONFIG_HOME/python
  ln -s --verbose $DOTDIR/python/startup.py $XDG_CONFIG_HOME/python/
fi

# ranger
if [ ! -e $XDG_CONFIG_HOME/ranger/rc.conf ]; then
  mkdir -p --verbose $XDG_CONFIG_HOME/ranger
  ln -s --verbose $DOTDIR/ranger/* $XDG_CONFIG_HOME/ranger/
fi

# readline
if [ ! -e $HOME/.inputrc ]; then
  ln -s --verbose $DOTDIR/readline/.inputrc $HOME/
fi

# tmux
if [ ! -e $XDG_CONFIG_HOME/tmux/tmux.conf ]; then
  mkdir -p --verbose $XDG_CONFIG_HOME/tmux
  ln -s --verbose $DOTDIR/tmux/tmux.conf $XDG_CONFIG_HOME/tmux/
fi

# xkeysnail
if [ ! -e $XDG_CONFIG_HOME/xkeysnail/config.py ]; then
  mkdir -p --verbose $XDG_CONFIG_HOME/xkeysnail
  ln -s --verbose $DOTDIR/xkeysnail/config.py $XDG_CONFIG_HOME/xkeysnail/
  # xkeysnail autostart
  sudo groupadd uinput
  sudo usermod -aG input,uinput ${USER}
  sudo cp --verbose $DOTDIR/xkeysnail/*.rules /etc/udev/rules.d/
  mkdir -p --verbose $XDG_CONFIG_HOME/systemd/user
  ln -s --verbose $DOTDIR/xkeysnail/xkeysnail.service $XDG_CONFIG_HOME/systemd/user/
  systemctl --user enable xkeysnail.service
fi

# gnome settings
gsettings set org.gnome.shell.extensions.dash-to-dock hot-keys false
