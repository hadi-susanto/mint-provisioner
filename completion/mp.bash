# Bash completion for Mint Provisioner (mp).
#
# Enable it by sourcing this file from ~/.bashrc:
#   source /path/to/mint-provisioner/completion/mp.bash
# or by linking it where bash-completion loads it on demand:
#   ln -s /path/to/mint-provisioner/completion/mp.bash ~/.local/share/bash-completion/completions/mp
#
# Candidates come from the hidden 'mp __complete' command, so module IDs and
# aliases always match the installed catalog.

_mp() {
    local current="${COMP_WORDS[COMP_CWORD]}"
    local candidates
    local IFS=$'\n'

    candidates="$("${COMP_WORDS[0]}" __complete "${COMP_WORDS[@]:1:COMP_CWORD}" 2>/dev/null)" || return 0

    # shellcheck disable=SC2207 # Newline-separated candidates; IFS is set above.
    COMPREPLY=($(compgen -W "$candidates" -- "$current"))
}

complete -F _mp mp
