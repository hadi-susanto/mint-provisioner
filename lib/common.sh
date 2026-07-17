#!/usr/bin/env bash

#
# Prevent the library from being loaded more than once.
#
if [[ "${__COMMON_LIB_LOADED:-false}" == "true" ]]; then
    return 0
fi

readonly __COMMON_LIB_LOADED="true"

# ANSI color constants.
#
# Colors are enabled only when stdout is connected to a terminal.
#
# Environment variables:
#   NO_COLOR
#     Disable colors regardless of output destination.
#
#   FORCE_COLOR
#     Force-enable colors even when stdout is redirected.
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

#
# Logging to stderr to prevent stdout cluttering
# stdout output will be stdin for other process
#
log_info() {
    printf "[INFO]  %s\n" "$*" >&2
}

log_warn() {
    printf "%s[WARN]  %s%s\n" "${COLOR_YELLOW}" "$*" "${COLOR_RESET}" >&2
}

log_error() {
    printf "%s[ERROR] %s%s\n" "${COLOR_RED}" "$*" "${COLOR_RESET}" >&2
}

#
# trim <string>
#
# Removes leading and trailing whitespace characters from a string.
#
# Whitespace characters include spaces, tabs, and other characters
# matched by the POSIX character class [:space:].
#
# Parameters:
#   string    Input string to trim.
#
# Output:
#   Prints the trimmed string to stdout.
#
# Returns:
#   0         Always succeeds.
#
# Examples:
#   trim "  hello world  "
#   # Output: hello world
#
#   result=$(trim $'\t  value \n')
#   echo "$result"
#   # Output: value
#
# Notes:
#   - Internal whitespace is preserved.
#   - The function does not modify the original variable.
#   - Uses Bash parameter expansion only; no external commands
#     such as sed, awk, or xargs are required.
#
trim() {
    local value="$*"

    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"

    printf '%s' "$value"
}

#
# is_admin
#
# Checks whether the current process is running with administrative privileges (root).
#
# Returns:
#   0       Running as root/admin.
#   1       Not running as root/admin.
#
is_admin() {
    [[ "$EUID" -eq 0 ]]
}

#
# get_user_home
#
# Returns the home directory of the current user.
# If running with sudo/administrative privileges, it attempts to return
# the home directory of the original user instead of /root.
#
# Output:
#   Prints the path to the home directory to stdout.
#
get_user_home() {
    if [[ -n "${SUDO_USER:-}" ]]; then
        eval echo "~$SUDO_USER"
    else
        echo "$HOME"
    fi
}

##
# Executes a script with optional temporary environment variables.
#
# The first argument specifies the script file to execute. Remaining arguments
# are interpreted as environment-variable key/value pairs:
#
#     run_script FILE [KEY [VALUE]]...
#
# Each environment variable is available only while the target script is
# running and does not modify the current shell environment.
#
# When a key is provided without a corresponding value, its value defaults to
# an empty string.
#
# Environment variable keys must be valid shell variable names. A valid key:
#
# - Begins with a letter or underscore.
# - Contains only letters, numbers, and underscores.
#
# If the target file is executable, it is executed directly. Otherwise, it is
# executed using Bash with errexit, nounset, and pipefail enabled.
#
# Examples:
#
#   run_script "./install.sh"
#
#   run_script "./install.sh" FORCE_INSTALL true
#
#   run_script "./install.sh" \
#       FORCE_INSTALL true \
#       NONINTERACTIVE false
#
#   run_script "./install.sh" EMPTY_VALUE
#
# Arguments:
#   $1 - Script file to execute.
#   $2... - Optional environment-variable key/value pairs.
#
# Returns:
#   0   - The script completed successfully.
#   1   - The script path is empty, the target is not a regular file, or an
#         environment-variable key is invalid.
#   Other - The exit code returned by the executed script.
#
# Dependencies:
#   log_error
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
        env "${environment[@]}" bash -euo pipefail "$file"
    fi
}

##
# Determine whether the current user can write to a path.
#
# Behavior:
#   - If the path exists, checks whether the path is writable.
#     This works for both files and directories.
#   - If the path does not exist, assumes the path represents a file
#     that may be created in the future. The function searches upward
#     through parent directories until an existing directory is found,
#     then checks whether that directory is writable.
#   - If no writable parent directory can be found, returns failure.
#
# Parameters:
#   $1 - Path to check.
#
# Returns:
#   0 - The path is writable, or a new file could be created at the
#       specified location.
#   1 - The path is not writable, or a new file could not be created
#       at the specified location.
#
# Notes:
#   - Existing directories are treated as writable targets and may
#     return success if the current user has write permission.
#   - For nonexistent paths, the function assumes the path is intended
#     to be a file and checks whether creation would be possible.
#   - A successful return value only indicates that permissions appear
#     to allow writing at the time of the check. The actual write
#     operation may still fail due to filesystem changes, ACL updates,
#     read-only mounts, disk-full conditions, and similar issues.
#
# Examples:
#   can_write ~/.bashrc
#   can_write ~/.config/myapp/config.yml
#   can_write /usr/share/applications/custom.desktop
#   can_write /tmp
#
can_write() {
    local target="$1"
    local dir

    [[ -n "$target" ]] || return 1

    # Expand ~ if present.
    [[ "$target" == "~"* ]] && target="${target/#\~/$HOME}"

    # Existing file.
    if [[ -e "$target" ]]; then
        [[ -w "$target" ]]
        return
    fi

    # Start from the file's parent directory.
    dir=$(dirname -- "$target")

    # Walk upward until an existing directory is found.
    while [[ ! -d "$dir" ]]; do
        local parent
        parent=$(dirname -- "$dir")

        [[ "$parent" == "$dir" ]] && return 1

        dir="$parent"
    done

    [[ -w "$dir" ]]
}
