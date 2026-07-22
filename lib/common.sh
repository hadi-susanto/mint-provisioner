#!/usr/bin/env bash

#
# Prevent the library from being loaded more than once.
#
if [[ "${__COMMON_LIB_LOADED:-false}" == "true" ]]; then
    return 0
fi

readonly __COMMON_LIB_LOADED="true"

if [[ -n "${NO_COLOR:-}" ]]; then
    readonly COLOR_GREEN=""
    readonly COLOR_RED=""
    readonly COLOR_YELLOW=""
    readonly COLOR_CYAN=""
    readonly COLOR_RESET=""
elif [[ -n "${FORCE_COLOR:-}" || -t 1 ]]; then
    readonly COLOR_GREEN=$'\033[0;32m'
    readonly COLOR_RED=$'\033[0;31m'
    readonly COLOR_YELLOW=$'\033[0;33m'
    readonly COLOR_CYAN=$'\033[0;36m'
    readonly COLOR_RESET=$'\033[0m'
else
    readonly COLOR_GREEN=""
    readonly COLOR_RED=""
    readonly COLOR_YELLOW=""
    readonly COLOR_CYAN=""
    readonly COLOR_RESET=""
fi

##
# Writes an informational message to stderr.
#
# Parameters:
#   message    Message text supplied as one or more arguments.
#
log_info() {
    printf "[INFO]  %s\n" "$*" >&2
}

##
# Writes a warning message to stderr.
#
# Parameters:
#   message    Message text supplied as one or more arguments.
#
log_warn() {
    printf "%s[WARN]  %s%s\n" "${COLOR_YELLOW}" "$*" "${COLOR_RESET}" >&2
}

##
# Writes an error message to stderr.
#
# Parameters:
#   message    Message text supplied as one or more arguments.
#
log_error() {
    printf "%s[ERROR] %s%s\n" "${COLOR_RED}" "$*" "${COLOR_RESET}" >&2
}

##
# Removes leading and trailing whitespace from the supplied text.
#
# Parameters:
#   text    Text supplied as one or more arguments.
#
# Output:
#   Prints the trimmed text without a trailing newline.
#
trim() {
    local value="$*"

    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"

    printf '%s' "$value"
}

##
# Checks whether the current process has administrative privileges.
#
# Returns:
#   0 when running as root; 1 otherwise.
#
is_admin() {
    [[ "$EUID" -eq 0 ]]
}

##
# Resolves the target user's home directory, including sudo sessions.
#
# Output:
#   Prints the path to the home directory to stdout.
#
# Returns:
#   1 when the sudo user cannot be resolved or HOME is unavailable.
#
get_user_home() {
    if [[ -n "${SUDO_USER:-}" ]]; then
        local passwd_entry
        local sudo_home

        if ! passwd_entry="$(getent passwd "$SUDO_USER")"; then
            log_error "[get_user_home] Unable to resolve home directory for $SUDO_USER"

            return 1
        fi

        IFS=: read -r _ _ _ _ _ sudo_home _ <<< "$passwd_entry"

        if [[ -n "$sudo_home" ]]; then
            printf '%s\n' "$sudo_home"

            return 0
        fi
    fi

    if [[ -z "${HOME:-}" ]]; then
        log_error "[get_user_home] Unable to determine the current user's home directory"

        return 1
    fi

    printf '%s\n' "$HOME"
}

##
# Executes a script with optional temporary environment variables.
#
# Parameters:
#   file           Script file to execute directly or through Bash.
#   environment    Remaining arguments are variable-name/value pairs. A name
#                  without a value is assigned an empty string.
#
# Returns:
#   1 when the file or an environment-variable name is invalid; otherwise the
#   status returned by the executed script.
#
run_script() {
    local file="${1:-}"

    local key
    local value

    local -a environment=()

    #
    # Validate input
    #
    if [[ -z "$file" ]]; then
        log_error "[run_script] Blank script given, unable to execute it."

        return 1
    fi

    shift

    #
    # Verify that the target exists and is a regular file
    #
    if [[ ! -f "$file" ]]; then
        log_error "[run_script] '$file' is not a file, unable to execute it."

        return 1
    fi

    #
    # Collect additional environment variables
    #
    while (($# > 0)); do
        key="$1"
        shift

        if [[ ! "$key" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
            log_error "[run_script] Invalid environment variable key: '$key'."

            return 1
        fi

        value=""

        if (($# > 0)); then
            value="$1"
            shift
        fi

        environment+=("$key=$value")
    done

    #
    # Execute according to executable permission
    #
    if [[ -x "$file" ]]; then
        env "${environment[@]}" "$file"
    else
        env "${environment[@]}" bash "$file"
    fi
}

##
# Checks whether an existing path is writable or a new path can be created.
#
# Parameters:
#   target    Existing path or prospective file path to inspect.
#
# Returns:
#   1 when the target is blank or no writable existing path or parent exists.
#
can_write() {
    local target="${1:-}"
    local dir

    [[ -n "$target" ]] || return 1

    # Expand ~ if present.
    [[ "$target" == "~"* ]] && target="${target/#\~/$HOME}"

    # Existing file.
    if [[ -e "$target" ]]; then
        [[ -w "$target" ]]

        return
    fi

    # use dirname to prevent edge case: target == file.txt
    # Start from the file's parent directory.
    dir="$(dirname -- "$target")"

    # Walk upward until an existing directory is found.
    while [[ ! -d "$dir" ]]; do
        local parent
        parent="$(dirname -- "$dir")"

        [[ "$parent" == "$dir" ]] && return 1

        dir="$parent"
    done

    [[ -w "$dir" ]]
}

##
# Checks whether any of the specified Debian packages is installed.
#
# Parameters:
#   canonical_id    Canonical module ID used for error logging.
#   packages        Remaining arguments are Debian package names to check.
#
# Returns:
#   1 when none are installed
#   2 when querying a package status fails unexpectedly.
#
package_installed() {
    local canonical_id="$1"

    shift

    local package
    local status
    local rc

    for package in "$@"; do
        if status="$(
            dpkg-query \
                --show \
                --showformat='${Status}' \
                "$package" 2>/dev/null
        )"; then
            if [[ "$status" == "install ok installed" ]]; then
                return 0
            fi

            continue
        fi

        rc=$?

        if ((rc == 1)); then
            continue
        fi

        log_error "[$canonical_id] Failed to query package status for $package"

        return 2
    done

    return 1
}
