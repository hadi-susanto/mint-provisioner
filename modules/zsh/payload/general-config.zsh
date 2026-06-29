# ~/.zshrc

# --------------------------------------------------
# History
# --------------------------------------------------
HISTFILE="$HOME/.zsh_history"
HISTSIZE=1000
SAVEHIST=1000

setopt APPEND_HISTORY
setopt HIST_IGNORE_DUPS
#setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
#setopt SHARE_HISTORY

# --------------------------------------------------
# Completion
# --------------------------------------------------
autoload -Uz compinit
compinit

zstyle ':completion:*' menu select

# --------------------------------------------------
# Useful Options
# --------------------------------------------------
#setopt AUTO_CD
#setopt INTERACTIVE_COMMENTS
setopt NO_BEEP

# --------------------------------------------------
# Editor
# --------------------------------------------------
export EDITOR=nano
export VISUAL="$EDITOR"

# --------------------------------------------------
# Pager
# --------------------------------------------------
export PAGER=less

# --------------------------------------------------
# Locale
# --------------------------------------------------
export LANG=en_US.UTF-8

# --------------------------------------------------
# PATH
# --------------------------------------------------
path=(
    "$HOME/.local/bin"
    "$HOME/bin"
    $path
)

export PATH

# --------------------------------------------------
# Aliases
# --------------------------------------------------
#alias ll='ls -lah'
#alias la='ls -A'
#alias l='ls -CF'

alias grep='grep --color=auto'

# --------------------------------------------------
# Key Bindings
# --------------------------------------------------
bindkey -e

# --------------------------------------------------
# Prompt
# --------------------------------------------------
#autoload -Uz colors
#colors

#PROMPT='%F{green}%n@%m%f:%F{blue}%~%f %# '

# --------------------------------------------------
# Load local customizations
# --------------------------------------------------
if [[ -f ~/.zshrc.local ]]; then source ~/.zshrc.local; fi
