#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# prompt
if [ -e /usr/share/git/completion/git-completion.bash ]; then
    source /usr/share/git/completion/git-completion.bash
fi
if [ -e /usr/share/git/completion/git-prompt.sh ]; then
    source /usr/share/git/completion/git-prompt.sh
fi
PS1='[\u@\h \w]$(__git_ps1)\n\$ '

# env
export PATH=$PATH:$HOME/.local/bin
if type nvim > /dev/null 2>&1; then
    export EDITOR=nvim
fi

# alias
alias ls='ls -la --color=auto'
alias j='cd $(fd --type d --hidden . . ~ | fzf)'

# history
export HISTSIZE=10000
export HISTCONTROL=ignooredups

# fzf
if [ -e /usr/share/fzf/completion.bash ]; then
    source /usr/share/fzf/completion.bash
fi
if [ -e /usr/share/fzf/key-bindings.bash ]; then
    source /usr/share/fzf/key-bindings.bash
fi
