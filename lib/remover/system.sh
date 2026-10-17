#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_REMOVER_SYSTEM_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_REMOVER_SYSTEM_LOADED=1

source "$LIB_COMMON/common.sh"

##
# remove_system_file
#
# Removes a single generated system file that no other remover covers, such as
# an APT pin or a launcher script. Only these locations are allowed:
# /etc/apt/preferences.d/<name> and /usr/local/bin/<name>. Symlinks are refused
# (use remove_symlink) and a missing file is not an error.
#
# Parameters:
#   canonical_id - Canonical module ID used for logging.
#   file - Absolute path of a regular file in an allowed directory.
#
# Return:
#   1 - Validation failed, the file is not a regular file, or removal failed.
#
remove_system_file() {
    local canonical_id="${1:-}"
    local file="${2:-}"
    local tag="remove-system-file"

    if [[ -n "$canonical_id" ]]; then
        tag+=":$canonical_id"
    fi

    if (( $# != 2 )) || [[ -z "$canonical_id" || -z "$file" ]]; then
        tlog_error "$tag" "A canonical ID and file path are required"

        return 1
    fi

    local directory="${file%/*}"
    local name="${file##*/}"

    if [[ "$directory" != "/etc/apt/preferences.d" && "$directory" != "/usr/local/bin" ]] ||
        [[ ! "$name" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ || "$name" == *..* ]]; then
        tlog_error "$tag" "File is not in an allowed location: %s" "$file"

        return 1
    fi

    if [[ ! -e "$file" && ! -L "$file" ]]; then
        tlog_info "$tag" "File does not exist, skipping: %s" "$file"

        return 0
    fi

    if [[ -L "$file" || ! -f "$file" ]]; then
        tlog_error "$tag" "Refusing to remove a path that is not a regular file: %s" "$file"

        return 1
    fi

    tlog_info "$tag" "Removing %s" "$file"

    if ! sudo rm -f -- "$file"; then
        tlog_error "$tag" "Failed to remove %s" "$file"

        return 1
    fi

    return 0
}
