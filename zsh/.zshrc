# env
export XDG_CONFIG_HOME=$HOME/.config
export XDG_CACHE_HOME=$HOME/.cache
export XDG_DATA_HOME=$HOME/.local/share

# history
HISTFILE=$XDG_DATA_HOME/zsh/history
HISTSIZE=100000
SAVEHIST=100000
setopt hist_ignore_all_dups
setopt share_history

# prompt
setopt prompt_subst
precmd() {
  git status --porcelain > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    export BRANCH_NAME=$(git branch --show-current 2>/dev/null)
    export GIT_INFO="(${BRANCH_NAME})"
  fi
}
## %n: user name
## %~: current directory from the home directory
## %F{}..%f: colorize
PROMPT='[%n %F{blue}%~%f] ${GIT_INFO}
%F{yellow}$%f '

# keybind
bindkey -e
autoload history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^P" history-beginning-search-backward-end
bindkey "^N" history-beginning-search-forward-end

# options
unsetopt beep

# completion
zstyle :compinstall filename '/home/makoto/.zshrc'
autoload -Uz compinit
compinit

# alias
alias ls="ls -la --color=auto"

# abbr
source $XDG_CONFIG_HOME/zsh/zsh-abbr/zsh-abbr.zsh
export ABBR_USER_ABBREVIATIONS_FILE=$XDG_CONFIG_HOME/zsh/abbreviations

# fzf
if [ -f "${XDG_CONFIG_HOME:-$HOME/.config}"/fzf/fzf.zsh ]; then
  source "${XDG_CONFIG_HOME:-$HOME/.config}"/fzf/fzf.zsh
fi

# nvim
if type nvim > /dev/null 2>&1; then
    export EDITOR=nvim
fi

# docker
export DOCKER_BUILDKIT=1
export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock

# python
export PYTHONSTARTUP=$XDG_CONFIG_HOME/python/startup.py

# rust
source $HOME/.cargo/env

# ros2
if [ $(lsb_release -rs) = 22.04 ]; then
  source /opt/ros/humble/setup.zsh
elif [ $(lsb_release -rs) = 20.04 ]; then
  source /opt/ros/galactic/setup.zsh
fi
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
export LD_LIBRARY_PATH="/usr/local/libtorch/lib:$LD_LIBRARY_PATH"
export RCUTILS_COLORIZED_OUTPUT=1
source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.zsh

# cuda
export PATH="/usr/local/cuda/bin:$PATH"
export LD_LIBRARY_PATH="/usr/local/cuda/lib64:$LD_LIBRARY_PATH"

# nodejs
export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
