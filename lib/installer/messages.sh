#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_MESSAGES_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_MESSAGES_LOADED=1

source "$LIB_COMMON/common.sh"

if [[ -z "${HOME:-}" || "$HOME" != /* ]]; then
    tlog_error "messages" "HOME must be set to an absolute path"

    return 1
fi

readonly __MESSAGES_DIR="$HOME/.cache/mint-provisioner/messages"

__validate_message_level() {
    local level="${1:-}"

    case "$level" in
        info | warn | error) return 0 ;;
        *)
            tlog_error "messages" "Invalid message level: %s" "${level:-<empty>}"

            return 1
            ;;
    esac
}

__resolve_message_file() {
    local canonical_id="${1:-}"
    local level="${2:-}"
    local tag="messages"

    if [[ -n "$canonical_id" ]]; then
        tag+=":$canonical_id"
    fi

    if [[ ! "$canonical_id" =~ ^[a-z0-9][a-z0-9-]*/[a-z0-9][a-z0-9-]*$ ]]; then
        tlog_error "$tag" "Invalid canonical ID: %s" "${canonical_id:-<empty>}"

        return 1
    fi

    __validate_message_level "$level" || return $?
    printf '%s/%s/%s\n' "$__MESSAGES_DIR" "$canonical_id" "$level"
}

##
# add_message
#
# Appends a non-empty info, warn, or error message for a module.
#
# Parameters:
#   canonical_id - Canonical module ID selecting the message directory.
#   level - Message level: info, warn, or error.
#   message - Non-empty message text to append.
#
# Return:
#   0 - The message was stored.
#   1 - Validation, directory creation, or writing failed.
#
add_message() {
    local canonical_id="${1:-}"
    local level="${2:-}"
    local message="${3:-}"
    local message_file
    local message_dir

    if (( $# != 3 )) || [[ -z "canonical_id" || -z "$level" || -z "$message" ]]; then
        tlog_error "messages" "add_message requires Canonical ID, Level, and Message"

        return 1
    fi

    message_file="$(__resolve_message_file "$canonical_id" "$level")" || return $?
    message_dir="${message_file%/*}"

    if ! mkdir -p "$message_dir"; then
        tlog_error "messages:$canonical_id" "Failed to create message directory: %s" "$message_dir"

        return 1
    fi

    if [[ -s "$message_file" ]]; then
        if ! printf '\n%s\n' "$message" >>"$message_file"; then
            tlog_error "messages:$canonical_id" "Failed to store message: %s" "$message_file"

            return 1
        fi
    elif ! printf '%s\n' "$message" >>"$message_file"; then
        tlog_error "messages:$canonical_id" "Failed to store message: %s" "$message_file"

        return 1
    fi
}

##
# add_system_toolkit_message
#
# Adds the standard System Toolkit integration guidance for a module.
#
# Parameters:
#   canonical_id - Canonical module ID selecting the message directory.
#
# Return:
#   0 - The System Toolkit message was stored.
#   1 - Validation or message storage failed.
#
add_system_toolkit_message() {
    local canonical_id="${1:-}"
    local message

    if (( $# != 1 )); then
        tlog_error "messages" "add_system_toolkit_message requires one canonical ID"

        return 1
    fi

    message="Enhance this module with additional integrations and functionality
by installing System Toolkit and enabling its integrations."

    add_message "$canonical_id" info "$message"
}

##
# has_messages
#
# Tests whether a module has at least one non-empty message file.
#
# Parameters:
#   canonical_id - Canonical module ID selecting the message directory.
#
# Return:
#   0 - At least one stored message exists.
#   1 - No stored messages exist.
#   2 - The canonical ID or argument count is invalid.
#
has_messages() {
    local canonical_id="${1:-}"
    local level
    local message_file

    if (( $# != 1 )); then
        tlog_error "messages" "has_messages requires one canonical ID"

        return 2
    fi

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
# print_messages
#
# Prints stored messages in info, warn, and error order with optional padding.
#
# Parameters:
#   canonical_id - Canonical module ID selecting the message directory.
#   padding - Optional number of spaces used to indent output; defaults to zero.
#
# Output:
#   Prints all stored messages grouped by level to standard output.
#
# Return:
#   0 - One or more stored messages were printed.
#   1 - No messages exist, input is invalid, or reading failed.
#
print_messages() {
    local canonical_id="${1:-}"
    local padding="${2:-0}"
    local level
    local message_file
    local title
    local title_color
    local messages_found=0

    if (( $# < 1 || $# > 2 )) || [[ -z "$canonical_id" || ! "$padding" =~ ^[0-9]+$ ]]; then
        tlog_error "messages" "print_messages requires a Canonical ID and optional Padding (must be a non-negative integer)"

        return 1
    fi

    for level in info warn error; do
        message_file="$(__resolve_message_file "$canonical_id" "$level")" || return $?

        if [[ ! -s "$message_file" ]]; then
            continue
        fi

        case "$level" in
            info)
                title='INFO'
                title_color="$COLOR_BLUE"
                ;;
            warn)
                title='WARN'
                title_color="$COLOR_YELLOW"
                ;;
            error)
                title='ERROR'
                title_color="$COLOR_RED"
                ;;
        esac

        if (( messages_found )); then
            printf '\n'
        fi

        printf '%*s%b[%s]:%b\n' \
            "$padding" '' "$title_color" "$title" "$COLOR_RESET"

        if (( padding == 0 )); then
            if ! command cat "$message_file"; then
                tlog_error "messages:$canonical_id" "Failed to print messages: %s" "$message_file"

                return 1
            fi
        elif ! awk -v padding="$padding" \
            '{ printf "%*s%s\n", padding, "", $0 }' "$message_file"; then
            tlog_error "messages:$canonical_id" "Failed to print messages: %s" "$message_file"

            return 1
        fi

        messages_found=1
    done

    (( messages_found ))
}

##
# delete_messages
#
# Deletes all persisted messages for one module.
#
# Parameters:
#   canonical_id - Canonical module ID selecting the message directory.
#
# Return:
#   0 - The module message directory was deleted or did not exist.
#   1 - Validation or deletion failed.
#
delete_messages() {
    local canonical_id="${1:-}"
    local message_file
    local message_dir

    if (( $# != 1 )); then
        tlog_error "messages" "delete_messages requires one canonical ID"

        return 1
    fi

    message_file="$(__resolve_message_file "$canonical_id" info)" || return $?
    message_dir="${message_file%/*}"

    if [[ -e "$message_dir" ]] && ! rm -rf "$message_dir"; then
        tlog_error "messages:$canonical_id" "Failed to delete module messages"

        return 1
    fi
}

##
# delete_all_messages
#
# Deletes all persisted module messages.
#
# Return:
#   0 - The message root was deleted or did not exist.
#   1 - Arguments are invalid or deletion failed.
#
delete_all_messages() {
    if (( $# != 0 )); then
        tlog_error "messages" "delete_all_messages does not accept arguments"

        return 1
    fi

    if [[ -e "$__MESSAGES_DIR" ]] && ! rm -rf "$__MESSAGES_DIR"; then
        tlog_error "messages" "Failed to delete message directory: %s" "$__MESSAGES_DIR"

        return 1
    fi
}
