#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/install-target.sh"
source "$LIB_WORKFLOW/latest-version.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"

install_dir="${ADB_INSTALL_DIR:-$INSTALL_DIR/adb}"

valid_install_target "$CANONICAL_ID" "$install_dir" "ADB_INSTALL_DIR" || exit $?
version="$(module_latest_version "$CANONICAL_ID")" || exit $?
url="https://dl.google.com/android/repository/platform-tools_r${version}-linux.zip"

stateful_download "$CANONICAL_ID" "ARCHIVE_FILE" "$url" ".zip" 1 "" "$version"
