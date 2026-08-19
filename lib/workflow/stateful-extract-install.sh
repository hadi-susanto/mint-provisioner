#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_STATEFUL_EXTRACT_INSTALL_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_STATEFUL_EXTRACT_INSTALL_LOADED=1

source "$LIB_WORKFLOW/stateful-extractor.sh"
source "$LIB_INSTALLER/path.sh"
source "$LIB_INSTALLER/registry.sh"
source "$LIB_INSTALLER/symlink.sh"

##
# stateful_extract_install <canonical_id> <state_name> <archive_type> <install_dir> [<binary> <link_name>]... [-- <extractor args...>]
#
# Extracts an archive, creates symlinks for the specified binaries, and saves
# the installation path to the registry.
#
# Parameters:
#   canonical_id - Canonical module ID used for tagged logging and state.
#   state_name - State name containing the archive information.
#   archive_type - Archive type used for extraction.
#   install_dir - Installation destination directory.
#   binary - Binary path relative to the installation directory.
#   link_name - Symlink name for the corresponding binary.
#   extractor args... - Additional extractor arguments passed as-is.
#
# Return:
#   1 - Validation failed or no binaries were specified.
#
stateful_extract_install() {
    local canonical_id="$1"
    local state_name="$2"
    local archive_type="$3"
    local raw_install_path="$4"
    local tag="extract:$canonical_id"
    local -a binaries=()
    local -a link_names=()
    local -a extractor_args=()
    local install_path
    local i

    shift 4

    install_path="$(expand_path "$raw_install_path")" || return $?

    while [[ $# -gt 0 ]]; do
        # Everything after -- belongs to the extractor.
        if [[ "$1" == "--" ]]; then
            shift
            extractor_args=("$@")
            break
        fi

        # Every binary must have a corresponding link name.
        if [[ -z "${2:-}" || "$2" == "--" ]]; then
            tlog_error "$tag" "Missing link name for binary: %s" "$1"

            return 1
        fi

        binaries+=("$1")
        link_names+=("$2")

        shift 2
    done

    if [[ ${#binaries[@]} -eq 0 ]]; then
        tlog_error "$tag" "No binaries specified"

        return 1
    fi

    stateful_extract \
        "$canonical_id" \
        "$state_name" \
        "$archive_type" \
        "$install_path" \
        "${extractor_args[@]}" || return $?

    for ((i = 0; i < ${#binaries[@]}; i++)); do
        symlink_binary \
            "$canonical_id" "${install_path}/${binaries[i]}" "${link_names[i]}" || return $?
    done

    set_registry "INSTALL_PATH" "$install_path" || return $?
    save_registry "$canonical_id" || return $?

    tlog_info "$tag" "Installation completed successfully"
}
