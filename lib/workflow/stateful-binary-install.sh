#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_STATEFUL_BINARY_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_STATEFUL_BINARY_LOADED=1

source "$LIB_INSTALLER/path.sh"
source "$LIB_INSTALLER/registry.sh"
source "$LIB_INSTALLER/state.sh"
source "$LIB_INSTALLER/symlink.sh"

##
# stateful_binary_install <canonical_id> <state_name> <install_dir> <binary> [<link_name>]
#
# Copy binary from state file to install_dir, creates symlinks for the specified binaries, and saves
# the installation path to the registry.
#
# Parameters:
#   canonical_id - Canonical module ID used for tagged logging and state.
#   state_name - State name containing the archive information.
#   binary - Binary path relative to the installation directory.
#   link_name - Symlink name for the corresponding binary.
#
# Return:
#   1 - Validation failed or no binaries were specified.
#
stateful_binary_install() {
    local canonical_id="$1"
    local state_name="$2"
    local raw_install_path="$3"
    local binary_name="$4"
    local link_name="${5:-$binary_name}"
    local tag="extract:$canonical_id"
    local install_path
    local binary_file

    install_path="$(expand_path "$raw_install_path")" || return $?
    tlog_info "$tag" "Create installation path directory %s" "$install_path"
    mkdir -p -- "$install_path"

    load_states "$canonical_id"
    binary_file="$(get_state "$state_name")" || return $?

    tlog_info "$tag" "Copying binary file from %s to %s" "$binary_file" "${install_path}/${binary_name}"
    cp "$binary_file" "${install_path}/${binary_name}"
    tlog_info "$tag" "Set executable bit for %s" "${install_path}/${binary_name}"
    chmod +x "${install_path}/${binary_name}"
    symlink_binary \
            "$canonical_id" "${install_path}/${binary_name}" "$link_name" || return $?

    set_registry "INSTALL_PATH" "$install_path" || return $?
    save_registry "$canonical_id" || return $?

    tlog_info "$tag" "Installation completed successfully"
}
