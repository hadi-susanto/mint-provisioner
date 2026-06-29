autoload -Uz add-zsh-hook

typeset -g STARSHIP_FIRST_PROMPT=1

starship_newline() {
    if (( STARSHIP_FIRST_PROMPT == 0 )); then
        print
    else
        STARSHIP_FIRST_PROMPT=0
    fi
}

add-zsh-hook precmd starship_newline

eval "$(starship init zsh)"
