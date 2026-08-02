#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_COMMON_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_COMMON_LOADED=1

if [[ -z "${NO_COLOR:-}" ]] &&
    { [[ -n "${FORCE_COLOR:-}" ]] || [[ -t 1 ]]; }; then
    readonly COLOR_GREEN=$'\033[0;32m'
    readonly COLOR_RED=$'\033[0;31m'
    readonly COLOR_YELLOW=$'\033[0;33m'
    readonly COLOR_CYAN=$'\033[0;36m'
    readonly COLOR_RESET=$'\033[0m'
else
    readonly COLOR_GREEN=''
    readonly COLOR_RED=''
    readonly COLOR_YELLOW=''
    readonly COLOR_CYAN=''
    readonly COLOR_RESET=''
fi

##
# log_info
#
# Prints an informational message to standard error.
#
# Supports printf-style formatting.
#
# Parameters:
#   format: Printf-style format string.
#   ...:    Values referenced by the format string.
#
log_info() {
    local format="$1"

    shift

    printf '%b[INFO]%b ' "$COLOR_CYAN" "$COLOR_RESET" >&2
    printf "$format\n" "$@" >&2
}

##
# log_warn
#
# Prints a warning message to standard error.
#
# Supports printf-style formatting.
#
# Parameters:
#   format: Printf-style format string.
#   ...:    Values referenced by the format string.
#
log_warn() {
    local format="$1"

    shift

    printf '%b[WARN]%b ' "$COLOR_YELLOW" "$COLOR_RESET" >&2
    printf "$format\n" "$@" >&2
}

##
# log_error
#
# Prints an error message to standard error.
#
# Supports printf-style formatting.
#
# Parameters:
#   format: Printf-style format string.
#   ...:    Values referenced by the format string.
#
log_error() {
    local format="$1"

    shift

    printf '%b[ERROR]%b ' "$COLOR_RED" "$COLOR_RESET" >&2
    printf "$format\n" "$@" >&2
}
