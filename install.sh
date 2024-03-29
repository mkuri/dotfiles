#!/usr/bin/bash

# base
sudo apt install -y git ranger curl tmux tig xsel

# nvim
if [ ! -e $HOME/.local/bin/nvim ]; then
  mkdir -p $HOME/.local/bin
  curl https://github.com/neovim/neovim/releases/download/stable/nvim.appimage -o $HOME/.local/bin/nvim
  chmod +x $HOME/.local/bin/nvim
  sudo apt install -y libfuse2
fi

# google-chrome
if [ ! -e /usr/bin/google-chrome ]; then
  curl -O https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
  sudo dpkg -i google-chrome-stable_current_amd64.deb
  rm -rf --verbose google-chrome-stable_current_amd64.deb
fi

# rust
if [ ! -e $HOME/.cargo ]; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  source $HOME/.cargo/env
fi
if [ ! -e $HOME/.cargo/bin/alacritty ]; then
  sudo apt install -y cmake pkg-config libfreetype6-dev libfontconfig1-dev libxcb-xfixes0-dev libxkbcommon-dev python3
  cargo install alacritty
  # desktop entry
  sudo cp $HOME/.cargo/bin/alacritty /usr/local/bin/
  sudo cp $HOME/.cargo/registry/src/github.com-1ecc6299db9ec823/alacritty-0.11.0/extra/logo/alacritty-term+scanlines.svg /usr/share/pixmaps/Alacritty.svg
  sudo desktop-file-install $HOME/.cargo/registry/src/github.com-1ecc6299db9ec823/alacritty-0.11.0/extra/linux/Alacritty.desktop
  sudo update-desktop-database
fi
if [ ! -e $HOME/.cargo/bin/rg ]; then
  cargo install ripgrep
fi
if [ ! -e $HOME/.cargo/bin/fd ]; then
  cargo install fd-find
fi
if [ ! -e $HOME/.cargo/bin/gitui ]; then
  cargo install gitui
fi
if [ ! -e $HOME/.cargo/bin/topgrade ]; then
  cargo install topgrade
fi

# fzf
if [ ! -e $HOME/.local/fzf ]; then
  git clone --depth 1 https://github.com/junegunn/fzf.git ~/.local/fzf
  ~/.local/fzf/install --xdg --key-bindings --completion --update-rc
fi

# xkeysnail
if [ ! -e /usr/local/bin/xkeysnail ]; then
  sudo apt install -y python3-pip python3-tk
  sudo pip3 install xkeysnail
fi

# nerd-fonts
if [ ! -e $HOME/.local/nerd-fonts ]; then
  git clone --depth 1 git@github.com:ryanoasis/nerd-fonts.git ~/.local/nerd-fonts
  ~/.local/nerd-fonts/install.sh DejaVuSansMono
fi

# mozc
sudo apt install -y ibus-mozc mozc-utils-gui

# mpv
sudo apt install -y mpv

# btop
curl -O https://github.com/aristocratos/btop/releases/download/v1.2.13/btop-x86_64-linux-musl.tbz
tar -Jxvf btop-x86_64-linux-musl.tbz
cd btop
make install --prefix=~/.local

# flatpak
sudo apt install -y flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub com.slack.Slack
flatpak install -y flathub im.riot.Riot
flatpak install -y flathub org.zulip.Zulip
flatpak install -y flathub us.zoom.Zoom
flatpak install -y flathub com.obsproject.Studio
flatpak install -y flathub org.gimp.GIMP
flatpak install -y flathub sa.sy.bluerecorder
flatpak install -y flathub net.ankiweb.Anki

# nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.2/install.sh | bash
