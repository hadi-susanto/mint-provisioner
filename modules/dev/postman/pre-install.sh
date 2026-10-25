#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/install-target.sh"
source "$LIB_WORKFLOW/latest-version.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"

install_dir="${POSTMAN_INSTALL_DIR:-$INSTALL_DIR/postman}"

valid_install_target "$CANONICAL_ID" "$install_dir" "POSTMAN_INSTALL_DIR" || exit $?
version="$(module_latest_version "$CANONICAL_ID")" || exit $?
url="https://dl.pstmn.io/download/version/${version}/linux64"

stateful_download "$CANONICAL_ID" "ARCHIVE_FILE" "$url" ".tar.gz" 1 "" "$version"
