#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_INSTALL_TARGET_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_INSTALL_TARGET_LOADED=1

source "$LIB_INSTALLER/messages.sh"
source "$LIB_INSTALLER/path.sh"

__add_install_target_access_message() {
    local canonical_id="$1"
    local install_path="$2"
    local message

    message="Mint Provisioner cannot install to $install_path as the current user.
Create the target directory or adjust its ownership and permissions, then retry the installation."

    if ! add_message "$canonical_id" info "$message"; then
        tlog_warn "pre-install:$canonical_id" \
            "Failed to persist installation-directory guidance"
    fi
}

##
# resolve_install_target <canonical_id> <raw_path>
#
# Normalizes and validates a user-selected installation directory without
# creating or modifying it.
#
# Parameters:
#   canonical_id - Canonical module ID used for logging and guidance.
#   raw_path     - Non-empty installation path to normalize and validate.
#
# Output:
#   Prints the normalized absolute installation path.
#
# Returns:
#   1 when the arguments or target are invalid, the path cannot be expanded,
#   or the target cannot be written by the current user.
#
resolve_install_target() {
    local canonical_id="${1:-}"
    local raw_path="${2:-}"
    local tag="pre-install"
    local install_path

    if [[ -n "$canonical_id" ]]; then
        tag+=":$canonical_id"
    fi

    if (( $# != 2 )) || [[ -z "$canonical_id" || -z "$raw_path" ]]; then
        tlog_error "$tag" \
            "resolve_install_target requires a canonical ID and installation path"

        return 1
    fi

    if [[ ! "$canonical_id" =~ ^[a-z0-9][a-z0-9-]*/[a-z0-9][a-z0-9-]*$ ]]; then
        tlog_error "$tag" "Invalid canonical ID: %s" "$canonical_id"

        return 1
    fi

    install_path="$(expand_path "$raw_path")" || return $?

    if [[ -e "$install_path" && ! -d "$install_path" ]]; then
        tlog_error "$tag" \
            "Installation target exists but is not a directory: %s" \
            "$install_path"
        __add_install_target_access_message "$canonical_id" "$install_path"

        return 1
    fi

    if ! can_write "$install_path"; then
        tlog_error "$tag" \
            "Installation target is not writable by the current user: %s" \
            "$install_path"
        __add_install_target_access_message "$canonical_id" "$install_path"

        return 1
    fi

    printf '%s\n' "$install_path"
}
