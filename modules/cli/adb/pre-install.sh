#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/install-target.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"

url="https://dl.google.com/android/repository/platform-tools-latest-linux.zip"
install_dir="${ADB_INSTALL_DIR:-$INSTALL_DIR/adb}"

valid_install_target "$CANONICAL_ID" "$install_dir" "ADB_INSTALL_DIR" || exit $?
stateful_download "$CANONICAL_ID" "ARCHIVE_FILE" "$url" ".zip"
