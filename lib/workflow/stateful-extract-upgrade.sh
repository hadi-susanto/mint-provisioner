#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_STATEFUL_EXTRACT_UPGRADE_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_STATEFUL_EXTRACT_UPGRADE_LOADED=1

source "$LIB_WORKFLOW/stateful-extractor.sh"
source "$LIB_INSTALLER/registry.sh"
source "$LIB_WORKFLOW/version-registry.sh"

##
# __swap_install_dir <tag> <install_path> <staging_path>
#
# Replaces install_path with staging_path. The previous directory is restored
# when the new one cannot be moved into place, and removed otherwise.
#
# Return:
#   1 - The directories could not be swapped; install_path is unchanged.
#
__swap_install_dir() {
    local tag="$1"
    local install_path="$2"
    local staging_path="$3"
    local backup_path="${install_path}.old.${staging_path##*.upgrade.}"

    if ! mv -T -- "$install_path" "$backup_path"; then
        tlog_error "$tag" "Failed to move the current installation aside: %s" "$install_path"
        rm -rf -- "$staging_path" || true

        return 1
    fi

    if ! mv -T -- "$staging_path" "$install_path"; then
        tlog_error "$tag" "Failed to move the upgraded files into place: %s" "$install_path"
        if ! mv -T -- "$backup_path" "$install_path"; then
            tlog_error "$tag" "Failed to restore the previous installation from: %s" "$backup_path"
        fi
        rm -rf -- "$staging_path" || true

        return 1
    fi

    if ! rm -rf -- "$backup_path"; then
        tlog_warn "$tag" "Failed to remove the previous installation: %s" "$backup_path"
    fi

    return 0
}

##
# stateful_extract_upgrade <canonical_id> <state_name> <archive_type> <binary>... [-- <extractor args...>]
#
# Replaces the installation directory recorded in the registry INSTALL_PATH
# with a freshly extracted archive. The archive is extracted next to the
# installation first, so a failed extraction leaves the installation untouched.
# Symlinks, desktop entries, and PATH entries are not changed; they keep
# pointing into the same directory.
#
# Parameters:
#   canonical_id - Canonical module ID used for tagged logging, state, and registry.
#   state_name - State name containing the archive path.
#   archive_type - Archive type used for extraction.
#   binary - Binary path relative to the installation directory to mark executable.
#   extractor args... - Additional extractor arguments passed as-is.
#
# Return:
#   1 - Validation, extraction, or the directory swap failed.
#
stateful_extract_upgrade() {
    local canonical_id="$1"
    local state_name="$2"
    local archive_type="$3"
    local tag="extract:$canonical_id"
    local -a binaries=()
    local -a extractor_args=()
    local install_path
    local staging_path
    local binary

    shift 3

    while (( $# > 0 )); do
        # Everything after -- belongs to the extractor.
        if [[ "$1" == "--" ]]; then
            shift
            extractor_args=("$@")
            break
        fi

        binaries+=("$1")
        shift
    done

    if (( ${#binaries[@]} == 0 )); then
        tlog_error "$tag" "No binaries specified"

        return 1
    fi

    if ! load_registry "$canonical_id" || ! install_path="$(get_registry "INSTALL_PATH")"; then
        tlog_error "$tag" "Installation path is not recorded in the registry"

        return 1
    fi

    if [[ ! -d "$install_path" ]]; then
        tlog_error "$tag" "Installation directory does not exist: %s" "$install_path"

        return 1
    fi

    if ! staging_path="$(mktemp -d "${install_path}.upgrade.XXXXXX")"; then
        tlog_error "$tag" "Failed to create a staging directory next to: %s" "$install_path"

        return 1
    fi

    # mktemp -d creates a 0700 directory; keep the installation's permissions.
    chmod --reference="$install_path" -- "$staging_path" || true

    if ! stateful_extract \
        "$canonical_id" \
        "$state_name" \
        "$archive_type" \
        "$staging_path" \
        "${extractor_args[@]}"; then
        rm -rf -- "$staging_path" || true

        return 1
    fi

    for binary in "${binaries[@]}"; do
        if ! chmod +x "${staging_path}/${binary}"; then
            tlog_error "$tag" "Failed to make binary executable: %s" "${staging_path}/${binary}"
            rm -rf -- "$staging_path" || true

            return 1
        fi
    done

    __swap_install_dir "$tag" "$install_path" "$staging_path" || return $?
    record_version_registry "$canonical_id"

    tlog_info "$tag" "Upgrade completed successfully"
}
