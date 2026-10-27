#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_STATEFUL_BINARY_UPGRADE_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_STATEFUL_BINARY_UPGRADE_LOADED=1

source "$LIB_INSTALLER/registry.sh"
source "$LIB_INSTALLER/state.sh"
source "$LIB_WORKFLOW/version-registry.sh"

##
# stateful_binary_upgrade <canonical_id> <state_name> <binary_name>
#
# Replaces a binary in the installation directory recorded in the registry
# INSTALL_PATH with the file from a state key. The new binary is copied next to
# the old one first and then moved over it. Symlinks are not changed.
#
# Parameters:
#   canonical_id - Canonical module ID used for tagged logging, state, and registry.
#   state_name - State name containing the downloaded binary path.
#   binary_name - Binary file name inside the installation directory.
#
# Return:
#   1 - State or registry lookup failed, or the binary could not be replaced.
#
stateful_binary_upgrade() {
    local canonical_id="$1"
    local state_name="$2"
    local binary_name="$3"
    local tag="extract:$canonical_id"
    local install_path
    local binary_file
    local staging_file

    if ! load_states "$canonical_id" || ! binary_file="$(get_state "$state_name")"; then
        tlog_error "$tag" "State key is not set: %s" "$state_name"

        return 1
    fi

    if [[ ! -f "$binary_file" ]]; then
        tlog_error "$tag" "State file does not exist: %s" "$binary_file"

        return 1
    fi

    if ! load_registry "$canonical_id" || ! install_path="$(get_registry "INSTALL_PATH")"; then
        tlog_error "$tag" "Installation path is not recorded in the registry"

        return 1
    fi

    if ! staging_file="$(mktemp "${install_path}/${binary_name}.upgrade.XXXXXX")"; then
        tlog_error "$tag" "Failed to create a staging file in: %s" "$install_path"

        return 1
    fi

    tlog_info "$tag" "Replacing %s" "${install_path}/${binary_name}"
    if ! cp -- "$binary_file" "$staging_file" ||
        ! chmod 0755 -- "$staging_file" ||
        ! mv -f -- "$staging_file" "${install_path}/${binary_name}"; then
        tlog_error "$tag" "Failed to replace binary: %s" "${install_path}/${binary_name}"
        rm -f -- "$staging_file" || true

        return 1
    fi

    record_version_registry "$canonical_id"

    tlog_info "$tag" "Upgrade completed successfully"
}
