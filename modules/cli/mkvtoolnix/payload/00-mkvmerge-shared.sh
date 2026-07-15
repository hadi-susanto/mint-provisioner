##
# Shell-specific compatibility initialization.
#
# This script supports both Bash and zsh. When running under zsh, a few
# compatibility options are enabled so that array behavior more closely
# matches Bash:
#
#   - KSH_ARRAYS
#       Use zero-based array indexing instead of zsh's default one-based
#       indexing.
#
#   - KSH_ZERO_SUBSCRIPT
#       Allow index 0 to reference the first array element.
#
# A shell-specific implementation of `tolower()` is also provided to avoid
# spawning an external `tr` process when the shell offers a built-in
# lowercase conversion.
#
# If the script is executed by an unsupported shell, a portable
# implementation using `tr` is used as a fallback.
#
if [ -n "$BASH_VERSION" ]; then
    #
    # Bash 4+ implementation.
    #
    tolower() {
        printf '%s' "${1,,}"
    }

elif [ -n "$ZSH_VERSION" ]; then
    #
    # Configure zsh for better Bash compatibility.
    #
    emulate -L zsh
    setopt KSH_ARRAYS
    setopt KSH_ZERO_SUBSCRIPT
    setopt TYPESET_SILENT

    #
    # Native zsh implementation.
    #
    tolower() {
        printf '%s' "${1:l}"
    }

else
    #
    # Portable fallback.
    #
    tolower() {
        printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
    }
fi

##
# Returns whether colored output should be used.
#
# Returns:
#   0 if colors should be enabled.
#   1 otherwise.
#
__supports_color() {
    [[ -z "${NO_COLOR:-}" ]] &&
    { [[ -n "${FORCE_COLOR:-}" ]] || [[ -t 1 ]]; }
}

##
# Converts a boolean value to a status icon.
#
# Parameters:
#   $1 - Boolean value ("true" or "false")
#   $2 - Whether to colorize the output ("true" or "false")
#
# Output:
#   ✓ for true
#   ✗ for false
#
__boolean_to_icon() {
    local value="$1"
    local colorize="$2"

    if [[ "$value" == "true" ]]; then
        if [[ "$colorize" == "true" ]]; then
            printf '\033[0;32m✓\033[0m'
        else
            printf '✓'
        fi
    else
        if [[ "$colorize" == "true" ]]; then
            printf '\033[0;31m✗\033[0m'
        else
            printf '✗'
        fi
    fi
}
