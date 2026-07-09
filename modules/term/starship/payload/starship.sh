__starship_first_prompt=1

__starship_newline() {
    if [ "$__starship_first_prompt" -eq 0 ]; then
        printf '\n'
    else
        __starship_first_prompt=0
    fi
}

if [ -n "${PROMPT_COMMAND:-}" ]; then
    PROMPT_COMMAND="__starship_newline;${PROMPT_COMMAND}"
else
    PROMPT_COMMAND="__starship_newline"
fi

eval "$(starship init bash)"
