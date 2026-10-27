#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_STATEFUL_EXTRACT_UPGRADE_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_STATEFUL_EXTRACT_UPGRADE_LOADED=1

source "$LIB_WORKFLOW/stateful-extractor.sh"
source "$LIB_INSTALLER/registry.sh"
source "$LIB_WORKFLOW/version-registry.sh"

##
# __swap_install_dir <tag> <install_path> <new_path> <backup_path>
#
# Replaces install_path with new_path. The previous directory is moved to
# backup_path, restored when new_path cannot be moved into place, and removed
# otherwise.
#
# Return:
#   1 - The directories could not be swapped; install_path is unchanged.
#
__swap_install_dir() {
    local tag="$1"
    local install_path="$2"
    local new_path="$3"
    local backup_path="$4"

    if ! mv -T -- "$install_path" "$backup_path"; then
        tlog_error "$tag" "Failed to move the current installation aside: %s" "$install_path"

        return 1
    fi

    if ! mv -T -- "$new_path" "$install_path"; then
        tlog_error "$tag" "Failed to move the upgraded files into place: %s" "$install_path"
        if ! mv -T -- "$backup_path" "$install_path"; then
            tlog_error "$tag" "Failed to restore the previous installation from: %s" "$backup_path"
        fi

        return 1
    fi

    if ! rm -rf -- "$backup_path"; then
        tlog_warn "$tag" "Failed to remove the previous installation: %s" "$backup_path"
    fi

    return 0
}

##
# __install_dir_in_use <tag> <install_path>
#
# Checks whether a running process was started from install_path. Without
# pgrep, the check is skipped.
#
# Return:
#   0 - A process runs from install_path; the processes are logged.
#   1 - No process runs from install_path.
#
__install_dir_in_use() {
    local tag="$1"
    local install_path="$2"
    local processes
    local line

    command -v pgrep >/dev/null 2>&1 || return 1
    processes="$(pgrep -af -- "$install_path/")" || return 1

    tlog_error "$tag" "Close the programs running from %s before upgrading:" "$install_path"
    while IFS= read -r line; do
        tlog_error "$tag" "  %s" "$line"
    done <<< "$processes"

    return 0
}

##
# __keep_install_paths <tag> <install_path> <new_path> <keep_path...>
#
# Copies each keep_path, relative to the installation, from install_path into
# new_path, replacing the newly extracted copy. Paths missing from the current
# installation are skipped.
#
# Return:
#   1 - A path could not be copied.
#
__keep_install_paths() {
    local tag="$1"
    local install_path="$2"
    local new_path="$3"
    shift 3

    local keep_path

    for keep_path in "$@"; do
        if [[ ! -e "$install_path/$keep_path" ]]; then
            continue
        fi

        tlog_info "$tag" "Keeping %s from the current installation" "$keep_path"
        if ! rm -rf -- "${new_path:?}/$keep_path" ||
            ! mkdir -p -- "$(dirname -- "$new_path/$keep_path")" ||
            ! cp -a -- "$install_path/$keep_path" "$new_path/$keep_path"; then
            tlog_error "$tag" "Failed to keep %s from the current installation" "$keep_path"

            return 1
        fi
    done

    return 0
}

##
# stateful_extract_upgrade <canonical_id> <state_name> <archive_type> [--root <dir>] [--keep <path>]... <binary>... [-- <extractor args...>]
#
# Replaces the installation directory recorded in the registry INSTALL_PATH
# with a freshly extracted archive. The archive is extracted next to the
# installation first, so a failed extraction leaves the installation untouched.
# Symlinks, desktop entries, and PATH entries are not changed; they keep
# pointing into the same directory. The upgrade is refused while a program runs
# from the installation directory.
#
# Parameters:
#   canonical_id - Canonical module ID used for tagged logging, state, and registry.
#   state_name - State name containing the archive path.
#   archive_type - Archive type used for extraction.
#   --root dir - Archive subdirectory that becomes the installation, for
#                archives with a top folder the extractor cannot strip.
#   --keep path - Path relative to the installation copied from the current
#                 installation into the new one, such as user-edited
#                 configuration. Repeatable.
#   binary - Binary path relative to the installation directory to mark executable.
#   extractor args... - Additional extractor arguments passed as-is.
#
# Return:
#   1 - Validation, extraction, keeping paths, or the directory swap failed,
#       or the installation is in use.
#
stateful_extract_upgrade() {
    local canonical_id="$1"
    local state_name="$2"
    local archive_type="$3"
    local tag="extract:$canonical_id"
    local root=""
    local -a keep_paths=()
    local -a binaries=()
    local -a extractor_args=()
    local install_path
    local staging_path
    local new_path
    local binary

    shift 3

    while (( $# > 0 )); do
        case "$1" in
            --)
                # Everything after -- belongs to the extractor.
                shift
                extractor_args=("$@")
                break
                ;;
            --root)
                root="${2:-}"
                shift 2 || shift
                ;;
            --keep)
                keep_paths+=("${2:-}")
                shift 2 || shift
                ;;
            *)
                binaries+=("$1")
                shift
                ;;
        esac
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

    if __install_dir_in_use "$tag" "$install_path"; then
        return 1
    fi

    if ! staging_path="$(mktemp -d "${install_path}.upgrade.XXXXXX")"; then
        tlog_error "$tag" "Failed to create a staging directory next to: %s" "$install_path"

        return 1
    fi

    # ${root:+/$root} expands to "/$root" only when --root was given, otherwise
    # to nothing: the new installation is <staging>/<root> or the staging root.
    new_path="$staging_path${root:+/$root}"

    if ! stateful_extract \
        "$canonical_id" \
        "$state_name" \
        "$archive_type" \
        "$staging_path" \
        "${extractor_args[@]}"; then
        rm -rf -- "$staging_path" || true

        return 1
    fi

    if [[ ! -d "$new_path" ]]; then
        tlog_error "$tag" "Archive root directory not found: %s" "$root"
        rm -rf -- "$staging_path" || true

        return 1
    fi

    # mktemp -d creates a 0700 directory; keep the installation's permissions.
    chmod --reference="$install_path" -- "$new_path" || true

    for binary in "${binaries[@]}"; do
        if ! chmod +x "${new_path}/${binary}"; then
            tlog_error "$tag" "Failed to make binary executable: %s" "${new_path}/${binary}"
            rm -rf -- "$staging_path" || true

            return 1
        fi
    done

    if ! __keep_install_paths "$tag" "$install_path" "$new_path" "${keep_paths[@]}"; then
        rm -rf -- "$staging_path" || true

        return 1
    fi

    if ! __swap_install_dir "$tag" "$install_path" "$new_path" \
        "${install_path}.old.${staging_path##*.upgrade.}"; then
        rm -rf -- "$staging_path" || true

        return 1
    fi

    # With --root, the staging directory still holds the rest of the archive.
    rm -rf -- "$staging_path" || true
    record_version_registry "$canonical_id"

    tlog_info "$tag" "Upgrade completed successfully"
}
