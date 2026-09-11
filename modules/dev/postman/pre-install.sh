#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/install-target.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"

url="https://dl.pstmn.io/download/latest/linux64"
install_dir="${POSTMAN_INSTALL_DIR:-$INSTALL_DIR/postman}"

valid_install_target "$CANONICAL_ID" "$install_dir" "POSTMAN_INSTALL_DIR" || exit $?
stateful_download "$CANONICAL_ID" "ARCHIVE_FILE" "$url" ".tar.gz"
