#!/usr/bin/env bash

#
# Colors only applicable when we directly print to the console
#
if [[ -t 1 ]]; then
    COLOR_GREEN=$'\033[0;32m'
    COLOR_RED=$'\033[0;31m'
    COLOR_YELLOW=$'\033[0;33m'
    COLOR_RESET=$'\033[0m'
else
    COLOR_GREEN=''
    COLOR_RED=''
    COLOR_YELLOW=''
    COLOR_RESET=''
fi

#
# Logging to stderr to prevent stdout cluttering
# stdout output will be stdin for other process
#
log_info() {
    printf "[INFO]  %s\n" "$*" >&2
}

log_warn() {
    printf "${COLOR_YELLOW}[WARN]  %s${COLOR_RESET}\n" "$*" >&2
}

log_error() {
    printf "${COLOR_RED}[ERROR] %s${COLOR_RESET}\n" "$*" >&2
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

    echo -n "$value"
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

#
# run_script <file>
#
# Executes a script file and propagates its exit status.
#
# Behavior:
#   - Returns 1 if no argument is supplied.
#   - Returns 1 if the file does not exist or is not a regular file.
#   - If the file is executable, executes it directly.
#   - Otherwise executes it using the Bash interpreter.
#   - Returns the exit code of the executed script.
#
# Parameters:
#   file    Path to the script to execute.
#
# Returns:
#   1       Missing argument or file not found.
#   N       Exit code returned by the executed script.
#
# Examples:
#   run_script "./deploy.sh"
#   run_script "/opt/tools/cleanup"
#
run_script() {
    local file="$1"

    # Validate input
    if [[ -z "$file" ]]; then
        log_error "[run_script] blank script given, unable to execute it"

        return 1
    fi

    # Verify that the target exists and is a regular file
    if [[ ! -f "$file" ]]; then
        log_error "[run_script] '$file' is not a file, unable to execute it"

        return 1
    fi

    # Execute according to executable permission
    if [[ -x "$file" ]]; then
        "$file"
    else
        bash -euo pipefail "$file"
    fi

    return $?
}

#
# post_message <module> <message>
#
# Appends a message to the module's message file in STATE_DIR.
#
# Parameters:
#   module    Name of the module.
#   message   The message to append.
#
post_message() {
    local module="$1"
    local message="$2"
    local message_file="${STATE_DIR}/${module}.messages"

    echo "$message" >> "$message_file"
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
