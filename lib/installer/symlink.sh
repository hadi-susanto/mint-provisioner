#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_SYMLINK_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_SYMLINK_LOADED=1

source "$LIB_COMMON/common.sh"

##
# symlink_location
#
# Resolves the shared installation directory for command symlinks.
#
# Output:
#   Prints the symlink directory to standard output.
#
symlink_location() {
    printf '%s\n' '/usr/local/bin'
}

##
# symlink_binary
#
# Creates or replaces a shared command symlink.
#
# Parameters:
#   canonical_id - Canonical module ID used for logging.
#   source_binary - Executable file targeted by the symlink.
#   link_name - Optional destination name; defaults to the source filename.
#
# Return:
#   0 - The command symlink was created or replaced.
#   1 - Validation or symlink creation failed.
#
symlink_binary() {
    local canonical_id="${1:-}"
    local source_binary="${2:-}"
    local link_name="${3:-${source_binary##*/}}"
    local tag="symlink"

    if [[ -n "$canonical_id" ]]; then
        tag+=":$canonical_id"
    fi

    if (( $# < 2 || $# > 3 )) ||
        [[ -z "$canonical_id" || -z "$source_binary" || -z "$link_name" ]]; then
        tlog_error "$tag" "Invalid symlink arguments"

        return 1
    fi

    if [[ "$link_name" == */* || "$link_name" == '.' || "$link_name" == '..' ]]; then
        tlog_error "$tag" "Invalid symlink name: %s" "$link_name"

        return 1
    fi

    if [[ ! -f "$source_binary" || ! -x "$source_binary" ]]; then
        tlog_error "$tag" "Source is not an executable file: %s" "$source_binary"

        return 1
    fi

    local destination="$(symlink_location)/$link_name"

    tlog_info "$tag" "Creating symlink: %s -> %s" "$destination" "$source_binary"

    if ! sudo ln -sf "$source_binary" "$destination"; then
        tlog_error "$tag" "Failed to create symlink: %s" "$destination"

        return 1
    fi

    return 0
}
