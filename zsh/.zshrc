# Lines configured by zsh-newuser-install
# history
HISTFILE=$XDG_DATA_HOME/zsh/histfile
HISTSIZE=10000
SAVEHIST=10000
setopt hist_ignore_all_dups
setopt share_history
bindkey -e

# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/makoto/.zshrc'

autoload -Uz compinit promptinit colors vcs_info
compinit
promptinit
colors
# End of lines added by compinstall

# UI
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr "%F{magenta}!"
zstyle ':vcs_info:git:*' unstagedstr "%F{magenta}+"
zstyle ':vcs_info:*' formats "%F{green}%c%u(%b)%f"
zstyle ':vcs_info:*' actionformats '[%b|%a]'

setopt prompt_subst
export VIRTUAL_ENV_DISABLE_PROMPT=1
precmd () {
  vcs_info
  PYTHON_VERSION_STRING='py:'$(python --version | awk '{print $2}')
  PYTHON_VIRTUAL_ENV_STRING=''
  if [ -n '$VIRTUAL_ENV' ]; then
    PYTHON_VIRTUAL_ENV_STRING=":`basename \"$VIRTUAL_ENV\"`"
  fi
}
PROMPT='[%F{green}%n%F{blue}@%c%{${reset_color}%}] %F{blue}${PYTHON_VERSION_STRING}${PYTHON_VIRTUAL_ENV_STRING}
%f${vcs_info_msg_0_}$ '

source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# completion
zstyle ':completion:*' format '%B%F{blue}%d%f%b'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*:sudo:*' command-path /usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin $HOME/bin

# keybind
autoload history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^P" history-beginning-search-backward-end
bindkey "^N" history-beginning-search-forward-end

# alias
alias ls='ls -la --color'
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias -g ffd='$(fd . $HOME/ --type d | fzf)'
alias -g fhd='$(fd . $HOME/ --type d --hidden | fzf)'
alias -g fcd='$(fd . ./ --type d --hidden | fzf)'
alias -g fad='$(fd . / --type d | fzf)'
alias j='cd ffd'
alias -g fff='$(fd . $HOME/ --type f | fzf)'
alias -g fhf='$(fd . $HOME/ --type f --hidden | fzf)'
alias -g fcf='$(fd . ./ --type f --hidden | fzf)'
alias -g faf='$(fd . / --type f | fzf)'
alias venv='source $(fd . $HOME/.local/share/venvs/ --type d --max-depth 1 | fzf)/bin/activate'

# options
setopt no_beep
setopt share_history

# fzf
source /usr/share/fzf/key-bindings.zsh
source /usr/share/fzf/completion.zsh
export FZF_DEFAULT_OPTS='--height 40% --reverse --border'

# python virtual env
# source $HOME/.local/share/venvs/main/bin/activate
