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

__trim() {
    local value_name="$1"
    local -n value_ref="$value_name"

    value_ref="${value_ref#"${value_ref%%[![:space:]]*}"}"
    value_ref="${value_ref%"${value_ref##*[![:space:]]}"}"
}

__log_tagged() {
    local level="$1"
    local level_color="$2"
    local tag="$3"
    local format="$4"

    shift 4

    printf '%b[%s]%b %b[%s]%b ' \
        "$level_color" "$level" "$COLOR_RESET" \
        "$COLOR_GREEN" "$tag" "$COLOR_RESET" >&2
    printf "$format\n" "$@" >&2
}

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

##
# tlog_info
#
# Prints a tagged informational message to standard error.
#
# Supports printf-style formatting.
#
# Parameters:
#   tag:    Message source tag.
#   format: Printf-style format string.
#   ...:    Values referenced by the format string.
#
tlog_info() {
    __log_tagged "INFO" "$COLOR_CYAN" "$@"
}

##
# tlog_warn
#
# Prints a tagged warning message to standard error.
#
# Supports printf-style formatting.
#
# Parameters:
#   tag:    Message source tag.
#   format: Printf-style format string.
#   ...:    Values referenced by the format string.
#
tlog_warn() {
    __log_tagged "WARN" "$COLOR_YELLOW" "$@"
}

##
# tlog_error
#
# Prints a tagged error message to standard error.
#
# Supports printf-style formatting.
#
# Parameters:
#   tag:    Message source tag.
#   format: Printf-style format string.
#   ...:    Values referenced by the format string.
#
tlog_error() {
    __log_tagged "ERROR" "$COLOR_RED" "$@"
}
