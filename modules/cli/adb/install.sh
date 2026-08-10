#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/path.sh"
source "$LIB_INSTALLER/registry.sh"
source "$LIB_INSTALLER/state.sh"

main() {
    local canonical_id="$1"
    local raw_install_path="$2"
    local archive_file
    local install_path
    local temporary_dir
    local tag="install:$canonical_id"

    load_states "$canonical_id" || return 1
    archive_file="$(get_state "ARCHIVE_FILE")" || return 1

    if [[ ! -f "$archive_file" ]]; then
        tlog_error "$tag" "Archive file not found: %s" "$archive_file"

        return 2
    fi

    install_path="$(expand_path "$raw_install_path")" || return $?
    if ! mkdir -p -- "$install_path"; then
        tlog_error "$tag" "Failed to create install directory: %s" "$install_path"

        return 3
    fi

    if ! temporary_dir="$(mktemp -d)"; then
        tlog_error "$tag" "Failed to create a temporary extraction directory"

        return 4
    fi

    if ! unzip -q "$archive_file" -d "$temporary_dir"; then
        tlog_error "$tag" "Failed to extract Android platform-tools"
        rm -rf -- "$temporary_dir"

        return 5
    fi

    if ! cp -r "${temporary_dir}/platform-tools/." "$install_path/"; then
        tlog_error "$tag" "Failed to copy Android platform-tools into: %s" "$install_path"
        rm -rf -- "$temporary_dir"

        return 6
    fi

    rm -rf -- "$temporary_dir"

    if [[ ! -x "$install_path/adb" ]]; then
        tlog_error "$tag" "ADB executable was not installed: %s" "$install_path/adb"

        return 7
    fi

    add_to_path "$canonical_id" "$install_path" || return 8
    set_registry "INSTALL_PATH" "$install_path" || return 9
    save_registry "$canonical_id" || return 9

    tlog_info "$tag" "Installation completed successfully"
}

main "$CANONICAL_ID" "${ADB_INSTALL_DIR:-$INSTALL_DIR/adb}"
