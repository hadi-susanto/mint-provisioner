#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/path.sh"
source "$LIB_INSTALLER/registry.sh"
source "$LIB_WORKFLOW/stateful-extractor.sh"

main() {
    local canonical_id="$1"
    local raw_install_path="$2"
    local archive_file
    local install_path
    local temporary_dir
    local tag="install:$canonical_id"

    install_path="$(expand_path "$raw_install_path")" || return $?
    if ! mkdir -p -- "$install_path"; then
        tlog_error "$tag" "Failed to create install directory: %s" "$install_path"

        return 1
    fi

    if ! temporary_dir="$(mktemp -d)"; then
        tlog_error "$tag" "Failed to create a temporary extraction directory"

        return 1
    fi

    stateful_extract "$canonical_id" "ARCHIVE_FILE" "zip" "$temporary_dir" || return $?
    if ! cp -r "${temporary_dir}/platform-tools/." "$install_path/"; then
        tlog_error "$tag" "Failed to copy Android platform-tools into: %s" "$install_path"
        rm -rf -- "$temporary_dir"

        return 1
    fi

    rm -rf -- "$temporary_dir"

    add_to_path "$canonical_id" "$install_path" || return $?
    set_registry "INSTALL_PATH" "$install_path" || return $?
    save_registry "$canonical_id" || return $?

    tlog_info "$tag" "Installation completed successfully"
}

main "$CANONICAL_ID" "${ADB_INSTALL_DIR:-$INSTALL_DIR/adb}"
