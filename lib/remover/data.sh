#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_REMOVER_DATA_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_REMOVER_DATA_LOADED=1

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/registry.sh"
source "$LIB_REMOVER/binary.sh"

##
# remove_data_dir
#
# Deletes a service or application data directory, such as a database directory
# under /var/lib, only when PURGE=true (mp purge, which asks for confirmation first).
# Otherwise the directory is kept and an info message naming it is added to the
# run summary. A missing directory is not an error. Refuses relative paths,
# paths containing "..", symlinks, and protected system or home directories.
# Uses sudo only when the directory cannot be deleted as the current user.
#
# Parameters:
#   canonical_id - Canonical module ID used for logging and messages.
#   data_path - Absolute data directory path.
#
# Return:
#   1 - Validation failed, the path is unsafe, or deletion failed.
#
remove_data_dir() {
    local canonical_id="${1:-}"
    local data_path="${2:-}"
    local tag="remove-data-dir"

    if [[ -n "$canonical_id" ]]; then
        tag+=":$canonical_id"
    fi

    if (( $# != 2 )) || [[ -z "$canonical_id" || -z "$data_path" ]]; then
        tlog_error "$tag" "A canonical ID and data path are required"

        return 1
    fi

    local status=0

    while [[ "${#data_path}" -gt 1 && "$data_path" == */ ]]; do
        data_path="${data_path%/}"
    done

    if [[ "$data_path" != /* || "/$data_path/" == */../* || "/$data_path/" == */./* ]]; then
        tlog_error "$tag" "Data path must be absolute and normalized: %s" "$data_path"

        return 1
    fi

    if __is_protected_directory "$data_path"; then
        tlog_error "$tag" "Refusing to remove a protected directory: %s" "$data_path"

        return 1
    fi

    if [[ -L "$data_path" ]] || { [[ -e "$data_path" ]] && [[ ! -d "$data_path" ]]; }; then
        tlog_error "$tag" "Data path is not a directory: %s" "$data_path"

        return 1
    fi

    if [[ ! -d "$data_path" ]]; then
        tlog_info "$tag" "Data directory does not exist, skipping: %s" "$data_path"

        return 0
    fi

    if [[ "${PURGE:-false}" != "true" ]]; then
        tlog_info "$tag" "Keeping data directory (use mp purge to delete it): %s" "$data_path"

        if ! add_message "$canonical_id" info \
            "Data directory kept: $data_path. Use 'mp purge' to delete it."; then
            tlog_warn "$tag" "Failed to record the data directory message"
        fi

        return 0
    fi

    tlog_warn "$tag" "Deleting data directory: %s" "$data_path"

    if [[ -w "${data_path%/*}" ]] && can_write "$data_path"; then
        rm -rf -- "$data_path" || status=$?
    else
        sudo rm -rf -- "$data_path" || status=$?
    fi

    if (( status != 0 )) || [[ -d "$data_path" ]]; then
        tlog_error "$tag" "Failed to remove data directory: %s" "$data_path"

        return 1
    fi

    return 0
}

##
# remove_registry_data_dir
#
# Loads the module registry and passes its INSTALL_PATH to remove_data_dir, for
# modules whose data directory was chosen at install time and recorded as
# INSTALL_PATH. A missing registry logs a warning and is not an error.
#
# Parameters:
#   canonical_id - Canonical module ID selecting the registry and used for logging.
#
# Return:
#   1 - The registry has no installation path, the path is unsafe, or deletion failed.
#   2 - The registry is invalid or unreadable.
#
remove_registry_data_dir() {
    local canonical_id="${1:-}"
    local tag="remove-data-dir"
    local data_path
    local status=0

    if [[ -n "$canonical_id" ]]; then
        tag+=":$canonical_id"
    fi

    if (( $# != 1 )) || [[ -z "$canonical_id" ]]; then
        tlog_error "$tag" "A canonical ID is required"

        return 1
    fi

    load_registry "$canonical_id" silent || status=$?

    if (( status == 1 )); then
        tlog_warn "$tag" "No registry found; the data directory is unknown and was not removed"

        return 0
    fi

    if (( status != 0 )); then
        return "$status"
    fi

    if ! data_path="$(get_registry INSTALL_PATH)"; then
        tlog_error "$tag" "The registry does not record a data directory"

        return 1
    fi

    remove_data_dir "$canonical_id" "$data_path"
}
