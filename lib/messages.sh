#
# Prevent the library from being loaded more than once.
#
if (( ${__MESSAGES_LIB_LOADED:-0} )); then
    return 0
fi

source "${LIB_DIR}/common.sh"

if [[ -z "${ROOT_DIR:-}" ]]; then
    log_error "[messages] ROOT_DIR is not defined."

    return 1
fi

readonly __MESSAGES_DIR="$ROOT_DIR/messages"
declare -a __MESSAGES_SUDO_CMD=()

if ! can_write "$__MESSAGES_DIR"; then
    __MESSAGES_SUDO_CMD=(sudo)
fi

#
# Validation completed, we can mark as loaded
#
readonly __MESSAGES_LIB_LOADED=1

##
# Validates a message level.
#
# Parameters:
#   $1 - Message level: info, warn, or error.
#
# Returns:
#   0 - Message level is valid.
#   1 - Message level is invalid.
#
__validate_message_level() {
    local level="${1:-}"

    case "$level" in
        info | warn | error)
            return 0
            ;;

        "")
            log_error "[messages] Message level must not be empty."
            ;;

        *)
            log_error \
                "[messages] Invalid message level: $level. Expected info, warn, or error."
            ;;
    esac

    return 1
}

##
# Resolves the persistent file path for a module message level.
#
# Parameters:
#   $1 - Canonical module ID in <category>/<module> format.
#   $2 - Message level: info, warn, or error.
#
# Output:
#   Writes the resolved message file path to stdout.
#
# Returns:
#   0 - File path was resolved.
#   1 - Invalid canonical ID or message level.
#
__resolve_message_file() {
    local canonical_id="${1:-}"
    local level="${2:-}"

    if [[ -z "$canonical_id" ]]; then
        log_error "[messages] Canonical ID must not be empty."

        return 1
    fi

    if ! __validate_message_level "$level"; then
        return 1
    fi

    printf '%s/%s/%s\n' \
        "$__MESSAGES_DIR" \
        "$canonical_id" \
        "$level"

    return 0
}

##
# Stores a message for a module.
#
# Messages with the same canonical ID and level are appended to the same file.
# A blank line is inserted before an appended message when the file is not
# empty.
#
# Parameters:
#   $1 - Canonical module ID in <category>/<module> format.
#   $2 - Message level: info, warn, or error.
#   $3 - Message text.
#
# Returns:
#   0 - Message was stored.
#   1 - Input is invalid or the message could not be stored.
#
add_message() {
    local canonical_id="${1:-}"
    local level="${2:-}"
    local message="${3:-}"

    if [[ -z "$message" ]]; then
        log_error "[add_message] Message must not be empty."

        return 1
    fi

    local message_file

    if ! message_file="$(__resolve_message_file "$canonical_id" "$level")"; then
        return 1
    fi

    local target_dir="${message_file%/*}"

    if ! "${__MESSAGES_SUDO_CMD[@]}" mkdir -p "$target_dir"; then
        log_error \
            "[add_message] Failed to create message directory: $target_dir."

        return 1
    fi

    local message_format

    if [[ -s "$message_file" ]]; then
        message_format='\n%s\n'
    else
        message_format='%s\n'
    fi

    if ! printf "$message_format" "$message" |
        "${__MESSAGES_SUDO_CMD[@]}" tee -a "$message_file" >/dev/null
    then
        log_error \
            "[add_message] Failed to store message: $message_file."

        return 1
    fi

    return 0
}

##
# Checks whether a module has any stored messages.
#
# Parameters:
#   $1 - Canonical module ID in <category>/<module> format.
#
# Returns:
#   0 - At least one message exists.
#   1 - No messages exist.
#   2 - Canonical ID is invalid.
#
has_messages() {
    local canonical_id="${1:-}"

    local level
    local message_file

    for level in info warn error; do
        if ! message_file="$(__resolve_message_file "$canonical_id" "$level")"; then
            return 2
        fi

        if [[ -s "$message_file" ]]; then
            return 0
        fi
    done

    return 1
}

##
# Prints all stored messages for a module.
#
# Messages are grouped by level and printed in the following order:
# info, warn, and error. Empty message levels are skipped. Each output line
# can optionally be indented with the specified number of spaces.
#
# Parameters:
#   $1 - Canonical module ID in <category>/<module> format.
#   $2 - Optional number of spaces used to indent the output. Defaults to 0.
#
# Returns:
#   0 - One or more messages were printed.
#   1 - No messages exist, the padding is invalid, or an error occurred.
#
print_messages() {
    local canonical_id="${1:-}"
    local padding="${2:-0}"

    local level
    local message_file
    local title
    local title_color
    local messages_found=false

    if [[ ! "$padding" =~ ^[0-9]+$ ]]; then
        log_error \
            "[print_messages] Padding must be a non-negative integer."

        return 1
    fi

    for level in info warn error; do
        if ! message_file="$(
            __resolve_message_file "$canonical_id" "$level"
        )"; then
            return 1
        fi

        if [[ ! -s "$message_file" ]]; then
            continue
        fi

        case "$level" in
            info)
                title="INFO"
                title_color="$COLOR_GREEN"
                ;;

            warn)
                title="WARN"
                title_color="$COLOR_YELLOW"
                ;;

            error)
                title="ERROR"
                title_color="$COLOR_RED"
                ;;
        esac

        if [[ "$messages_found" == "true" ]]; then
            printf '\n'
        fi

        printf '%*s%s[%s]:%s\n' \
            "$padding" "" \
            "$title_color" \
            "$title" \
            "${COLOR_RESET}"

        if (( padding == 0 )); then
            if ! "${__MESSAGES_SUDO_CMD[@]}" cat "$message_file"; then
                log_error \
                    "[print_messages] Failed to print messages: $message_file."

                return 1
            fi
        else
            if ! "${__MESSAGES_SUDO_CMD[@]}" awk \
                -v padding="$padding" \
                '{ printf "%*s%s\n", padding, "", $0 }' \
                "$message_file"; then
                log_error \
                    "[print_messages] Failed to print messages: $message_file."

                return 1
            fi
        fi

        messages_found=true
    done

    [[ "$messages_found" == "true" ]]
}

##
# Deletes all stored messages for a module.
#
# Parameters:
#   $1 - Canonical module ID in <category>/<module> format.
#
# Returns:
#   0 - The module message directory was deleted or did not exist.
#   1 - The canonical ID is invalid or deletion failed.
#
delete_messages() {
    local canonical_id="${1:-}"

    local message_file

   if ! message_file="$(__resolve_message_file "$canonical_id" "$level")"; then
        return 1
    fi

    local message_dir="${message_file%/*}"

    if [[ ! -d "$message_dir" ]]; then
        return 0
    fi

    if ! "${__MESSAGES_SUDO_CMD[@]}" rm -rf "$message_dir"; then
        log_error \
            "[delete_messages] Failed to delete messages for module: $canonical_id."

        return 1
    fi

    return 0
}

##
# Deletes all stored module messages.
#
# Parameters:
#   None.
#
# Returns:
#   0 - All messages were deleted or the message directory did not exist.
#   1 - Message directory could not be deleted.
#
delete_all_messages() {
    if ! "${__MESSAGES_SUDO_CMD[@]}" test -e "$__MESSAGES_DIR"; then
        return 0
    fi

    if ! "${__MESSAGES_SUDO_CMD[@]}" rm -rf "$__MESSAGES_DIR"; then
        log_error \
            "[delete_all_messages] Failed to delete message directory: $__MESSAGES_DIR."

        return 1
    fi

    return 0
}
