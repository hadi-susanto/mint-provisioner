#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/path.sh"
source "$LIB_INSTALLER/registry.sh"
source "$LIB_WORKFLOW/stateful-extractor.sh"
source "$LIB_WORKFLOW/version-registry.sh"

tag="install:$CANONICAL_ID"
install_path="$(expand_path "${ADB_INSTALL_DIR:-$INSTALL_DIR/adb}")" || exit $?

if ! mkdir -p -- "$install_path"; then
    tlog_error "$tag" "Failed to create install directory: %s" "$install_path"

    exit 1
fi

if ! temporary_dir="$(mktemp -d)"; then
    tlog_error "$tag" "Failed to create a temporary extraction directory"

    exit 1
fi

stateful_extract "$CANONICAL_ID" "ARCHIVE_FILE" "zip" "$temporary_dir" || exit $?
if ! cp -r "${temporary_dir}/platform-tools/." "$install_path/"; then
    tlog_error "$tag" "Failed to copy Android platform-tools into: %s" "$install_path"
    rm -rf -- "$temporary_dir"

    exit 1
fi

rm -rf -- "$temporary_dir"

add_to_path "$CANONICAL_ID" "$install_path" || exit $?
set_registry "INSTALL_PATH" "$install_path" || exit $?
save_registry "$CANONICAL_ID" || exit $?
record_version_registry "$CANONICAL_ID"

tlog_info "$tag" "Installation completed successfully"
